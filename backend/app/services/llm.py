from __future__ import annotations

import asyncio
import json
import logging
from typing import Any

import httpx

from app.core.config import settings

logger = logging.getLogger(__name__)

# Back-off configuration for OpenRouter free-tier rate limits / queuing.
_BACKOFF_BASE: float = 2.0       # seconds: 2, 4, 8, 16 …
_BACKOFF_CAP: float = 30.0       # never wait longer than this per attempt
_RETRY_AFTER_MIN: float = 1.0    # honour Retry-After but never below this
_RETRY_AFTER_MAX: float = 60.0   # ignore absurdly large Retry-After values


class LLMError(RuntimeError):
    """Raised when the configured text-generation provider cannot serve a request."""


class LLMProviderOverloadedError(LLMError):
    """Raised after all retries for a temporary provider overload are exhausted."""


def _is_provider_overloaded(result: dict[str, Any]) -> bool:
    """Return whether a successful HTTP response reports a retryable overload or rate-limit.

    Handles two OpenRouter patterns:
    - ``error_type: "provider_overloaded"`` (upstream provider busy)
    - ``error.message`` containing "overload" or "rate limit" (free-model quota)
    """
    error = result.get("error")
    error_type = result.get("error_type")
    if isinstance(error, dict):
        error_type = error_type or error.get("type") or error.get("code")
        message = error.get("message", "")
    else:
        message = ""

    if isinstance(error_type, str) and error_type.lower() == "provider_overloaded":
        return True

    if isinstance(message, str):
        msg_lower = message.lower()
        # "overload" covers provider_overloaded messages; "rate limit" covers
        # OpenRouter free-model per-minute / per-day quota errors.
        if ("overload" in msg_lower or "rate limit" in msg_lower) and result.get("status") == "failed":
            return True

    return False


def _parse_retry_after(headers: httpx.Headers) -> float | None:
    """Return the number of seconds from a ``Retry-After`` header, or ``None``.

    Clamps the value to ``[_RETRY_AFTER_MIN, _RETRY_AFTER_MAX]`` so that
    unreasonably small or large server hints are ignored.
    """
    raw = headers.get("retry-after")
    if raw is None:
        return None
    try:
        seconds = float(raw)
    except ValueError:
        return None
    return max(_RETRY_AFTER_MIN, min(_RETRY_AFTER_MAX, seconds))


async def _retry_after_overload(attempt: int, retry_after: float | None = None) -> None:
    """Yield control to the event loop while waiting for the overload back-off delay.

    Priority order:
    1. ``Retry-After`` header value (clamped to a safe range) — respects OpenRouter hints.
    2. Exponential back-off: ``2 ** attempt`` seconds, capped at ``_BACKOFF_CAP``.

    Uses ``asyncio.sleep`` so the Uvicorn event loop is not blocked.
    """
    if retry_after is not None:
        delay = retry_after
    else:
        delay = min(_BACKOFF_BASE ** attempt, _BACKOFF_CAP)

    logger.info(
        "LLM provider overloaded — waiting %.1fs before retry (attempt %d)", delay, attempt + 1
    )
    await asyncio.sleep(delay)


def _response_text(result: dict[str, Any]) -> str:
    """Extract text from Responses API payloads, with a Chat Completions fallback."""
    output_text = result.get("output_text")
    if isinstance(output_text, str) and output_text.strip():
        return output_text.strip()

    parts: list[str] = []
    for item in result.get("output", []):
        if not isinstance(item, dict):
            continue
        for content in item.get("content", []):
            if isinstance(content, dict) and isinstance(content.get("text"), str):
                parts.append(content["text"])
    if parts:
        return "".join(parts).strip()

    choices = result.get("choices", [])
    if choices and isinstance(choices[0], dict):
        message = choices[0].get("message", {})
        if isinstance(message, dict) and isinstance(message.get("content"), str):
            return message["content"].strip()
    raise LLMError("LLM response did not contain text")


