# API Design

> REST API design patterns — status codes, pagination, error responses, authentication, rate limiting. The "what every backend API should follow" guide.

## 触发场景

- 设计新 API
- 修改现有 API 契约
- 设计错误响应格式
- 设计分页 / 排序 / 过滤
- 设计鉴权方案（Bearer / Cookie / API Key）
- 设计限流
- 涉及 OpenAPI / API 文档
- 任何后端 agent / skill 涉及 HTTP 接口

## 核心知识

### 1. HTTP 状态码（按场景）

| 码 | 含义 | 典型场景 |
|----|------|----------|
| **200** | OK | 成功（GET / 同步操作完成） |
| **201** | Created | 资源创建成功（POST） |
| **202** | Accepted | 已接收但未完成（异步任务） |
| **204** | No Content | 成功但无 body（DELETE / 部分 PUT） |
| **400** | Bad Request | 入参错误（schema 校验失败） |
| **401** | Unauthorized | 未认证（没 token / token 无效） |
| **403** | Forbidden | 已认证但无权限（鉴权失败） |
| **404** | Not Found | 资源不存在 |
| **409** | Conflict | 资源冲突（重复创建 / 状态机错误） |
| **422** | Unprocessable Entity | 格式对但语义错（业务校验失败） |
| **429** | Too Many Requests | 限流 |
| **500** | Internal Server Error | 兜底（永远返回 5xx） |
| **503** | Service Unavailable | 临时不可用（维护中 / 依赖挂了） |

**记忆口诀**：2xx = 成功，3xx = 重定向，4xx = 客户端错，5xx = 服务端错。

### 2. 资源命名

- **复数名词**：`/users` / `/orders` / `/payments`
- **kebab-case**：`/user-profiles` / `/payment-methods`（**不 snake_case**）
- **嵌套不超过 2 层**：`/users/{id}/orders` ✅ / `/users/{id}/orders/{oid}/items/{iid}/comments` ❌
- **动词只在特殊动作**：`/users/{id}/activate` / `/auth/login` / `/auth/refresh` / `/search`
- **不暴露实现**：`/getUsers` ❌ → `GET /users` ✅

### 3. HTTP 方法语义

| 方法 | 幂等 | 安全 | 用途 |
|------|------|------|------|
| **GET** | ✅ | ✅ | 读取（不修改） |
| **HEAD** | ✅ | ✅ | 只取 headers |
| **POST** | ❌ | ❌ | 创建 / 触发非幂等动作 |
| **PUT** | ✅ | ❌ | 完整替换资源 |
| **PATCH** | ❌ | ❌ | 部分更新 |
| **DELETE** | ✅ | ❌ | 删除（多次 DELETE 同一资源 = 一次删除） |

**关键点**：
- **GET 必须安全**（不改数据）——搜索引擎爬虫会 GET 所有 URL
- **PUT 是幂等的**（客户端重试不会出问题）
- **POST 不是幂等的**（重试可能创建多个）

### 4. 分页

**Cursor-based**（推荐，无限滚动 / 实时数据）：
```
GET /orders?cursor=eyJpZCI6MTAwfQ&limit=20
{
  "data": [...],
  "nextCursor": "eyJpZCI6MTIwfQ",
  "hasMore": true
}
```

**Offset-based**（简单后台 / 已知数据量）：
```
GET /orders?page=1&size=20
{
  "data": [...],
  "total": 1000,
  "page": 1,
  "size": 20
}
```

**选哪个**：
- **Cursor**：feed / 时间线 / 大数据量（默认）
- **Offset**：管理后台 / 需要"跳到第 N 页"
- **不混用**：API 一旦选了一种就一直用

### 5. 错误响应（统一 envelope）

**推荐格式**（所有错误用这个 shape）：
```json
{
  "error": {
    "code": "ORDER_NOT_FOUND",
    "message": "Order with id 123 not found",
    "details": { "orderId": 123 },
    "traceId": "abc-123-def-456"
  }
}
```

**字段含义**：
- `code` — 程序可读的稳定错误码（UPPER_SNAKE_CASE）
- `message` — 人类可读（可本地化）
- `details` — 额外上下文（哪个字段错了 / 当前状态等）
- `traceId` — 关联服务端日志（调试必备）

**code 设计**：
- ✅ `USER_NOT_FOUND` / `ORDER_ALREADY_PAID` / `PAYMENT_DECLINED` / `EMAIL_ALREADY_EXISTS`
- ❌ `ERROR_001` / `INVALID_REQUEST` / `-1` / `false`

