# 通用 Multi-tenant RAG 平台需求文档

## 1. 项目概述

### 1.1 项目定位

本项目是一个**通用的企业级 Multi-tenant RAG（Retrieval-Augmented Generation）平台**。

平台本身不绑定任何特定行业。核心能力包括：

* 用户与组织管理
* 多租户隔离
* RBAC 权限控制
* 文档管理
* 知识库管理
* 文档解析与 Chunking
* Embedding
* 向量检索
* RAG 问答
* Prompt 管理
* 可配置 Workflow
* 文档审核/分析能力
* 模块化业务能力

平台可以通过 **Module / Preset** 为特定行业提供预配置能力。

第一个实际落地场景为：

> **Real Estate Compliance**

用于房地产 Agent、Broker 等专业用户，根据组织配置的法律法规、政策和其他知识库，对合同、广告、披露文件及其他文本进行辅助审核。

但是：

> **房地产逻辑不得直接耦合到 RAG Core。**

房地产只是平台上的一个 Module / Preset。

---

# 2. 核心设计原则

## 2.1 RAG Core 与业务模块分离

核心 RAG 系统只负责通用能力：

```text
Document
Knowledge Base
Chunk
Embedding
Retrieval
Prompt
LLM
Workflow
User
Organization
Permission
```

不得在核心代码中大量出现：

```python
if industry == "real_estate":
    ...
```

行业特定逻辑应该通过 Module、配置、Prompt、Workflow 和 Document Type 实现。

---

## 2.2 Multi-tenant

平台支持多个 Organization。

Organization 之间的数据必须逻辑隔离。

例如：

```text
Organization A
    ├── Users
    ├── Knowledge Bases
    ├── Documents
    └── Workflows

Organization B
    ├── Users
    ├── Knowledge Bases
    ├── Documents
    └── Workflows
```

Organization A 的普通用户不能访问 Organization B 的资源。

---

## 2.3 权限控制必须在 Backend 强制执行

Frontend 只负责展示允许用户执行的操作。

真正的权限检查必须在 FastAPI Backend 完成。

例如：

```text
DELETE /documents/{id}
        ↓
Authentication
        ↓
Authorization
        ↓
Resource ownership / organization check
        ↓
Document permission check
        ↓
Allow / 403 Forbidden
```

不能依赖：

```text
隐藏 Delete 按钮
```

来实现安全控制。

---

# 3. 用户与角色模型

系统至少包含两个管理层级。

## 3.1 System Admin

System Admin 是平台级管理员。

主要职责：

* 管理 Organization
* 创建/停用 Organization
* 管理系统级配置
* 管理 Module / Preset
* 管理系统级 Prompt Template
* 管理系统级 Workflow Template
* 管理系统级模型配置
* 管理平台运行状态
* 管理平台级资源

System Admin 不等同于某个 Organization 的普通 Admin。

平台必须支持通过后端环境变量注入最高权限账户 ID。环境变量使用逗号分隔的 Firebase UID，兼容本地 User ID；匹配账户完成 Firebase 登录后，Backend 必须自动将其标记为 `system_admin`。该权限不得由 Frontend 注入或修改。

---

## 3.2 Organization Admin

Organization Admin 是组织级管理员。

职责：

* 管理本组织成员
* 管理本组织 Knowledge Base
* 上传和管理组织文档
* 设置文档权限
* 配置组织级 Prompt
* 配置 Workflow
* 启用/配置 Module
* 管理组织级资源

Organization Admin 只能管理自己所属 Organization 的资源。

---

## 3.3 Organization User

普通用户主要使用平台提供的功能。

例如：

* 查询 Knowledge Base
* 使用 RAG
* 上传自己的文档
* 对自己的文档执行分析
* 使用 Organization 开放的 Workflow
* 查看自己有权限访问的资源

普通用户不能修改 Organization 全局设置。

---

# 4. User 与 Organization 的关系

User 与 Organization 不应该简单设计成：

```text
users.organization_id
```

而应该使用 Membership 模型：

```text
User
  │
  │ many-to-many
  ▼
Organization
```

建议：

```text
users
organizations
organization_members
```

其中：

```text
organization_members
--------------------
user_id
organization_id
role
status
created_at
```

