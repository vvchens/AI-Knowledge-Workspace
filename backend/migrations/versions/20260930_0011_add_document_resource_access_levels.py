"""add document resource access levels"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = "20260930_0011"
down_revision = "20260930_0010"
branch_labels = None
depends_on = None

def upgrade():
    source_type = postgresql.ENUM("SYSTEM", "ORGANIZATION", "USER", name="document_source_type")
    access_level = postgresql.ENUM("READ_ONLY", "ORGANIZATION", "PRIVATE", name="document_access_level")
    bind = op.get_bind()
    source_type.create(bind, checkfirst=True)
    access_level.create(bind, checkfirst=True)
    op.add_column("documents", sa.Column("source_type", source_type, nullable=False, server_default="USER"))
    op.add_column("documents", sa.Column("access_level", access_level, nullable=False, server_default="PRIVATE"))
    op.create_index("ix_documents_source_type", "documents", ["source_type"])
    op.create_index("ix_documents_access_level", "documents", ["access_level"])

def downgrade():
    op.drop_index("ix_documents_access_level", table_name="documents")
    op.drop_index("ix_documents_source_type", table_name="documents")
    op.drop_column("documents", "access_level")
    op.drop_column("documents", "source_type")
    bind = op.get_bind()
    postgresql.ENUM(name="document_access_level").drop(bind, checkfirst=True)
    postgresql.ENUM(name="document_source_type").drop(bind, checkfirst=True)
