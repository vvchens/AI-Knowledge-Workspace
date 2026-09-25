"""use an enum for document status

Revision ID: 20260924_0007
Revises: 20260912_0006
Create Date: 2026-09-24 00:00:00.000000

"""

from typing import Sequence

from alembic import op
import sqlalchemy as sa


revision: str = "20260924_0007"
down_revision: str | None = "20260912_0006"
branch_labels: Sequence[str] | None = None
depends_on: Sequence[str] | None = None


document_status = sa.Enum("PROCESSING", "INDEXED", "FAILED", name="document_status")


def upgrade() -> None:
    op.execute(
        "UPDATE documents SET status = 'INDEXED' "
        "WHERE status NOT IN ('PROCESSING', 'INDEXED', 'FAILED')"
    )
    document_status.create(op.get_bind(), checkfirst=True)
    op.alter_column(
        "documents",
        "status",
        existing_type=sa.String(length=32),
        type_=document_status,
        postgresql_using="status::document_status",
        existing_nullable=False,
    )


def downgrade() -> None:
    op.alter_column(
        "documents",
        "status",
        existing_type=document_status,
        type_=sa.String(length=32),
        postgresql_using="status::text",
        existing_nullable=False,
    )
    document_status.drop(op.get_bind(), checkfirst=True)