这样一个用户未来可以属于多个 Organization。

例如：

```text
User A

Organization X → Admin
Organization Y → User
```

---

# 5. Organization

Organization 是平台的核心租户边界。

Organization 可以代表：

* 公司
* Brokerage
* 团队
* 学校
* 企业部门
* 其他独立组织

Organization 至少包含：

```text
id
name
slug
status
settings
created_at
updated_at
```

---

# 6. Module / Preset

## 6.1 概念

Module 是平台针对特定业务场景提供的**能力模板**。

Module 不应该修改 RAG Core。

Module 可以包含：

```text
Module
├── Prompt Templates
├── Workflow Templates
├── Document Types
├── Review Types
├── Default Settings
├── UI configuration
└── Knowledge Base configuration
```

---

## 6.2 示例 Module

未来可以存在：

```text
Real Estate Compliance
Legal Research
HR Policy
Customer Support
Technical Documentation
```

但这些都不是 RAG Core 的固定组成部分。

---

# 7. Real Estate Module

第一个实际落地场景为：

```text
Real Estate Compliance
```

它只是一个 Module / Preset。

## 7.1 典型用户

* Real Estate Agent
* Broker
* Brokerage Administrator
* Compliance Manager

---

## 7.2 典型知识库

Organization Admin 可以配置：

```text
Georgia Laws
Georgia Real Estate Commission Rules
Brokerage Policies
Office Compliance Manual
Forms
Internal Procedures
```

其中官方法律法规可以设置为：

```text
READ_ONLY
```

---

## 7.3 典型使用场景

### RAG Question

例如：

```text
What does Georgia law require for this type of advertisement?
```

---

### Document Review

用户上传：

```text
listing.pdf
contract.pdf
advertisement.txt
```

然后：

```text
Review this document for potential compliance issues.
```

系统通过 RAG 检索相关法规并生成分析结果。

---

### Advertisement Review

例如：

```text
Review this real estate advertisement against
the organization's regulatory knowledge base.
```

---

### Contract Review

例如：

```text
Review this contract and identify provisions
that may require further review.
```

---

## 7.4 合规分析结果

系统不应该简单输出：

```text
LEGAL
ILLEGAL
```

而应该输出结构化结果，例如：

```text
Compliant
Potential Issue
Needs Review
Unable to Determine
```

每一个 finding 应尽可能包含：

```text
Issue
Explanation
Document Evidence
Relevant Source
Source Chunk
```

系统应该明确区分：

* RAG 检索到的事实
* LLM 的分析
* 不确定性
* 需要人工进一步确认的内容

系统不能把 AI 分析包装成确定性的法律意见。

---

# 8. Knowledge Base

Knowledge Base 是一组具有共同用途和权限边界的 Documents。

例如：

```text
Knowledge Base: Georgia Real Estate Regulations

Documents:
├── Georgia Code
├── GREC Rules
├── Definitions
└── Advertising Rules
```

Knowledge Base 应至少包含：

```text
id
organization_id
name
description
status
visibility
created_at
updated_at
```

---

# 9. Document

Document 是平台中的基础知识资源。

建议至少包含：

```text
id
organization_id
owner_id
knowledge_base_id
title
source_type
access_level
status
metadata
created_at
updated_at
```

---

# 10. Document Source Type

Document 应支持来源类型。

第一版可以包括：

```text
SYSTEM
ORGANIZATION
USER
```

含义：

### SYSTEM

平台级资源。

例如：

```text
System documentation
System prompt reference
```

---

### ORGANIZATION

Organization Admin 管理的组织资源。

例如：

```text
Company Policy
Brokerage Compliance Manual
Official Regulations
```

---

### USER

用户自己的文档。

例如：

```text
My Listing
My Contract
My Draft Advertisement
```

---

# 11. Document Access Level

建议至少支持：

```text
READ_ONLY
ORGANIZATION
PRIVATE
```

## READ_ONLY

用户可以：

* 查看
* 搜索
* RAG 检索

但不能：

* 修改
* 删除

例如：

```text
Official Laws
Official Regulations
```

---

## ORGANIZATION

Organization 成员可以根据组织权限访问。

Organization Admin 可以管理。

---

## PRIVATE

只有 owner 和被授权用户可以访问。

---

