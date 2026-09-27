"""add organizations and membership-based authorization

Revision ID: 20260927_0009
Revises: 20260924_0008
"""

from typing import Sequence

from alembic import op
import sqlalchemy as sa


revision: str = "20260927_0009"
down_revision: str | None = "20260924_0008"
branch_labels: Sequence[str] | None = None
depends_on: Sequence[str] | None = None


def upgrade() -> None:
    op.add_column("users", sa.Column("system_role", sa.String(length=32), nullable=False, server_default="user"))
    op.create_table(
        "organizations",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("name", sa.String(length=255), nullable=False),
        sa.Column("slug", sa.String(length=255), nullable=False),
        sa.Column("status", sa.String(length=32), nullable=False, server_default="active"),
        sa.Column("settings", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("slug"),
    )
    op.create_table(
        "organization_members",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("organization_id", sa.String(length=36), nullable=False),
        sa.Column("user_id", sa.String(length=36), nullable=False),
        sa.Column("role", sa.String(length=32), nullable=False, server_default="user"),
        sa.Column("status", sa.String(length=32), nullable=False, server_default="active"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.ForeignKeyConstraint(["organization_id"], ["organizations.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("organization_id", "user_id", name="uq_organization_members_org_user"),
    )
    op.create_index("ix_organization_members_organization_id", "organization_members", ["organization_id"])
    op.create_index("ix_organization_members_user_id", "organization_members", ["user_id"])
    op.add_column("projects", sa.Column("organization_id", sa.String(length=36), nullable=True))
    op.add_column("user_invitations", sa.Column("organization_id", sa.String(length=36), nullable=True))
    op.create_index("ix_projects_organization_id", "projects", ["organization_id"])
    op.create_index("ix_user_invitations_organization_id", "user_invitations", ["organization_id"])
    op.create_table(
        "project_memberships",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("project_id", sa.String(length=36), nullable=False),
        sa.Column("user_id", sa.String(length=36), nullable=False),
        sa.Column("role", sa.String(length=32), nullable=False, server_default="member"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.ForeignKeyConstraint(["project_id"], ["projects.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("project_id", "user_id", name="uq_project_memberships_project_user"),
    )
    op.create_index("ix_project_memberships_project_id", "project_memberships", ["project_id"])
    op.create_index("ix_project_memberships_user_id", "project_memberships", ["user_id"])

    connection = op.get_bind()
    connection.execute(
        sa.text("UPDATE users SET system_role = 'system_admin' WHERE role = 'system_admin'")
    )
    default_org_id = "00000000-0000-0000-0000-000000000001"
    connection.execute(
        sa.text(
            "INSERT INTO organizations (id, name, slug) VALUES (:id, 'Default Organization', 'default')"
        ),
        {"id": default_org_id},
    )
    connection.execute(
        sa.text(
            "INSERT INTO organization_members (id, organization_id, user_id, role) "
            "SELECT md5(random()::text || clock_timestamp()::text), :org_id, id, "
            "CASE WHEN role = 'admin' THEN 'admin' ELSE 'user' END FROM users"
        ),
        {"org_id": default_org_id},
    )
    connection.execute(
        sa.text("UPDATE projects SET organization_id = :org_id WHERE organization_id IS NULL"),
        {"org_id": default_org_id},
    )
    connection.execute(
        sa.text("UPDATE user_invitations SET organization_id = :org_id WHERE organization_id IS NULL"),
        {"org_id": default_org_id},
    )
    connection.execute(
        sa.text(
            "INSERT INTO project_memberships (id, project_id, user_id, role) "
            "SELECT md5(random()::text || clock_timestamp()::text), id, owner_id, 'owner' FROM projects"
        )
    )
    op.alter_column("projects", "organization_id", nullable=False)
    op.alter_column("user_invitations", "organization_id", nullable=False)
    op.create_foreign_key(
        "fk_projects_organization_id", "projects", "organizations", ["organization_id"], ["id"], ondelete="CASCADE"
    )
    op.create_foreign_key(
        "fk_user_invitations_organization_id",
        "user_invitations",
        "organizations",
        ["organization_id"],
        ["id"],
        ondelete="CASCADE",
    )


def downgrade() -> None:
    op.drop_constraint("fk_user_invitations_organization_id", "user_invitations", type_="foreignkey")
    op.drop_constraint("fk_projects_organization_id", "projects", type_="foreignkey")
    op.drop_index("ix_project_memberships_user_id", table_name="project_memberships")
    op.drop_index("ix_project_memberships_project_id", table_name="project_memberships")
    op.drop_table("project_memberships")
    op.drop_index("ix_user_invitations_organization_id", table_name="user_invitations")
    op.drop_index("ix_projects_organization_id", table_name="projects")
    op.drop_column("user_invitations", "organization_id")
    op.drop_column("projects", "organization_id")
    op.drop_index("ix_organization_members_user_id", table_name="organization_members")
    op.drop_index("ix_organization_members_organization_id", table_name="organization_members")
    op.drop_table("organization_members")
    op.drop_table("organizations")
    op.drop_column("users", "system_role")