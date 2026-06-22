---
name: vibecoding-discipline
description: "Vibe Coding 防屎山 5 实践——AI 写代码越快，工程边界越不能糊。架构先于实现、5 条解耦实践、克制自己。触发词：vibecoding, 屎山, 耦合, 解耦, 架构, 模块化"
---

# Vibe Coding Discipline — 防屎山 5 实践

> 源自 Vibe Coding 视频核心 + [YYHDBL 的迁移复盘](https://github.com/YYHDBL/nlp-agent-notes/blob/main/notes/agents/from-vibe-coding-to-harness-engineering.md)。
> **核心信念**：**AI 写代码越快，工程边界越不能糊。**

## 为什么会有"屎山"

> **复杂度不是跟代码量正比增长，是平方级增长。**
> 代码量翻倍，复杂度可能翻 4 倍。
> 人的理解和开发能力是**线性**的，迟早追不上屎山膨胀。

**比喻**：一个直径 10 的圆面积 314；切成 5 个直径 5 的圆面积总和 392。看似拆小反而大，但**维护成本不在面积，在耦合**——一坨大圆的"边界数量"远小于拆开后的总边界，但拆开后**每段独立可控**。

**解耦的本质**：把大屎山拆成多个小屎山，每段复杂度上限在人的线性能力范围内。

---

## 5 条解耦实践（**Build 阶段必查**）

### 1. 依赖接口而不是实现

```java
// ❌ 依赖具体类
@Service
public class OrderService {
    @Autowired
    private MySqlOrderRepository repo;  // 绑死 MySQL
}

// ✅ 依赖接口
public interface OrderRepository { ... }  // domain 层定义接口

@Service
public class OrderService {
    private final OrderRepository repo;  // 注入接口
}

// infrastructure 层实现
@Repository
public class MySqlOrderRepository implements OrderRepository { ... }
```

```ts
// ❌ 直接 import 具体实现
import { MysqlUserRepo } from "./mysql-user-repo";
const userRepo = new MysqlUserRepo();

// ✅ 依赖注入接口
interface UserRepo { findById(id: string): Promise<User | null>; }
class UserService {
  constructor(private readonly repo: UserRepo) {}
}
```

**测试时** → mock 接口，**0 数据库**。

### 2. 一个模块只干一件事

```java
// ❌ 啥都管
@Service
public class UserService {
    public User create(...) { ... }
    public void sendWelcomeEmail(...) { ... }     // 邮件是另一件事
    public void generateReport(...) { ... }        // 报表是另一件事
    public void validatePassword(...) { ... }     // 密码是另一件事
}

// ✅ 拆分
@Service
public class UserService {              // 只管用户 CRUD
    public User create(...) { ... }
    public User findById(...) { ... }
}

@Service
public class EmailService {             // 只管邮件
    public void sendWelcomeEmail(User u) { ... }
}
```

**判断标准**：这个类的职责能用**一句话**说清吗？说不清就拆。

### 3. 少用继承、多用组合

```java
// ❌ 继承层级
public class Animal { ... }
public class Dog extends Animal { ... }
public class ServiceDog extends Dog { ... }     // 2 层
public class BlindServiceDog extends ServiceDog { ... }  // ❌ 3 层

// ✅ 组合 + 接口
public interface GuideCapable { void guide(); }
public class ServiceDog extends Dog implements GuideCapable {
    private final Training training;  // 组合
    public void guide() { training.execute(); }
}
```

**规则**：继承层级 ≤ 2 层。**永远问"能不能用组合"**。

### 4. 一点点增加功能，每步测试完再继续

```
// ❌ 大爆炸 commit
git commit -m "feat: 实现用户系统（含 CRUD、邮件、报表、权限、SSO）"
→ 5000 行 diff，3 天写，1 周 review

// ✅ 阶段化交付
git commit -m "feat: User entity + repository"      // Phase 1
git commit -m "feat: User CRUD API"                  // Phase 2
git commit -m "feat: 邮件通知（接 UserCreated 事件）"  // Phase 3
→ 每个 commit 独立可测、独立 merge
```

**规则**：每写完一个 Phase → 跑通测试 → commit → 才写下一个。

### 5. 小心全局状态，多写纯函数

```java
// ❌ 全局状态
public class Config {
    public static String API_KEY;  // 全局可变
}

// ❌ 隐式依赖
@Service
public class ReportService {
    public Report generate() {
        return callApi(Config.API_KEY);  // 读全局
    }
}

// ✅ 配置注入
@Service
public class ReportService {
    private final String apiKey;  // 构造器注入
    public ReportService(@Value("${api.key}") String apiKey) {
        this.apiKey = apiKey;
    }
}

// ✅ 纯函数
public class PriceCalculator {
    public Money calculate(Order order, Discount discount) {  // 输入决定输出
        return order.total().subtract(discount.amount());
    }
}
```

**规则**：
- `static` 可变字段 → 几乎全错
- 单例 / 全局变量 → 默认改成依赖注入
- 函数没输入但返回不同结果 → 改为接收参数

---

## Vibe Coding 陷阱（**AI 写代码特有**）

### 1. AI 不做架构设计
- AI 看到的更多是"附近代码"，不是"全局结构"
- 仓库里如果有 5 个服务都读全局 state，AI 会接着写第 6 个
- **架构必须人定**——AI 只钻进模块内部实现

### 2. 协议和状态容易乱
- "业务 agent 为了快，直接拼前端 payload"
- "为了拿字段，直接读 shared_data"
- **修法**：立接口合同（`AgentResult` / `ResponseRoute` / `FrontendMessage`），不让 transport 字段混进 facts

### 3. 测试假绿
- AI 写 `assert True` 当测试 → 后面的 agent 当成可信信号
- **修法**：测试必须是行为测试，不是"过就完事"
- 加**结构性检查测试**（import 方向、状态访问边界、协议字段合同）

### 4. 文档"过程材料"堆成噪音
- 迁移早期会留计划、对比、日志、归档
- 新会话 agent 不知道"哪份是当前规则"
- **修法**：稳定材料进 docs/，过程材料进 archive/

---

## 微服务陷阱（**别拆太碎**）

模块之间需要接口通信，**接口本身有维护成本**。拆太碎会掉进"微服务地狱"——

```
服务 A 调服务 B
  B 调 C
    C 调 D
      D 抛错
        → A 的请求超时
          → 排查链路要跨 4 个服务
            → 1 周过去了
```

**规则**：
- **先单体 + 模块化**（按 package / module 拆）
- **真的需要独立部署 / 独立伸缩**才拆服务
- **架构师的核心能力**：找"总复杂度最小"的平衡点

---

## 实用检查清单（**Build 阶段过一遍**）

每次写完一个模块，**自检 5 问**：

- [ ] 我注入了接口还是具体类？
- [ ] 这个类的职责能用一句话说清吗？
- [ ] 继承层级 ≤ 2 层？
- [ ] 这个 commit 是独立可 merge 的吗？
- [ ] 有没有 static / 全局变量 / 隐式依赖？

**任一为否** → 重构再交付。

---

## 跟 mavis 工作流的对接

- **planner** → Plan 阶段显式确定模块边界 + 接口契约
- **coder** → Build 阶段严格按 plan，**不重新做架构决策**
- **verifier** → Review 阶段对照 5 条实践审查
- **code-simplifier** → 砍违反 5 条实践的代码
- **meta-writer** → 把"我们今天决定 X 架构"写进 ADR

---

## 红线

- **不要**让 AI 决定模块边界——人定
- **不要**让 AI 在已有屎山上"加一层封装"——拆掉重做
- **不要**"大爆炸 commit"——分阶段
- **不要**用 static / 全局变量偷懒
- **不要**写"为了未来扩展"的接口——**真需要时再加**

---

**怎么算"在工作"**：每个模块的职责用一句话能说清、每个 commit 独立可 merge、每次 review 不需要"打回重做"。