# 12. Read-only 文档

Read-only 是本项目的重要功能。

例如 Organization Admin 上传：

```text
Georgia Real Estate Commission Rules
```

并设置：

```text
source_type = ORGANIZATION
access_level = READ_ONLY
```

则：

```text
Organization Admin
    View       ✓
    Search     ✓
    RAG        ✓
    Edit       ✓
    Delete     ✓

Organization User
    View       ✓
    Search     ✓
    RAG        ✓
    Edit       ✗
    Delete     ✗
```

注意：

> Read-only 必须由 Backend 强制执行。

不能仅通过前端隐藏按钮实现。

---

# 13. Document 与 RAG 数据关系

Document 与 Chunk、Embedding 应建立明确关系：

```text
Document
   │
   ├── Chunk
   │     ├── Embedding
   │     ├── metadata
   │     └── source location
   │
   └── metadata
```

用户删除 Document 时，应级联处理：

```text
Document
   ↓
Chunks
   ↓
Embeddings
   ↓
Document metadata
```

避免出现：

```text
Document 已删除
但 Vector DB 中仍然可以检索到内容
```

---

# 14. RAG Retrieval

RAG Retrieval 必须执行权限过滤。

不能出现：

```text
用户 A 查询
    ↓
Vector Search
    ↓
返回 Organization B 的 chunk
```

正确流程：

```text
User
 ↓
Organization Context
 ↓
Permission Filter
 ↓
Vector Retrieval
 ↓
Authorized Chunks
 ↓
LLM
```

权限过滤必须在 Retrieval 层考虑。

---

# 15. Prompt

Prompt 应支持不同级别。

```text
System Prompt
Organization Prompt
Module Prompt
Workflow Prompt
User Query
```

推荐优先级：

```text
System
  ↓
Organization
  ↓
Module
  ↓
Workflow
  ↓
User Input
```

具体优先级和覆盖规则需要在实现阶段明确。

---

# 16. Workflow

Workflow 用于描述复杂的 RAG 操作。

基础 RAG：

```text
User Question
      ↓
Retrieve
      ↓
Generate Answer
```

Document Review：

```text
Document
   ↓
Parse
   ↓
Retrieve Relevant Knowledge
   ↓
Analyze
   ↓
Generate Findings
   ↓
Generate Report
```

Workflow 应尽量配置化，而不是写死在 RAG Core 中。

---

# 17. 通用 RAG 与业务 Workflow 的关系

核心：

```text
RAG Engine
```

负责：

* Parsing
* Chunking
* Embedding
* Retrieval
* Context construction
* LLM generation

业务 Module：

```text
Real Estate Compliance
```

负责定义：

```text
什么时候调用 RAG
检索什么
使用什么 Prompt
如何组织结果
如何生成 Review Report
```

---

# 18. 权限模型

整体权限结构：

```text
SYSTEM
│
├── System Admin
│
└── Organizations
      │
      ├── Organization Admin
      │
      └── Organization Users
```

资源 Scope：

```text
SYSTEM
ORGANIZATION
PRIVATE
```

权限判断至少需要考虑：

```text
User
Role
Organization Membership
Resource Owner
Resource Organization
Resource Access Level
Action
```

例如：

```text
Can User X delete Document Y?
```

需要依次判断：

```text
User authenticated?
        ↓
User belongs to Document's organization?
        ↓
Is user System Admin?
        ↓
Is user Organization Admin?
        ↓
Is user document owner?
        ↓
Is document READ_ONLY?
        ↓
Allow / Deny
```

---

# 19. API 安全要求

所有资源 API 必须进行：

1. Authentication
2. Authorization
3. Organization isolation
4. Resource ownership/access check

例如：

```text
GET /documents/{id}
POST /documents
PATCH /documents/{id}
DELETE /documents/{id}
```

不能仅通过：

```text
document_id
```

直接操作数据库。

---

# 20. 前端要求

Frontend 应根据权限显示功能。

例如普通用户看到：

```text
Document
├── View
├── Search
└── Ask
```

Organization Admin 看到：

```text
Document
├── View
├── Search
├── Edit
├── Delete
└── Permission
```

但：

> UI 权限控制只是 UX，Backend Authorization 才是真正的安全边界。

---

# 21. MVP 第一阶段

