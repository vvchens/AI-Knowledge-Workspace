# Phase 0 设计基线草案

## 1. 目标

Phase 0 的目标不是先做可交付功能，而是把后续实现的边界、架构决策和协作规则固定下来，确保进入 Phase 1 时，团队可以直接从“统一基线”开始开发。

本版本基于项目总说明、需求规范、架构说明和路线图，形成一份适合后续开发的 Phase 0 设计基线。

---

## 2. 项目定位

AI Knowledge Workspace 是一个多项目、基于 RAG 的 AI 知识平台。其核心价值在于：

- 每个 Project 都是一个独立 AI 应用
- 用户通过项目内知识库问答，而非全局共享知识
- 后端负责 Project 级授权与数据隔离
- 前端只负责 UI 与交互，不负责安全 enforcement
- 应用层负责检索、提示词构建、工具调用和评估

项目最终目标是做成一个“可展示的真实 AI SaaS 风格 portfolio 项目”，而不是单纯的 PDF 问答 demo。

---

## 3. Phase 0 产出范围

Phase 0 的主要交付物包括：

1. 需求与边界说明
2. 架构说明
3. 数据库模型草案
4. API 契约草案
5. 前端导航与屏幕结构
6. 设计系统基线
7. ADR 模板
8. repo / CI 基础结构
9. Codex/AI 协作规范

本阶段不做大规模功能实现，但必须让团队对“后续功能该怎么搭建”形成一致认知。

---

## 4. 技术架构基线

### 4.1 前端

- Flutter
- 适配 Web + Android + iOS
- 推荐技术：Riverpod、GoRouter、Dio、Freezed、json_serializable
- UI 基础：Material 3

### 4.2 后端

- FastAPI
- 负责：认证、授权、Project 管理、文档管理、Chat、Prompt、评估、AI runtime orchestration
- 注意：后端对外暴露的 API 应该是应用层抽象，而不是供应商特定实现

### 4.3 数据层

- PostgreSQL + pgvector
- 作为系统主数据存储与检索核心
- 负责：users、projects、memberships、documents、chunks、embeddings、conversations、messages、prompts、prompt versions、evaluation datasets 等

### 4.4 存储层

- 对象存储（S3/R2/MinIO）
- 存储原始文档文件
- PostgreSQL 存储 metadata 和对象引用

### 4.5 工作流与异步

- Redis / queue 用于异步文档处理
- 流程：Upload -> create ingestion job -> queue -> worker -> parse -> chunk -> embed -> persist -> indexed

### 4.6 AI runtime

架构应抽象以下能力：

- LLMProvider
- EmbeddingProvider
- Retriever
- Reranker
- PromptBuilder
- Tool
- Agent
- EvaluationRunner

要求：业务代码不要直接耦合到某个 vendor SDK。

---

## 5. 产品边界与范围

### 5.1 角色

#### Administrator

- 创建/管理 Project
- 上传、删除和重建索引文档
- 配置 prompt 与 model
- 管理 Project 用户
- 运行评估
- 查看运营/项目指标

#### Normal User

- 查看有权限的 Project
- 在 Project 内提问
- 查看历史会话
- 查看答案 citation
- 提供简单反馈

### 5.2 非目标（Phase 0 确认）

以下内容不在初始范围内：

- 自行训练模型
- 自研基础向量引擎
- 自研 LLM 推理引擎
- 扩展所有文档格式
- 所有 Agent 能力
- 所有 LLM provider

---

## 6. 多项目隔离原则

这是这个项目最重要的工程约束之一。

### 6.1 强约束

- 所有 Project-owned 资源都必须绑定 project_id
- 检索前必须执行 Project 级过滤
- 前端不能被用来替代后端授权
- 用户只能访问其拥有权限的 Project

### 6.2 示例字段

- Document.project_id
- Chunk.document_id -> Document.project_id
- Conversation.project_id
- Prompt.project_id
- EvaluationSet.project_id

这项约束必须在数据库设计与 API 设计中显式写清楚，不能“后面再补”。

---

## 7. 数据模型草案

### 7.1 核心实体

#### users

- id
- auth_provider
- provider_user_id
- firebase_uid (nullable)
- email
- email_verified
- display_name
- avatar_url
- locale
- status
- last_login_at
- created_at
- updated_at

