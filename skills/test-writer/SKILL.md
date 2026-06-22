---
name: test-writer
description: "测试编写专项 skill。覆盖：边界测试、异常测试、mock 模式、集成测试、E2E。TDD 优先，能先红就先红。触发词：test, tdd, 单测, 集成测试, mock, pytest, junit, vitest"
---

# Test Writer — 测试编写专项

> 单职责：**专门写测试**。TDD 优先、边界覆盖、异常覆盖、mock 模式。**不写业务代码**——业务代码是 coder。

## 触发场景

- 用户说"给这个加测试"
- TDD：先红后绿
- 补覆盖率
- 写集成测试
- 写 E2E（Playwright / Cypress）
- 修 bug 必带复现测试

**不适用**：纯加新功能（业务代码是 coder）。

## 4 原则

1. **Think First**：先想清"测什么、不测什么"——别为覆盖率数字写废测试
2. **Simplicity**：一个测试一个断言（复杂场景拆多个）
3. **Surgical**：只加测试，**不动业务代码**（除非是修 bug 的复现）
4. **Goal-Driven**：每个测试必须有"失败 → 修 → 通过"的可验证流程

## 测试金字塔

```
       /\
      /  \      E2E（少量）
     /────\     - 关键用户旅程
    /      \    
   /────────\   集成测试（适量）
  /          \  - 模块交互、API
 /────────────\ 
/              \ 单元测试（大量）
────────────────  - 函数 / 类 / 边界
```

## TDD 黄金流程（**永远先红后绿**）

```
1. 写失败测试
2. 跑：❌ 红
3. 写最小实现
4. 跑：✅ 绿
5. 重构（保持绿）
6. 跑：✅ 还绿
7. 重复
```

**先写测试**是规则，**例外情况**：
- 接口契约还不确定（先 prototype）
- 第三方库行为不明（先写 usage code）

但**99% 的情况** → 先测试。

## 必须覆盖的测试类型

### 1. 边界测试（**必加**）

| 类型 | 例子 |
|------|------|
| null / None | 字段为 null |
| 空 | 空字符串 / 空 list / 空 dict |
| 极值 | 0、-1、Int.MAX、Long.MAX |
| 边界 | 0/1 之间、999/1000 之间 |
| 非法字符 | emoji、特殊字符、SQL 注入、Unicode 边界 |
| 超大 | 1M 字符串、100K 元素 list |

```python
@pytest.mark.parametrize("input,expected", [
    ("", False),               # 空
    (None, False),             # null
    ("valid@x.com", True),     # 正常
    ("no-at-sign", False),     # 非法
    ("a@b.c", True),           # 最短合法
    ("a" * 1000 + "@x.com", True),  # 超长
])
def test_email_validation(input, expected):
    assert is_valid_email(input) == expected
```

### 2. 异常测试

```python
def test_create_user_rejects_duplicate_email():
    create_user(email="a@b.com")
    with pytest.raises(DuplicateEmailError):
        create_user(email="a@b.com")

def test_divide_by_zero():
    with pytest.raises(ZeroDivisionError):
        divide(10, 0)
```

```ts
test("rejects invalid email", async () => {
  await expect(createUser({ email: "bad" })).rejects.toThrow(ZodError);
});
```

```java
@Test
void createUser_rejectsDuplicateEmail() {
    userService.create(req);
    assertThrows(DuplicateEmailException.class,
        () -> userService.create(req));
}
```

### 3. Mock 模式

**该 mock 的**：
- 外部 HTTP / RPC
- 数据库（用 in-memory 或 test container）
- 时间（`Clock` 接口）
- 随机数
- 文件系统
- 第三方 SDK

**不该 mock 的**：
- 自己写的纯函数
- 值对象（POJO / record / dataclass）

```python
# ✅ Python mock
from unittest.mock import Mock, patch

def test_send_welcome_email_on_signup():
    email_sender = Mock()
    user_service = UserService(email_sender=email_sender, ...)

    user_service.signup("alice@x.com")

    email_sender.send_welcome.assert_called_once_with("alice@x.com")
```

```ts
// ✅ TS vi
import { vi } from "vitest";

test("sends welcome email on signup", async () => {
  const emailSender = vi.fn();
  const userService = new UserService(emailSender);

  await userService.signup("alice@x.com");

  expect(emailSender).toHaveBeenCalledWith("alice@x.com");
});
```

```java
// ✅ JUnit 5 + Mockito
@ExtendWith(MockitoExtension.class)
class UserServiceTest {
    @Mock EmailSender emailSender;
    @InjectMocks UserService userService;

    @Test
    void signup_sendsWelcomeEmail() {
        userService.signup("alice@x.com");
        verify(emailSender).sendWelcome("alice@x.com");
    }
}
```

