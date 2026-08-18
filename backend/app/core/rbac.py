from __future__ import annotations

from dataclasses import dataclass
from enum import Enum


class Role(str, Enum):
    OWNER = "owner"
    ADMIN = "admin"
    MEMBER = "member"
    VIEWER = "viewer"


@dataclass
class Membership:
    user_id: str
    project_id: str
    role: Role


class ProjectPermissionService:
    def can_access(self, membership: Membership | None, required_role: Role) -> bool:
        if membership is None:
            return False

        role_hierarchy = {
            Role.VIEWER: 1,
            Role.MEMBER: 2,
            Role.ADMIN: 3,
            Role.OWNER: 4,
        }

        return role_hierarchy.get(membership.role, 0) >= role_hierarchy.get(required_role, 0)
