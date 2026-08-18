from fastapi import APIRouter

router = APIRouter(prefix="/projects", tags=["projects"])


@router.get("")
def list_projects() -> dict[str, list[dict[str, str]]]:
    return {
        "projects": [
            {"id": "project_001", "name": "Demo Project", "status": "active"},
        ]
    }


@router.post("")
def create_project() -> dict[str, str]:
    return {"status": "created", "message": "Project creation is not implemented yet."}
