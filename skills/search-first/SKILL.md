# Search First — 编码前先搜

> Karpathy 原则 1 落地 + 吸收 addy 的 `source-driven-development`：**搜了才写，引用源，标 unverified**。

## 触发场景

- 写新代码（**任何**语言 / 框架 / 库）
- 用不熟的 API / 框架特性
- 选技术方案（哪个 DB / 哪个 lib / 哪个 SDK）
- 改 deprecated 的代码（要先确认新 API）
- 任何"凭记忆"写代码之前

**不适用**：
- 写非常熟的标准代码（`for` 循环、`if` 判断）—— 不用查
- 改自己 1 小时前写的代码 —— 不用查

## 核心纪律（**MUST**）

### 1. 必须搜 — 写代码前先查

**触发条件**（任一满足就要搜）：
- 用了**不熟**的 API / 类 / 函数
- 用了**新版本**的特性（v18 → v20 / Spring Boot 2 → 3）
- 用了**第三方库**（不是 JDK / stdlib / 公认标准）
- 选**哪个库 / 哪个方案**（comparison 类）

**搜的优先级**：
1. **官方文档**（必看）— `docs.spring.io` / `nextjs.org/docs` / `fastapi.tiangolo.com`
2. **官方 examples / cookbook**（必看）
3. **官方 changelog / release notes**（如果用新版本）
4. **权威博客**（可选）— 公司技术博客 / 知名个人博客

**禁止**：
- ❌ 凭记忆写不熟的 API（"我记得是这样"——通常错）
- ❌ 只看 StackOverflow（SO 有时不更新到新版本）
- ❌ 看 5 年前的博客（API 可能变了）
- ❌ 跳过官方文档直接看第三方教程

### 2. 必须引用源 — 标 URL

**每段**用了搜过的知识 → **必须**在代码注释或 commit message 引用源：

```java
// 用 Spring Boot 3.2 record 模式（[Spring Docs](https://docs.spring.io/spring-boot/docs/3.2.x/reference/htmlsingle/)）
public record OrderRequest(@NotBlank String customerId, ...) {}
```

```ts
// 用 Next.js 15 Server Action（[Next.js Docs](https://nextjs.org/docs/app/building-your-application/data-fetching/server-actions-and-mutations)）
async function createOrder(formData: FormData) {
  'use server';
  ...
}
```

**为什么**：
- reviewer 能验证
- 6 个月后你自己能找回源
- 防止"AI 凭记忆编 API"（编的 API 看起来对实际编译不过）

### 3. 必须标 unverified — 找不到源时

**搜不到官方源** → 必须在代码处**显式标 unverified**：

```python
# UNVERIFIED: FastAPI 中间件用法基于 2024 训练数据，未对照官方文档
@app.middleware("http")
async def add_trace_id(request, call_next):
    ...
```

**或者**在 commit message 里：

```
feat: add trace ID middleware

UNVERIFIED: FastAPI middleware pattern based on training data,
not verified against current FastAPI docs. May need adjustment.
```

**为什么**：
- 让 reviewer 知道"这块不可信，要重点 review"
- 防止"AI 编的代码当 verified 写进生产"

### 4. 必须标 framework assumption — 框架 / 版本变了

**写"这个 API 在 X 版本是这样"** → 标版本 + 日期：

```ts
// Spring Boot 3.2 (verified 2024-01) — Spring Boot 4 may differ
```

**为什么**：
- 升级到新版本时这些 assumption 可能失效
- 防止"今年能用明年挂"

## 工作流（3 步）

### Step 1: 识别要不要搜

写代码前 5 秒问自己：
- "这个 API 我熟吗？" 不熟 → 搜
- "这个版本我用过吗？" 没用过 → 搜
- "这是不是第三方库？" 是 → 搜

**不确定就搜**——搜比错便宜 100 倍。

### Step 2: 搜 + 记

