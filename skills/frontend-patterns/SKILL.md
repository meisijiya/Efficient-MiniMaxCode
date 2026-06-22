# Frontend Patterns

> React 19 / Next.js 15 / modern frontend patterns. The "what every React component should follow" guide.

## 触发场景

- 新建 React 组件
- Next.js 页面 / layout / API route
- 表单设计
- 数据获取（client / server）
- 状态管理（local / global / server）
- 性能优化
- 可访问性（a11y）审查
- 任何前端 agent / skill 涉及 UI

## 核心知识

### 1. React 19 新特性（**必知**）

| 特性 | 用途 | 替代什么 |
|------|------|----------|
| **Actions** | 表单 / 异步操作原生支持 | onSubmit + fetch + useState |
| **useFormStatus** | 跟踪表单 pending 状态 | 手动 setLoading |
| **useActionState** | 管理 action 状态 + 错误 | useState + try/catch |
| **useOptimistic** | 乐观更新 | 先 setState 再 await |
| **use** Hook | 读 Promise / Context | useContext + useEffect 模式 |
| **ref as prop** | 不再需要 forwardRef | forwardRef 包裹 |

**示例**（useActionState）：
```tsx
async function createUser(prevState: any, formData: FormData) {
  'use server';
  const result = await db.users.create(formData);
  if (!result.ok) return { error: result.error };
  revalidatePath('/users');
  return { success: true };
}

function CreateUserForm() {
  const [state, action, pending] = useActionState(createUser, { error: null });
  return <form action={action}>...</form>;
}
```

### 2. Next.js 15 App Router（**默认架构**）

- **Server Components** 默认（**更少 JS 传到客户端**）
- **Client Components** 用 `'use client'` 显式标记
- **Server Actions** 用 `'use server'` + form action
- **Layouts** vs **Pages** vs **Templates**
- **Parallel Routes** / **Intercepting Routes**（高级模式）
- **Streaming** with `loading.tsx` / `<Suspense>`

**默认决策树**：
```
默认 Server Component
    ↓
需要 onClick / onChange / useState / useEffect？
    ↓ 是
加 'use client'
    ↓
需要调外部 API / 数据库？
    ↓ 是
用 Server Action（'use server'）而不是 useEffect + fetch
```

### 3. 状态管理（**按场景选**）

| 场景 | 推荐 | **不推荐** |
|------|------|------------|
| **本地 UI 状态** | useState / useReducer | Redux / Zustand |
| **跨组件共享（少量）** | Context | - |
| **复杂跨页状态** | Zustand / Jotai | Redux（除非团队习惯） |
| **服务器状态** | **TanStack Query** / SWR | **绝不用 Redux 管** |
| **表单状态** | React Hook Form | useState 一堆字段 |
| **URL 状态**（filter / sort / page） | nuqs / useSearchParams | 全局 state |
| **主题 / 国际化** | next-themes / next-intl | 自己写 Context |

**核心规则**：
- 能用 React 内置 + Context 解决 → **不上 Zustand**
- 能用 TanStack Query 管服务器状态 → **不复制到 Redux**
- URL 该有的状态（filter / sort）→ **放 URL**，不存 localStorage

### 4. 数据获取

**Server Component**（**首选**）：
```tsx
async function UserList() {
  const users = await db.users.findMany();
  return <List users={users} />;
}
```

**Client Component + TanStack Query**（需要交互时）：
```tsx
'use client';
function UserList() {
  const { data, isLoading, error } = useQuery({
    queryKey: ['users'],
    queryFn: () => fetch('/api/users').then(r => r.json()),
  });
  if (isLoading) return <Skeleton />;
  if (error) return <Error error={error} />;
  return <List users={data} />;
}
```

**Server Action 触发 mutation**（Next 15）：
```tsx
async function deleteUser(id: string) {
  'use server';
  await db.users.delete(id);
  revalidatePath('/users');
}
```

### 5. 表单（**React Hook Form + Zod** 是默认栈）

```tsx
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';

const schema = z.object({
  name: z.string().min(1, 'Name required'),
  email: z.string().email('Invalid email'),
  age: z.number().int().positive().optional(),
});

type FormData = z.infer<typeof schema>;

function UserForm() {
  const { register, handleSubmit, formState: { errors } } = useForm<FormData>({
    resolver: zodResolver(schema),
  });
  const onSubmit = handleSubmit(async (data) => {
    await fetch('/api/users', { method: 'POST', body: JSON.stringify(data) });
  });
  return (
    <form onSubmit={onSubmit}>
      <input {...register('name')} />
      {errors.name && <span>{errors.name.message}</span>}
      ...
    </form>
  );
}
```

