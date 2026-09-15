"""add document chunk metadata

Revision ID: 20260912_0006
Revises: 20260909_0005
Create Date: 2026-09-12 00:00:00.000000
"""

from typing import Sequence

from alembic import op
import sqlalchemy as sa


revision: str = "20260912_0006"
down_revision: str | None = "20260909_0005"
branch_labels: Sequence[str] | None = None
depends_on: Sequence[str] | None = None


def upgrade() -> None:
    op.add_column("document_chunks", sa.Column("project_id", sa.String(length=36), nullable=True))
    op.add_column("document_chunks", sa.Column("document_name", sa.String(length=255), nullable=True))
    op.add_column(
        "document_chunks",
        sa.Column("metadata", sa.JSON(), nullable=False, server_default=sa.text("'{}'::json")),
    )

    op.execute(
        sa.text(
            """
            UPDATE document_chunks AS chunks
            SET project_id = documents.project_id,
                document_name = documents.name
            FROM documents
            WHERE documents.id = chunks.document_id
            """
        )
    )
    op.alter_column("document_chunks", "project_id", nullable=False)
    op.alter_column("document_chunks", "document_name", nullable=False)
    op.alter_column("document_chunks", "metadata", server_default=None)
    op.create_foreign_key(
        "fk_document_chunks_project_id",
        "document_chunks",
        "projects",
        ["project_id"],
        ["id"],
        ondelete="CASCADE",
    )
    op.create_index("ix_document_chunks_project_id", "document_chunks", ["project_id"])


def downgrade() -> None:
    op.drop_index("ix_document_chunks_project_id", table_name="document_chunks")
    op.drop_constraint("fk_document_chunks_project_id", "document_chunks", type_="foreignkey")
    op.drop_column("document_chunks", "metadata")
    op.drop_column("document_chunks", "document_name")
    op.drop_column("document_chunks", "project_id")