搜（官方文档优先）→ **记下**：
- **API 怎么用**（签名 / 参数 / 返回值）
- **URL**（用于引用）
- **版本 + 日期**（用于标 assumption）

### Step 3: 写代码 + 标源

写代码 → **在代码注释 / commit message 标**：
- ✅ Verified：URL + 日期
- ⚠️ Unverified：理由 + 待 review 标记
- 📅 Version assumption：版本 + 日期

## 完整工作流示例

```
任务：给 Spring Boot 项目加 OpenAPI 文档

Step 1: 识别要不要搜
  - 用 springdoc-openapi 库 → 第三方库 → 必搜
  - Spring Boot 3.2 → 之前用过 1.x 版本 → 必搜
  
Step 2: 搜 + 记
  - 官方：https://springdoc.org/ （openapi 集成）
  - 官方：https://docs.spring.io/spring-boot/docs/3.2.x/ （Boot 3 集成方式）
  - 记：springdoc-openapi v2.x 集成方式 / 2024-01 verified

Step 3: 写代码 + 标源
  // OpenAPI 3.0 集成（[springdoc v2.x](https://springdoc.org/) 适配 Spring Boot 3.2, verified 2024-01）
  <dependency>
      <groupId>org.springdoc</groupId>
      <artifactId>springdoc-openapi-starter-webmvc-ui</artifactId>
      <version>2.5.0</version>
  </dependency>
```

## 常见反模式

| 反模式 | 修正 |
|--------|------|
| "我记得是这样" | 凭记忆 80% 错。搜。 |
| "StackOverflow 第一个答案就是对的" | SO 经常过时。交叉验证官方文档。 |
| "5 年前看的文章，应该没变" | API 经常变。搜。 |
| "这是标准用法不用查" | 标准用法也有 deprecated。查。 |
| "AI 写的肯定对" | AI 经常编。**必须**搜 + 引用。 |
| "时间紧先写，回头再查" | 回头不会查。写时一起查。 |

## Anti-rationalization（**绝不跳搜的借口**）

| 借口 | 反驳 |
|------|------|
| "我已经写过 100 次了" | 100 次前 API 可能已经 deprecated |
| "团队都用这个写法" | 团队可能都是错的，传承错误 |
| "文档太烂找不到" | 至少找到 1 个官方/权威源；标 unverified |
| "AI 训练数据足够新" | AI 也经常错，必须搜验证 |
| "任务太紧急" | 紧急 → 错更快。搜 5 分钟救 1 小时 |
| "reviewer 会发现" | reviewer 看不到你"凭记忆"写的，会过 |

## 跟其他 skill 的关系

- **`grill-me`**：先 grill 用户（搞清需求）→ 再 search-first（搞清技术）
- **`coder` agent**：**写代码前必 load 这个 skill**
- **`vibecoding-discipline`**：5 实践 + 这个 = 写对且不啰嗦
- **`verification-loop`**：写完要 verify 实际能跑（不只是搜过）

## 红线

- ❌ 凭记忆写第三方库代码
- ❌ 不用官方文档（只用 SO / 博客）
- ❌ 找不到源还假装 verified
- ❌ 不标版本 assumption（升级时翻车）
- ❌ 标完源不 commit 到 message（"看不见"等于没标）

## 与 addy `source-driven-development` 对照

| addy 提的 | 我们做的 |
|----------|---------|
| Ground every framework decision in official docs | ✅ Step 1 + Step 2 |
| Verify | ✅ Step 2 搜 |
| Cite sources | ✅ 必须引用 URL |
| Flag what's unverified | ✅ 必须标 UNVERIFIED |
| Version + date | ✅ 标 Spring Boot 3.2 / 2024-01 |

**吸收度：100%**，加上 karpathy 原则 1 落地。

---

**怎么算"在工作"**：每个用第三方库的代码都有 `verified URL` 或 `UNVERIFIED 标记`、6 个月后还能找到源、verifier 不需要问"这 API 哪来的"。
