"""remove database-backed auth sessions

Revision ID: 20260905_0002
Revises: 20260825_0001
Create Date: 2026-09-05 00:00:00.000000

"""

from typing import Sequence

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = "20260905_0002"
down_revision: str | None = "20260825_0001"
branch_labels: Sequence[str] | None = None
depends_on: Sequence[str] | None = None


def upgrade() -> None:
    op.drop_index("ix_auth_sessions_expires_at", table_name="auth_sessions")
    op.drop_index("ix_auth_sessions_session_token", table_name="auth_sessions")
    op.drop_column("auth_sessions", "expires_at")
    op.drop_column("auth_sessions", "revoked_at")
    op.drop_column("auth_sessions", "session_token")
    op.alter_column("auth_sessions", "created_at", new_column_name="linked_at")


def downgrade() -> None:
    op.alter_column("auth_sessions", "linked_at", new_column_name="created_at")
    op.add_column("auth_sessions", sa.Column("session_token", sa.String(length=128), nullable=True))
    op.add_column("auth_sessions", sa.Column("expires_at", sa.DateTime(timezone=True), nullable=True))
    op.add_column("auth_sessions", sa.Column("revoked_at", sa.DateTime(timezone=True), nullable=True))
    op.create_index("ix_auth_sessions_session_token", "auth_sessions", ["session_token"], unique=True)
    op.create_index("ix_auth_sessions_expires_at", "auth_sessions", ["expires_at"])