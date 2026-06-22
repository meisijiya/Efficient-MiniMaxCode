---
name: backend-patterns-typescript
description: "TypeScript / Node 后端核心模式（Express / Fastify / NestJS / 异步 IO / 类型设计）。触发词：typescript, ts, node, express, nest, fastify, 后端, ts 类型, async"
---

# TypeScript / Node 后端核心模式

> 适用：TypeScript / Node 后端开发。聚焦实战高频模式。

## 4 原则提醒（落地版）

- **Think First**：先想清"同步 vs 异步"、"CPU vs IO 密集"、用 `Worker` 还是主线程
- **Simplicity**：类型别 over-engineer；Promise 链别套 5 层
- **Surgical**：改类型别"顺手"改格式；改 import 别动业务
- **Goal-Driven**：先写失败测试

---

## 1. strict 模式（**必开**）

```json
// tsconfig.json
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitOverride": true,
    "exactOptionalPropertyTypes": true,
    "noFallthroughCasesInSwitch": true
  }
}
```

### 红线
- ❌ `any` 偷懒
- ❌ `// @ts-ignore` / `@ts-expect-error` 偷懒（除非确认是工具误报）
- ❌ `as unknown as T` 双重 cast
- ❌ `!` 非空断言滥用

---

## 2. Promise / async-await

```typescript
// ✅ 正确
async function fetchUser(id: string): Promise<User> {
  const res = await fetch(`/api/users/${id}`);
  if (!res.ok) throw new ApiError(res.status, "Failed to fetch user");
  return res.json() as Promise<User>;
}

// ❌ 反模式
function fetchUser(id: string): Promise<User> {
  return fetch(`/api/users/${id}`).then(r => r.json());  // 没检查状态
}

// ❌ Promise 链断链
async function handler() {
  backgroundTask().catch(console.error);  // fire-and-forget 但忘了 log 什么
}
```

### 规则
- **永远 await 或显式 `.catch()`**——不要留 dangling promise
- **永远检查 `res.ok`**——4xx/5xx 不会 reject fetch
- **并行独立 IO** → `Promise.all`，别 `await` 串行
- **有限并行** → `Promise.allSettled` 或 p-limit

### 错误处理
```typescript
// ✅ 显式错误类型
class ApiError extends Error {
  constructor(public status: number, message: string) {
    super(message);
    this.name = "ApiError";
  }
}

// ❌ 静默吞错
try { await risky() } catch (e) { /* TODO */ }

// ❌ 吞错返 null
async function getUser(id: string): Promise<User | null> {
  try { return await fetchUser(id); }
  catch { return null; }  // 调用方分不清"没找到"还是"出错"
}
```

---

## 3. Zod 边界校验

```typescript
import { z } from "zod";

const CreateUserSchema = z.object({
  email: z.string().email(),
  age: z.number().int().min(0).max(150),
  tags: z.array(z.string()).max(10).default([]),
});

type CreateUserInput = z.infer<typeof CreateUserSchema>;

export function createUser(input: unknown): User {
  const data = CreateUserSchema.parse(input);  // 失败抛 ZodError
  return db.users.create(data);
}
```

### 模式
- **API 入参** → Zod schema 校验
- **环境变量** → Zod 校验（用 `z.object` + `process.env`）
- **第三方响应** → parse 后再用，不要直接 `as T`

---

## 4. 不可变性

```typescript
// ✅ 不可变更新
const updated = { ...user, name: "新名字" };
const newList = [...list, newItem];

// ✅ 真冻结
const config = Object.freeze({ timeout: 5000 });

// ❌ 变异
user.name = "新名字";
list.push(newItem);
```

### 何时用
- **状态对象** → 不可变更新
- **配置** → `as const` 或 `Object.freeze`
- **集合** → 优先 `ReadonlyArray<T>` / `ReadonlyMap<K, V>`

---

## 5. 类型设计

### Discriminated Union（**首选**）
```typescript
// ✅ 状态用 union
type AsyncState<T> =
  | { status: "idle" }
  | { status: "loading" }
  | { status: "success"; data: T }
  | { status: "error"; error: Error };

// ❌ 用 boolean / 多个字段
type BadState = { loading: boolean; data?: T; error?: Error };
```

