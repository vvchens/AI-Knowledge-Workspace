# AI Knowledge Workspace — Navigation

## User Navigation

```text
Login
  |
  +-- Project List
       |
       +-- Project Chat
       |
       +-- Conversation History
       |
       +-- Project Selection
```

Mobile primary navigation:

```text
Projects
Chat
History
Profile
```

---

## Admin Navigation

```text
Dashboard
Projects
  |
  +-- Project Overview
  +-- Documents
  +-- Prompt
  +-- AI / Retrieval
  +-- Tools
  +-- Users
  +-- Evaluation

Users
Evaluation
Settings
```

---

## Routes

Initial route concepts:

```text
/login

/projects
/projects/:projectId/chat
/projects/:projectId/history

/admin
/admin/projects
/admin/projects/:projectId
/admin/projects/:projectId/documents
/admin/projects/:projectId/prompt
/admin/projects/:projectId/ai
/admin/projects/:projectId/tools
/admin/projects/:projectId/users
/admin/projects/:projectId/evaluation
/admin/users
/admin/evaluation
/admin/settings
```

Actual route naming may be adjusted during implementation, but changes must preserve the information architecture.