### 4. 集成测试

```python
# pytest + testcontainers
@pytest.fixture
def postgres():
    with PostgresContainer("postgres:16") as pg:
        yield pg.get_connection_url()

def test_user_repository_save_and_find(postgres):
    repo = UserRepository(postgres)
    user = User(id="1", email="a@b.com")
    repo.save(user)

    found = repo.find_by_id("1")
    assert found.email == "a@b.com"
```

### 5. E2E（Playwright）

```ts
import { test, expect } from "@playwright/test";

test("user can sign up and see dashboard", async ({ page }) => {
  await page.goto("/signup");
  await page.fill('input[name="email"]', "alice@x.com");
  await page.fill('input[name="password"]', "secret123");
  await page.click('button[type="submit"]');

  await expect(page).toHaveURL("/dashboard");
  await expect(page.getByText("Welcome, alice@x.com")).toBeVisible();
});
```

## 结构性测试（**借鉴 ohMeisijiyaCode 经验**）

pytest 可以承担**项目级 linter** 的工作——

```python
# 检查 import 方向（domain 不应该 import infra）
def test_domain_does_not_import_infra():
    for path in Path("src/domain").rglob("*.py"):
        content = path.read_text()
        assert "from src.infra" not in content, \
            f"{path} imports infra — domain must be pure"

# 检查全局可变状态
def test_no_global_mutable_state():
    for path in Path("src").rglob("*.py"):
        for node in ast.parse(path.read_text()).body:
            if isinstance(node, ast.Assign):
                for target in node.targets:
                    if isinstance(target, ast.Name):
                        assert not target.id.isupper() or path.name == "constants.py"
```

```java
// ArchUnit（Java 架构测试）
@ArchTest
static final ArchRule domain_should_not_depend_on_infra =
    noClasses().that().resideInAPackage("..domain..")
        .should().dependOnClassesThat().resideInAPackage("..infra..");
```

## 假绿测试（**严禁**）

### 1. assert True 当测试
```python
# ❌ 假绿
def test_something():
    assert True
```

### 2. 只测 mock
```python
# ❌ 假绿
def test_user_creation():
    mock_db = Mock()
    mock_db.create.return_value = "user_1"
    user_service = UserService(mock_db)
    result = user_service.create_user(req)
    assert result == "user_1"  # 测的是 mock 的行为，不是真业务
```

### 3. 只测 happy path
```python
# ❌ 假绿
def test_divide():
    assert divide(10, 2) == 5  # 测了唯一一行 happy path
```

### 4. 为改测试而改测试
```python
# ❌ 修 bug 时改了测试断言
def test_order_total():
    # 业务说 total 应该是 100，但测试断言改成 99
    assert order.total == 99
```

## 测试组织（项目结构）

```
tests/
├── unit/                    # 单元测试
│   ├── domain/
│   └── services/
├── integration/             # 集成测试
│   ├── api/
│   └── database/
├── e2e/                     # 端到端
│   └── user_journey/
├── structural/              # 架构 / 结构性测试
│   ├── test_imports.py
│   └── test_boundaries.py
└── conftest.py             # 共享 fixture
```

## 覆盖率目标

| 类型 | 目标 |
|------|------|
| 核心业务逻辑 | ≥ 90% |
| service / controller | ≥ 80% |
| utility / helper | ≥ 70% |
| config / boilerplate | 不用测 |
| main / 启动 | 不用测 |

**覆盖率不是目标**——是为了发现漏测的代码。**没有断言的覆盖率** = 0 价值。

## 自检清单（每个测试）

- [ ] 名字描述了**测什么**（不是 test_1）
- [ ] 一个测试一个断言（或一组紧密相关）
- [ ] 跑过红的（先写测试，再写实现）
- [ ] 边界 + 异常 + happy path 都覆盖
- [ ] 没改业务代码（除非是修 bug）
- [ ] 没假绿（assert True / 只测 mock）

## 红线

- **不要**写没断言的测试
- **不要**为覆盖率数字凑数
- **不要**测自己的 mock 行为
- **不要**让测试依赖外部网络（除非 E2E）
- **不要**让测试相互依赖（必须独立运行）
- **不要**改测试断言让 bug 修复"通过"
- **不要**跳过失败的测试

## 跟 mavis 工作流的对接

- **coder** 写完业务代码 → 调 test-writer 补测试
- **verification-loop skill** → 跑测试循环
- **build-error-resolver** → 编译过了但测试红时定向修

---

**怎么算"在工作"**：每个新功能都有"边界 + 异常 + happy path"、覆盖率真实反映价值、修 bug 必带复现测试。