### Brand Type（防 ID 混用）
```typescript
type UserId = string & { readonly __brand: "UserId" };
type OrderId = string & { readonly __brand: "OrderId" };

function getUser(id: UserId) { ... }
getUser("u_1" as UserId);
getUser(orderId);  // ❌ 类型错误
```

### Result 类型（**慎用**——只在你确定要）
```typescript
type Result<T, E = Error> = { ok: true; value: T } | { ok: false; error: E };

// 用 throw 还是 Result 是风格选择——团队统一
// 不要一半代码用 throw，一半用 Result
```

---

## 6. Express / Fastify 模式

### 中间件
```typescript
// ✅ 显式 async + next
app.use(async (req, res, next) => {
  try {
    await someAsyncOp();
    next();
  } catch (e) {
    next(e);  // Express 会传给 error handler
  }
});

// ❌ async + 没 try/catch
app.use(async (req, res, next) => {
  await someAsyncOp();  // 抛了 Express 5 才自动 catch
  next();
});
```

### Error handler（**必须有**）
```typescript
app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
  if (err instanceof ZodError) {
    return res.status(400).json({ error: "validation", details: err.issues });
  }
  if (err instanceof ApiError) {
    return res.status(err.status).json({ error: err.message });
  }
  console.error("unhandled", err);
  res.status(500).json({ error: "internal" });
});
```

---

## 7. 依赖注入

```typescript
// ✅ 接口 + 构造器注入
interface UserRepo {
  findById(id: string): Promise<User | null>;
}

class UserService {
  constructor(private readonly repo: UserRepo) {}

  async getUser(id: string): Promise<User> {
    const user = await this.repo.findById(id);
    if (!user) throw new NotFoundError(`user ${id} not found`);
    return user;
  }
}

// 测试时 mock
const mockRepo: UserRepo = { findById: async () => testUser };
const service = new UserService(mockRepo);
```

---

## 8. 性能 / 内存

- **流式处理大文件** → `stream.pipeline` 别 `readFile`
- **避免 JSON.parse 大字符串** → 用 `JSONStream` 或分批
- **缓存** → LRU（quick-lru），别自己写
- **限流** → `p-limit` / `p-queue`，别自己实现 semaphore
- **Event loop 阻塞** → CPU 密集用 `worker_threads`

---

## 9. 测试（vitest / jest）

```typescript
import { describe, it, expect, vi } from "vitest";

describe("createUser", () => {
  it("rejects invalid email", async () => {
    await expect(createUser({ email: "bad", age: 20 })).rejects.toThrow(ZodError);
  });

  it("creates user with valid input", async () => {
    const user = await createUser({ email: "a@b.com", age: 20 });
    expect(user.id).toBeDefined();
  });
});
```

### Mock 模式
```typescript
import { vi } from "vitest";
const fetchMock = vi.spyOn(global, "fetch").mockResolvedValue(
  new Response(JSON.stringify({ id: "1" }), { status: 200 })
);
```

---

## 10. 项目结构（推荐）

```
src/
├── api/                 # 路由 / controller
│   ├── users/
│   │   ├── routes.ts
│   │   └── schema.ts    # Zod
├── core/                # 基础设施
│   ├── config.ts        # env 校验
│   ├── errors.ts
│   └── logger.ts
├── domain/              # 业务模型
├── infra/               # DB / 缓存 / 第三方
├── services/            # 编排
└── main.ts
```

---

## 高频反模式（自查清单）

- [ ] strict 模式开了（不要 any）
- [ ] async 函数有 await 或显式 catch
- [ ] fetch 检查了 `res.ok`
- [ ] Zod 校验边界
- [ ] 没把异常吞成 null
- [ ] 状态用 discriminated union
- [ ] 错误有统一 handler
- [ ] 并行 IO 用 `Promise.all`
- [ ] 依赖用接口注入
- [ ] 测试覆盖边界 + 异常