说明：

- `auth_provider` 用于记录身份来源，如 `firebase`、`clerk`、`auth0` 或 `local`
- `provider_user_id` 是第三方身份供应商中的用户唯一 ID
- `firebase_uid` 仅用于 Firebase 场景，便于与 Firebase Admin SDK 直接对接
- `email`、`display_name` 等字段可由 provider 回调同步，但必须经过最小必要字段校验
- 用户的业务角色不应直接存放在 `users` 表中，而应通过 `project_memberships` 绑定到具体 Project

#### projects

- id
- name
- slug
- description
- status
- created_by
- created_at
- updated_at

#### project_memberships

- id
- project_id
- user_id
- role
- created_at

#### documents

- id
- project_id
- filename
- storage_key
- mime_type
- status
- parse_status
- indexing_version
- created_at
- updated_at

#### document_chunks

- id
- document_id
- project_id
- chunk_index
- content
- embedding
- metadata_json
- created_at

#### conversations

- id
- project_id
- user_id
- title
- created_at
- updated_at

#### messages

- id
- conversation_id
- project_id
- role
- content
- metadata_json
- created_at

#### prompts

- id
- project_id
- name
- system_prompt
- version
- status
- created_by
- created_at

#### evaluation_sets

- id
- project_id
- name
- created_by
- created_at

#### evaluation_cases

- id
- evaluation_set_id
- project_id
- question
- expected_answer
- metadata_json
- created_at

---

## 8. 认证与身份提供商接入方案

### 8.1 总体策略

建议采用“双层模型”：

1. 身份层：由 Firebase / Auth0 / Clerk 等外部提供商负责认证与 token 颁发
2. 应用层：由 FastAPI 负责验证 token、绑定 internal user、执行 Project 级授权

这意味着：

- 用户不再依赖本地密码体系作为唯一认证入口
- 本地 `users` 表保存的是“已认证的应用用户”记录，而非认证凭据本身
- 原始 token / secret 不应保存到数据库中
- `project_memberships` 继续负责“用户在某个 Project 中的权限”

### 8.2 推荐抽象

```text
AuthProvider
 ├── FirebaseAuthProvider
 ├── Auth0AuthProvider
 ├── ClerkAuthProvider
 └── LocalAuthProvider
```

统一能力：

- verify_token()
- get_provider_user_id()
- sync_user_profile()
- get_user_email()
- get_user_display_name()

### 8.3 Firebase 接入建议

当使用 Firebase 时：

- 前端使用 Firebase Auth 获取 ID token
- 后端用 Firebase Admin SDK 验证 token
- token 验证成功后，按 `firebase_uid` 或 `provider_user_id` 在本地用户表中匹配或创建用户
- 仅保存最小必要的用户资料，不保存秘密或长生命周期 token
- 通过 `project_memberships` 给用户授权，而不是在 `users` 表里写死全局角色

### 8.4 安全要求

- 不信任 client 端的角色和权限状态
- 所有项目数据访问必须经过服务端 permission check
- 记录关键认证操作：login、logout、membership change、role escalation
- 对未验证 provider token 直接拒绝访问

---

## 10. RAG 架构草案

目标架构应保持独立测试能力，不能把整个 pipeline 全塞进一个单体 service。

```text
Question
  ↓
Optional Query Rewrite
  ↓
Project Metadata Filter
  ↓
Dense Vector Search
  +
Full-Text Search
  ↓
Hybrid Rank Fusion
  ↓
Reranker
  ↓
Context Selection
  ↓
PromptBuilder
  ↓
LLMProvider
  ↓
Answer + Citations
```

### 10.1 设计要求

- Dense retrieval 与 FTS 分开实现
- Hybrid retrieval 可以后续加入 rank fusion
- 检索组件需要单元测试
- citation 必须基于 document / chunk source
- retrieval 与 generation 是分层的，不应混成一个大函数

---

## 11. API 契约草案

### 11.1 Auth

- POST /api/v1/auth/login
- POST /api/v1/auth/register
- POST /api/v1/auth/logout
- POST /api/v1/auth/firebase/session

### 11.2 Projects

