from __future__ import annotations

import json
import time
from typing import Any
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

from app.core.config import settings


class LLMError(RuntimeError):
    """Raised when the configured text-generation provider cannot serve a request."""


class LLMProviderOverloadedError(LLMError):
    """Raised after all retries for a temporary provider overload are exhausted."""


def _is_provider_overloaded(result: dict[str, Any]) -> bool:
    """Return whether a successful HTTP response reports temporary provider overload."""
    error = result.get("error")
    error_type = result.get("error_type")
    if isinstance(error, dict):
        error_type = error_type or error.get("type") or error.get("code")
        message = error.get("message", "")
    else:
        message = ""

    return (
        isinstance(error_type, str)
        and error_type.lower() == "provider_overloaded"
    ) or (
        isinstance(message, str)
        and "overload" in message.lower()
        and result.get("status") == "failed"
    )


def _retry_after_overload(attempt: int) -> None:
    """Wait according to the overload retry schedule before the next request."""
    delay = 1 if attempt == 0 else 2
    time.sleep(delay)


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


def generate_text(
    *,
    instructions: str,
    input_text: str,
    max_output_tokens: int,
    temperature: float,
) -> str:
    """Call an OpenAI-compatible Responses or Chat Completions endpoint."""
    if not settings.llm_api_url:
        raise LLMError("LLM_API_URL is not configured")

    is_chat_completions = settings.llm_api_url.rstrip("/").endswith("/chat/completions")
    is_openrouter = "openrouter.ai" in settings.llm_api_url.lower()
    if is_chat_completions:
        request_body: dict[str, object] = {
            "model": settings.llm_model,
            "messages": [
                {"role": "system", "content": instructions},
                {"role": "user", "content": input_text},
            ],
            "max_completion_tokens": max_output_tokens,
            "temperature": temperature,
        }
        if is_openrouter and settings.llm_suppress_reasoning:
            request_body["reasoning"] = {"enabled": False, "exclude": True}
    else:
        request_body = {
            "model": settings.llm_model,
            "instructions": instructions,
            "input": input_text,
            "max_output_tokens": max_output_tokens,
            "temperature": temperature,
            "store": False,
        }
        if is_openrouter and settings.llm_suppress_reasoning:
            request_body["reasoning"] = {"enabled": False, "exclude": True}
    payload = json.dumps(request_body).encode("utf-8")
    headers = {"Content-Type": "application/json"}
    if settings.llm_api_key:
        headers["Authorization"] = f"Bearer {settings.llm_api_key}"

    request = Request(settings.llm_api_url, data=payload, headers=headers, method="POST")
    total_attempts = settings.llm_overload_max_retries + 1
    for attempt in range(total_attempts):
        try:
            with urlopen(request, timeout=settings.llm_timeout_seconds) as response:
                result = json.load(response)
        except HTTPError as exc:
            # Providers conventionally use 429/503 for rate limiting and temporary overload.
            if exc.code not in (429, 503):
                raise LLMError(f"LLM request failed: {exc}") from exc
            if attempt == total_attempts - 1:
                raise LLMProviderOverloadedError(
                    f"LLM provider remained overloaded after {total_attempts} attempts"
                ) from exc
            _retry_after_overload(attempt)
            continue
        except (URLError, TimeoutError, json.JSONDecodeError) as exc:
            raise LLMError(f"LLM request failed: {exc}") from exc

        if not isinstance(result, dict):
            raise LLMError("LLM response must be a JSON object")
        if not _is_provider_overloaded(result):
            return _response_text(result)
        if attempt == total_attempts - 1:
            raise LLMProviderOverloadedError(
                f"LLM provider remained overloaded after {total_attempts} attempts"
            )
        _retry_after_overload(attempt)

    # The loop always returns or raises; this keeps static type checkers satisfied.
    raise AssertionError("unreachable")
