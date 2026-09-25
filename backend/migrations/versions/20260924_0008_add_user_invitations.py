"""add user roles and invitations

Revision ID: 20260924_0008
Revises: 20260924_0007
"""

from typing import Sequence

from alembic import op
import sqlalchemy as sa


revision: str = "20260924_0008"
down_revision: str | None = "20260924_0007"
branch_labels: Sequence[str] | None = None
depends_on: Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "users",
        sa.Column("role", sa.String(length=32), nullable=False, server_default="member"),
    )
    op.create_table(
        "user_invitations",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("email", sa.String(length=320), nullable=False),
        sa.Column("role", sa.String(length=32), nullable=False),
        sa.Column("token_hash", sa.String(length=128), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("accepted_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_by_id", sa.String(length=36), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.ForeignKeyConstraint(["created_by_id"], ["users.id"]),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("token_hash"),
    )
    op.create_index("ix_user_invitations_email", "user_invitations", ["email"])
    op.create_index("ix_user_invitations_expires_at", "user_invitations", ["expires_at"])


def downgrade() -> None:
    op.drop_index("ix_user_invitations_expires_at", table_name="user_invitations")
    op.drop_index("ix_user_invitations_email", table_name="user_invitations")
    op.drop_table("user_invitations")
    op.drop_column("users", "role")