def _build_request_body(
    *,
    instructions: str,
    input_text: str,
    max_output_tokens: int,
    temperature: float,
    is_chat_completions: bool,
    is_openrouter: bool,
) -> dict[str, object]:
    """Construct the JSON request body for the configured LLM endpoint format."""
    if is_chat_completions:
        body: dict[str, object] = {
            "model": settings.llm_model,
            "messages": [
                {"role": "system", "content": instructions},
                {"role": "user", "content": input_text},
            ],
            "max_completion_tokens": max_output_tokens,
            "temperature": temperature,
        }
    else:
        body = {
            "model": settings.llm_model,
            "instructions": instructions,
            "input": input_text,
            "max_output_tokens": max_output_tokens,
            "temperature": temperature,
            "store": False,
        }
    if is_openrouter and settings.llm_suppress_reasoning:
        body["reasoning"] = {"enabled": False, "exclude": True}
    return body


async def generate_text(
    *,
    instructions: str,
    input_text: str,
    max_output_tokens: int,
    temperature: float,
) -> str:
    """Asynchronously call an OpenAI-compatible Responses or Chat Completions endpoint.

    Uses ``httpx.AsyncClient`` so that the Uvicorn event loop remains unblocked
    during network I/O and overload back-off sleeps.  Must be called with ``await``
    from an ``async def`` context.

    Raises:
        LLMError: The provider returned an unexpected response or a non-retryable error.
        LLMProviderOverloadedError: All configured retries were exhausted due to
            provider overload (HTTP 429/503 or an overload payload).
    """
    if not settings.llm_api_url:
        raise LLMError("LLM_API_URL is not configured")

    is_chat_completions = settings.llm_api_url.rstrip("/").endswith("/chat/completions")
    is_openrouter = "openrouter.ai" in settings.llm_api_url.lower()

    body = _build_request_body(
        instructions=instructions,
        input_text=input_text,
        max_output_tokens=max_output_tokens,
        temperature=temperature,
        is_chat_completions=is_chat_completions,
        is_openrouter=is_openrouter,
    )

    headers: dict[str, str] = {"Content-Type": "application/json"}
    if settings.llm_api_key:
        headers["Authorization"] = f"Bearer {settings.llm_api_key}"

    total_attempts = settings.llm_overload_max_retries + 1
    async with httpx.AsyncClient(timeout=settings.llm_timeout_seconds) as client:
        for attempt in range(total_attempts):
            try:
                response = await client.post(
                    settings.llm_api_url,
                    json=body,
                    headers=headers,
                )
            except (httpx.TimeoutException, httpx.TransportError) as exc:
                raise LLMError(f"LLM request failed: {exc}") from exc

            # Providers use 429/503 for rate limiting and temporary overload.
            # Respect any Retry-After hint the server provides.
            if response.status_code in (429, 503):
                if attempt == total_attempts - 1:
                    raise LLMProviderOverloadedError(
                        f"LLM provider remained overloaded after {total_attempts} attempts"
                    )
                retry_after = _parse_retry_after(response.headers)
                await _retry_after_overload(attempt, retry_after)
                continue

            if response.status_code != 200:
                raise LLMError(f"LLM request failed: HTTP {response.status_code}")

            try:
                result = response.json()
            except json.JSONDecodeError as exc:
                raise LLMError(f"LLM response was not valid JSON: {exc}") from exc

            if not isinstance(result, dict):
                raise LLMError("LLM response must be a JSON object")
            if not _is_provider_overloaded(result):
                return _response_text(result)
            if attempt == total_attempts - 1:
                raise LLMProviderOverloadedError(
                    f"LLM provider remained overloaded after {total_attempts} attempts"
                )
            # No Retry-After in a 200 body; fall through to exponential back-off.
            await _retry_after_overload(attempt)

    # The loop always returns or raises; this keeps static type checkers satisfied.
    raise AssertionError("unreachable")