- GET /api/v1/projects
- POST /api/v1/projects
- GET /api/v1/projects/{projectId}
- PATCH /api/v1/projects/{projectId}
- DELETE /api/v1/projects/{projectId}

### 11.3 Documents

- POST /api/v1/projects/{projectId}/documents/upload
- GET /api/v1/projects/{projectId}/documents
- GET /api/v1/projects/{projectId}/documents/{documentId}
- DELETE /api/v1/projects/{projectId}/documents/{documentId}
- POST /api/v1/projects/{projectId}/documents/{documentId}/reindex

### 11.4 Chat

- GET /api/v1/projects/{projectId}/conversations
- POST /api/v1/projects/{projectId}/conversations
- POST /api/v1/projects/{projectId}/chat
- GET /api/v1/projects/{projectId}/conversations/{conversationId}/messages

### 11.5 Prompt

- GET /api/v1/projects/{projectId}/prompts
- POST /api/v1/projects/{projectId}/prompts
- PATCH /api/v1/projects/{projectId}/prompts/{promptId}
- POST /api/v1/projects/{projectId}/prompts/{promptId}/versions

### 11.6 Evaluation

- GET /api/v1/projects/{projectId}/evaluations
- POST /api/v1/projects/{projectId}/evaluations/run
- GET /api/v1/projects/{projectId}/evaluations/{id}

### 11.7 安全要求

- 所有带 projectId 的请求都必须在后端校验权限
- 结果必须默认按 Project 过滤
- 日志中不要泄露敏感 token / secret

---

## 12. 用户导航和屏幕结构

### 12.1 用户视角

- Login
- Project List
- Project Chat
- Conversation History
- Project Selection

### 12.2 管理员视角

- Dashboard
- Projects
- Project Overview
- Documents
- Prompt
- AI / Retrieval
- Tools
- Users
- Evaluation
- Settings

### 12.3 路由草案

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

---

## 13. 设计系统基线

### 13.1 UI 方向

- Material 3
- Modern AI SaaS 风格
- 低噪音，专业、清晰
- 强信息层级
- 桌面和移动端都需要单独设计布局策略

### 13.2 视觉约束

- 主色：休闲紫/靛蓝系，偏中性
- spacing 使用 4 / 8 / 12 / 16 / 24 / 32 / 48 / 64
- radius 采用 8 / 12 / 16
- 组件应中心化在 theme 中，不在 widget 中硬编码颜色和间距

---

## 14. CI 与工程基线

### 14.1 最小 CI

- lint
- format check
- unit tests
- optional backend smoke tests

### 14.2 最小 repo 结构

```text
/README.md
/REQUIREMENTS.md
/ARCHITECTURE.md
/ROADMAP.md
/CODEX_INSTRUCTIONS.md
/docs/
  /phase0/
  /design/
  /adr/
/.github/workflows/
```

### 14.3 协作要求

- 所有重大架构改动需要有 ADR 或设计说明
- AI 生成代码需要人工 review
- 任何与权限、RAG、provider 抽象相关的代码必须在设计文档中可追踪

---

## 15. Phase 0 Exit Criteria

Phase 0 可以被视为完成的前提是：

1. 两位成员对架构和边界达成一致
2. 核心屏幕和导航已确认
3. 数据库模型与 API 边界已稳定
4. Project 隔离机制已被写入设计要求
5. AI provider 抽象已被确定
6. Codex/AI 协作规则已落地
7. repo 与 CI 基线已初始化

---

## 14. 紧接着的下一步

接下来应进入 Phase 1 的准备动作：

1. 确认是否采用 monorepo 或前后端分仓
2. 初始化 Flutter + FastAPI 的目录结构
3. 拉起 Docker Compose 本地开发环境
4. 完成基础用户认证与 RBAC schema
5. 初始化 PostgreSQL 迁移脚本
6. 准备最小的 document upload -> ingestion pipeline skeleton

---

## 15. 结论

本草案的核心思想是：

> 先把“架构、边界、权限、数据模型、交互结构”定下来，然后再用 AI coding agent 开发，不让 Phase 1 从文档混乱和技术不一致中开始。

如果这个草案被接受，后续即可进入真实开发的 Phase 1，并以 Project-scope RAG 能力为第一优先级目标。