**HTTP 状态码 vs error.code**：
- HTTP 状态码 = **类别**（4xx/5xx）
- error.code = **具体原因**（ORDER_NOT_FOUND）
- **两个一起用**——客户端先看状态码分流，再看 code 决定 UI

### 6. 鉴权

| 方式 | 场景 | 头 / Cookie |
|------|------|-------------|
| **Bearer Token** | 现代 web / mobile API | `Authorization: Bearer <token>` |
| **Cookie + CSRF** | 浏览器传统应用 | `Cookie: session=...` + `X-CSRF-Token: ...` |
| **API Key** | 服务间 / 第三方开发者 | `X-API-Key: <key>` |
| **OAuth 2.0** | 第三方授权 | Bearer + refresh flow |
| **mTLS** | 高安全服务间 | TLS 证书 |

**关键规则**：
- ✅ token 放 Header（**不 URL**）
- ✅ HTTPS only（**不 HTTP**）
- ✅ 短时 access token（15min - 1h）+ 长时 refresh token（7d - 30d）
- ✅ 不在错误响应中泄露 token（即使是 invalid 也别回显）
- ✅ token 撤销机制（黑名单 / 版本号）

### 7. 限流

**标准 Headers**（每个响应都带）：
```
X-RateLimit-Limit: 100       # 总配额
X-RateLimit-Remaining: 0     # 剩余次数
X-RateLimit-Reset: 1640995200  # 重置时间（unix epoch）
```

**429 响应**：
```http
HTTP/1.1 429 Too Many Requests
Retry-After: 60
Content-Type: application/json

{
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Too many requests, retry after 60s",
    "retryAfter": 60
  }
}
```

**限流维度**（按需组合）：
- IP（防爬虫）
- User ID（防单个用户刷）
- API Key（第三方配额）
- Endpoint（防单接口被刷爆）

### 8. 版本控制

**URL path**（推荐，简单清晰）：
```
/api/v1/users
/api/v2/users
```

**Header**（不推荐，但更"RESTful"）：
```
Accept: application/vnd.myapi.v2+json
```

**实战选择**：URL path——易调试 / 易路由 / 不用客户端改 Accept。

### 9. 文档（OpenAPI）

- **单一 source of truth** — OpenAPI spec
- **自动生成** — client SDK / mock server / 文档站点
- **生态**：
  - Java/Spring: springdoc-openapi
  - TS/Nest: @nestjs/swagger
  - Python/Flask: flask-smorest / FastAPI（原生）
  - Node/Express: swagger-ui-express
- **CI 校验** — 每次 PR 检查 spec 与实现一致

## 常见陷阱

1. **不要在 URL 里放动词** — `/getUsers` ❌ → `GET /users` ✅
2. **不要 POST 里改 GET 行为** — `POST /listUsers` ❌ → `GET /users?filter=...` ✅
3. **不要 200 + 自定义 error code** — `{ "code": 0, "error": "..." }` ❌ → `400 + envelope` ✅
4. **不要 URL 里有 token** — `/users?token=abc` ❌ → `Authorization: Bearer abc` ✅
5. **不要忘了限流** — 尤其公开 API
6. **不要 200 + 错误状态** — 客户端靠状态码判断成功失败
7. **不要 PII 在 URL** — `/users/search?email=xxx` ❌ → `POST /users/search` body ✅
8. **不要混用 snake_case / kebab-case** — 选一种坚持
9. **不要 GET 里改数据** — 即使"很方便"
10. **不要在 5xx 里泄露堆栈** — 给 traceId 让用户报

## 红线

- 不在 API 里暴露内部错误堆栈
- 不在 GET 里改数据
- 不返回 200 表示"操作失败"（用 4xx/5xx）
- 不把 PII 放 URL（URL 会进 log / referer / 浏览器历史）
- 不把 token 放 URL / log / 错误响应
- 不在生产环境返回 500 + debug 信息

## 与其他 skill / agent 联动

- **`database-patterns`** — API 字段映射 DB schema
- **`silent-failure-hunter`** — 4xx 错误也要 log（不吞）
- **`auditor`** — 鉴权 / 限流 / 错误信息泄露 / 越权审查
- **`vibecoding-discipline`** — 5 实践中"接口分离"对应 API contract 稳定性
- **`backend-patterns-*`** — 各语言实现细节（拦截器 / 装饰器 / 中间件）