第一阶段不追求实现所有复杂功能。

建议 MVP 包括：

### Authentication

* Login
* User
* System Admin
* Organization Admin
* Organization User

### Organization

* Create Organization
* Organization membership
* Organization Admin

### Knowledge Base

* Create
* List
* View
* Delete

### Document

* Upload
* Parse
* Store
* Chunk
* Embedding
* Search
* Delete

### Permission

* System Admin
* Organization Admin
* Organization User
* Read-only Document

### RAG

* Question
* Retrieval
* Answer
* Source citation

---

# 22. MVP 第二阶段

增加：

```text
Module
Workflow
Prompt Template
Document Review
Structured Findings
```

然后实现：

```text
Real Estate Compliance Module
```

---

# 23. 后续扩展

未来可以支持：

```text
Multiple Organizations per User
Team / Department
Fine-grained ACL
Document Sharing
Document Versioning
Audit Log
Usage Tracking
Billing
Multiple LLM Providers
Multiple Embedding Providers
Hybrid Search
Reranking
Evaluation
Automated RAG Evaluation
Workflow Builder
Plugin / Module Marketplace
```

---

# 24. 非目标

第一阶段不应该做：

* 把平台做成房地产专用系统
* 将 Georgia 法规硬编码到 Backend
* 将房地产规则写死到 RAG Engine
* 实现复杂的企业级 ACL
* 实现完整 Billing
* 实现复杂 Workflow Builder
* 实现全自动法律结论

核心目标是：

> **先建立一个干净、可扩展的 Multi-tenant RAG Platform。**

---

# 25. 总体架构

最终逻辑架构：

```text
                         RAG PLATFORM
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
   System Admin          Module / Preset       Organizations
                              │                     │
                    ┌─────────┼─────────┐           │
                    │         │         │           │
               Real Estate  Legal     HR       Organization A
               Compliance  Research  Policy          │
                                                      │
                                      ┌───────────────┼──────────────┐
                                      │               │              │
                                   Members       Knowledge Bases   Settings
                                                      │
                                                 Documents
                                                      │
                                           ┌──────────┴──────────┐
                                           │                     │
                                      Organization             Private
                                      Documents               Documents
                                           │
                                      READ_ONLY
                                           │
                                      RAG Engine
                                           │
                              ┌────────────┼────────────┐
                              │            │            │
                           Retrieval    Prompt       Workflow
                              │            │            │
                              └────────────┼────────────┘
                                           │
                                          LLM
                                           │
                                        Result
```

---

# 26. 核心实体关系

初步数据模型：

```text
User
  │
  ├──────────────┐
  │              │
  ▼              ▼
OrganizationMember  Personal Resources
  │
  ▼
Organization
  │
  ├── KnowledgeBase
  │       │
  │       └── Document
  │               │
  │               └── Chunk
  │                       │
  │                       └── Embedding
  │
  ├── Prompt
  ├── Workflow
  └── Module
```

平台级：

```text
SystemAdmin
   │
   ├── Organization
   ├── Module
   ├── System Prompt
   └── System Configuration
```

---

# 27. 设计目标总结

本项目最终应该体现以下能力：

### 通用性

RAG Core 与具体行业无关。

### Multi-tenancy

不同 Organization 数据严格隔离。

### RBAC

System Admin、Organization Admin、Organization User 权限分离。

### Resource-level Permission

不同 Document 可以拥有不同访问权限。

### Read-only Knowledge

官方法规等知识可以作为只读知识源供所有组织成员查询。

### Modular

行业功能通过 Module / Preset 实现。

### Configurable

Prompt、Workflow、Knowledge Base 等尽量配置化。

### Extensible

未来可以增加新的行业和业务场景，而无需修改 RAG Core。

---

# 28. 第一阶段核心原则

开发过程中必须始终遵守：

> **RAG Core 不知道“地产”是什么。**

它只知道：

```text
User
Organization
Knowledge Base
Document
Chunk
Embedding
Retrieval
Prompt
Workflow
Permission
```

而：

```text
Real Estate Compliance
```

只是这些通用能力的一种组合。

这样才能保证本项目最终是：

> **一个通用的 Multi-tenant RAG Platform，而不是一个房地产 RAG Demo。**