**Zod 的好处**：
- 一份 schema → TS 类型 + 运行时校验
- Server Action / API 都能复用

### 6. 样式

| 方案 | 场景 | **推荐度** |
|------|------|------------|
| **Tailwind CSS 4** | 99% 项目 | ⭐⭐⭐⭐⭐ |
| **CSS Modules** | 组件作用域 + 复杂样式 | ⭐⭐⭐ |
| **CSS-in-JS** (styled-components) | 旧项目维护 | ⭐⭐ |
| **vanilla-extract** | 强类型 CSS | ⭐⭐⭐（TS 强约束项目） |
| **inline style** | 简单动态值 | ⭐（仅动态值） |

**默认选 Tailwind 4**——零运行时、utility-first、IDE 提示完整。

### 7. 测试（**必备**）

- **单元 / 组件** — **Vitest** + **React Testing Library**
- **E2E** — **Playwright**（推荐）/ Cypress
- **Visual regression** — Chromatic / Percy（UI 装饰严格时）
- **覆盖率目标** — 关键组件 ≥ 80%，纯展示组件可低（30%+）

**不写测试的反模式**：
- ❌ 跳过测试因为"UI 测试太麻烦"
- ❌ 只测 happy path
- ❌ 用 `data-testid` 满地（应该用 semantic selector）
- ❌ snapshot test 一切（变化太大，维护成本高）

### 8. 性能（**先 profile 后优化**）

| 措施 | 适用 | 注意 |
|------|------|------|
| **`next/image`** | 所有图片 | **必用**——自动优化 + lazy |
| **`next/font`** | 字体 | 自动 subset + preload |
| **`React.memo`** | 重组件 + 同样 props | **别 over-use**——先 profile |
| **`useMemo` / `useCallback`** | 重计算 / 引用稳定性 | **别 over-use**——同 memo |
| **`dynamic()`** | 大组件 / 不常访问 | code splitting |
| **`<Suspense>`** | 异步数据 | streaming + 渐进渲染 |
| **Server Components** | 默认 | 减少客户端 JS |

**Web Vitals 监控**：
- **LCP**（Largest Contentful Paint）< 2.5s
- **INP**（Interaction to Next Paint）< 200ms
- **CLS**（Cumulative Layout Shift）< 0.1

### 9. 可访问性（**WCAG 2.2 AA**）

- **语义化 HTML** — `<button>` 不是 `<div onClick>` / `<nav>` 不是 `<div class="nav">` / `<main>` / `<article>`
- **ARIA** — 仅在 HTML 语义不够时（如 `aria-expanded` / `aria-live`）
- **键盘导航** — 所有交互元素 Tab 可达 / Enter 可触发
- **焦点管理** — 模态打开时焦点入模态、关闭时还原
- **颜色对比度** — 文本 4.5:1，大文本 3:1
- **alt 属性** — 图片必须有（装饰图用 `alt=""`）
- **表单 label** — 每个 input 有对应的 `<label>`

## 常见陷阱

1. **不要 `'use client'` 全标** — 默认 Server Component，按需升级
2. **不要 useEffect 拉数据** — Server Component 或 TanStack Query
3. **不要 Redux 管服务器状态** — 用 TanStack Query
4. **不要 over-memo** — `React.memo` 不是免费的（先 profile 再 memo）
5. **不要 `<div onClick>`** — 用 `<button>`（键盘可访问性 + 语义）
6. **不要硬编码颜色** — 用 Tailwind class / CSS 变量
7. **不要 inline function 在大列表** — `useCallback`（但**别 over-use**）
8. **不要 snapshot 一切** — 只 snapshot 关键 UI
9. **不要用 `dangerouslySetInnerHTML` 除非真有必要** — XSS 风险
10. **不要忘了 loading / error state** — 用户得知道发生了什么

## 红线

- **不在 client component 放敏感数据**（API key / secret / token）—— 客户端代码所有人都能看
- **不在 server action 漏掉 auth check**——每个 action 必须 verify user
- **不跳过 ESLint + TypeScript strict**——这两个是基础保障
- **不依赖未类型化的 third-party**——优先选 `@types/*` 完备的库
- **不忽略 a11y**——WCAG AA 是底线

## 与其他 skill / agent 联动

- **`api-design`** — 前端调什么 API 决定 fetch 怎么写
- **`test-writer`** — 组件测试策略 / E2E 流程
- **`verifier`** — a11y / 性能 / 错误处理审查
- **`silent-failure-hunter`** — client error boundary / 异步错误吞错
- **`backend-patterns-*`** — 前后端类型契约共享
- **`vibecoding-discipline`** — 5 实践中的"纯函数优先"对应 React pure component
