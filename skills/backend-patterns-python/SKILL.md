---
name: backend-patterns-python
description: "Python 后端核心模式（FastAPI / Django / 数据处理 / 异步）。触发词：python, fastapi, django, async, pydantic, sqlalchemy, 后端, 异步"
---

# Python 后端核心模式

> 适用：Python 后端开发。聚焦实战高频模式，不涉及冷门内容。

## 4 原则提醒（落地版）

- **Think First**：写之前先明确"这是 sync 还是 async"、"是 IO 密集还是 CPU 密集"
- **Simplicity**：能用标准库就别引第三方；能用 list comprehension 就别 map/filter
- **Surgical**：改 import 别"顺手"改格式；删 unused 别"顺手"重命名
- **Goal-Driven**：写新功能先写 pytest 失败测试

---

## 1. 异步 vs 同步（**选错会卡死**）

### 决策表

| 场景 | 选 | 原因 |
|------|-----|------|
| FastAPI 路由处理 | **async** | 高并发 IO |
| FastAPI 同步操作（CPU bound） | **def**（非 async def） | 避免阻塞 event loop |
| Django 视图（Django 4.1+） | **async** 可选 | 看视图是否 IO bound |
| Django ORM 调用 | **同步上下文** | Django ORM 不支持 async |
| 数据处理 ETL | **def + 多进程** | CPU 密集 |
| 第三方库（无 async 版本） | **def + run_in_executor** | 不要强行 await |

### 红线
```python
# ❌ 在 async 里调同步阻塞
async def handler():
    time.sleep(10)        # 阻塞整个 event loop
    requests.get(url)     # 同步 IO，阻塞

# ✅ 正确
async def handler():
    await asyncio.sleep(10)
    async with httpx.AsyncClient() as c:
        await c.get(url)
```

```python
# ❌ 同步里调 async
def sync_handler():
    return asyncio.run(coro())  # 在已有 event loop 里会报错

# ✅ 移到异步入口，或用 run_in_executor
```

---

## 2. 类型注解（**必加**）

```python
from __future__ import annotations
from typing import Optional

def get_user(user_id: int, *, include_posts: bool = False) -> Optional[User]:
    ...
```

### 红线
- ❌ `def foo(x):` 不加类型
- ❌ `Optional[int]` 当字段类型用（应用 `int | None`）
- ❌ 过度用 `Any`
- ❌ `# type: ignore` 偷懒（除非确认是工具误报）

---

## 3. Pydantic 边界校验

```python
from pydantic import BaseModel, Field

class CreateUserRequest(BaseModel):
    email: str = Field(..., pattern=r"^[\w.+-]+@[\w-]+\.[\w.-]+$")
    age: int = Field(..., ge=0, le=150)
    tags: list[str] = Field(default_factory=list, max_length=10)

# ✅ 边界用 Pydantic，业务用 dataclass / typed dict
```

### 模式
- **API 入参** → Pydantic `BaseModel`
- **业务数据** → `dataclass(frozen=True)` 或 `TypedDict`
- **配置** → Pydantic `BaseSettings`（从 env 读）

---

## 4. 错误处理

### 显式优于聪明
```python
# ❌ 静默吞错
try:
    critical()
except Exception:
    pass

# ❌ 只 log 不 raise
try:
    critical()
except Exception as e:
    logger.error(e)

# ✅ 显式
try:
    result = critical()
except SpecificError as e:
    raise ServiceError("failed to do X") from e
```

### 何时用什么
- **业务错误** → 自定义异常类（`class UserNotFoundError(Exception): ...`）
- **第三方错误** → 包成你的异常（不要让 `boto3` 的 `BotoCoreError` 透到 controller）
- **不要**用 `(success, error) = operation()` 返回码模式（这是 Java 习惯）
- **不要**用 `Optional[T]` 表示错误（None 意味着"无值"不是"出错"）

---

## 5. 不可变性

```python
from dataclasses import dataclass

@dataclass(frozen=True)
class Point:
    x: int
    y: int

p = Point(1, 2)
p.x = 3  # FrozenInstanceError ✅
```

### 何时用
- **领域模型** → `frozen=True` dataclass
- **配置** → `frozen=True`
- **dict / list** → 用 `MappingProxyType` 或 `tuple/frozenset`

---

## 6. 路径与 IO

```python
from pathlib import Path

# ✅ 永远用 pathlib
config_path = Path(__file__).parent / "config.yaml"
content = config_path.read_text(encoding="utf-8")

# ❌ 不用 os.path（除非老代码）
```

### 编码
- **永远显式指定 encoding="utf-8"**（不要依赖平台默认）
- 读文件用 `read_text(encoding="utf-8")`
- 写文件用 `write_text(encoding="utf-8")`

---

## 7. 测试（pytest）

```python
import pytest

def test_user_validation_rejects_bad_email():
    with pytest.raises(ValidationError):
        CreateUserRequest(email="not-an-email", age=20)

@pytest.mark.asyncio
async def test_async_handler():
    result = await handler()
    assert result.status == "ok"
```

### 必加
- **边界测试**：None、空、极大、极小、非法字符
- **异常测试**：`pytest.raises`
- **异步测试**：`@pytest.mark.asyncio` + `pytest-asyncio` 插件

### fixture 模式
```python
@pytest.fixture
def db_session():
    session = Session()
    yield session
    session.rollback()  # 每个测试独立回滚
    session.close()
```

---

## 8. 依赖注入（FastAPI）

```python
from fastapi import Depends

def get_db() -> Generator[Session, None, None]:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.get("/users/{user_id}")
def get_user(user_id: int, db: Session = Depends(get_db)):
    return db.query(User).get(user_id)
```

### 规则
- **永远用 `Depends`**——不要全局 import db
- **generator 形式** —— yield + finally 清理
- **override 依赖**便于测试：`app.dependency_overrides[get_db] = ...`

---

## 9. 性能常识

- **大列表查找** → 用 `set` 或 `dict`，别用 `list`
- **字符串拼接循环** → 用 `"".join(parts)`，别用 `+=`
- **读大文件** → `for line in file:`（迭代器），别 `readlines()`
- **CPU 密集** → `multiprocessing`，别 `threading`（GIL 限制）
- **N+1 查询** → 用 `selectinload` / `joinedload`（SQLAlchemy），或 `.values()` 直接 dict

---

## 10. 项目结构（推荐）

```
src/
├── api/                 # FastAPI 路由
│   ├── v1/
│   └── deps.py          # 共享 Depends
├── core/                # 配置、日志、异常
│   ├── config.py
│   └── errors.py
├── domain/              # 业务模型、领域服务
│   ├── user.py
│   └── orders.py
├── infra/               # DB、缓存、外部服务
│   ├── db.py
│   └── s3.py
├── services/            # 用例编排
│   └── checkout.py
└── main.py
```

---

## 高频反模式（自查清单）

- [ ] 没用 `# type: ignore` 偷懒
- [ ] async 里没调同步阻塞 IO
- [ ] catch 没空吞
- [ ] 没把 `Optional[T]` 当错误用
- [ ] 没在 dataclass 里 mutable
- [ ] 路径用 `pathlib` + 显式 encoding
- [ ] 测试有边界 + 异常 + 异步 fixture
- [ ] DB 用 `Depends` 注入
- [ ] N+1 查询用 `selectinload`
- [ ] import 没"顺手"重排
