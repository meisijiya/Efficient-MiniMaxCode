---
name: backend-patterns-java
description: "Java 后端核心模式（Spring Boot 3+ / JVM 21+ / 不可变 record / 构造器注入 / 异常体系）。触发词：java, spring, springboot, jvm, jpa, 后端"
---

# Java / Spring Boot 后端核心模式

> 适用：Java 后端，JVM 21+，Spring Boot 3+。

## 4 原则提醒（落地版）

- **Think First**：明确"同步 vs 异步"、"事务边界在哪"、"可变 vs 不可变"
- **Simplicity**：record 优先，类能少就少
- **Surgical**：改方法签名不"顺手"改格式；改 import 不动业务
- **Goal-Driven**：JUnit 测试先红后绿

---

## 1. 现代 Java 必备

| 旧习惯 | 现代替代 |
|--------|---------|
| `class User { ... }` 加 getter/setter | `record User(String name, int age) {}` |
| `new ArrayList<>()` | `new ArrayList<>()`（保留）或 `List.of()` 不可变 |
| `StringBuilder` 拼接 | `String.join()` / text block |
| `Optional<T>` 作字段类型 | 不作字段，只作返回 |
| 匿名内部类 | Lambda |
| 写 `equals/hashCode` | record 自动 |
| `@Data` Lombok | record（无 Lombok 依赖） |

### record 优先
```java
// ✅
public record User(String id, String email, int age) {}

// ❌ 类 + getter/setter + equals/hashCode + toString
public class User {
    private String id;
    // ...
}
```

---

## 2. Spring Boot 注入（构造器优先）

```java
// ✅ 构造器注入（不可变 + 易测试 + 显式依赖）
@Service
public class UserService {
    private final UserRepository repo;
    private final EmailSender email;

    public UserService(UserRepository repo, EmailSender email) {
        this.repo = repo;
        this.email = email;
    }
}

// ❌ 字段注入（隐式依赖，难测试）
@Service
public class UserService {
    @Autowired
    private UserRepository repo;
}
```

### 规则
- **永远 final 字段**
- **永远构造器注入**
- **@Autowired** 加在构造器上（Spring 4.3+ 可省略）
- **测试时直接 `new UserService(mockRepo, mockEmail)`**，不用 Spring context

---

## 3. 不可变性

```java
// ✅ record 默认不可变
public record Point(int x, int y) {}

// ✅ 集合返回不可变视图
public List<Order> getOrders() {
    return List.copyOf(orders);  // 防御性拷贝
}

// ❌ 暴露可变内部状态
public List<Order> getOrders() {
    return orders;  // 调用方可以 add/remove
}
```

---

## 4. Optional 用法（**只作返回类型**）

```java
// ✅ 返回类型表示"可能没有"
public Optional<User> findById(String id) { ... }

// ❌ 作字段
public class Order {
    private Optional<User> assignee;  // 序列化、反射都很难搞
}

// ❌ 作方法参数
public void updateUser(Optional<String> name) { ... }  // 应该用重载或 null

// ❌ Optional.of(null) - 会 NPE
Optional.of(nullableValue);
```

---

## 5. 异常体系

### 业务异常用 unchecked（RuntimeException）
```java
// ✅ unchecked 业务异常
public class UserNotFoundException extends RuntimeException {
    public UserNotFoundException(String userId) {
        super("user not found: " + userId);
    }
}
```

### 全局 handler（**必须有**）
```java
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(UserNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleNotFound(UserNotFoundException e) {
        return ResponseEntity.status(404)
            .body(new ErrorResponse("user_not_found", e.getMessage()));
    }

    @ExceptionHandler(ValidationException.class)
    public ResponseEntity<ErrorResponse> handleValidation(ValidationException e) {
        return ResponseEntity.status(400)
            .body(new ErrorResponse("validation_error", e.getMessage()));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponse> handleOther(Exception e) {
        log.error("unhandled", e);
        return ResponseEntity.status(500)
            .body(new ErrorResponse("internal", "internal error"));
    }
}
```

### 规则
- **不要 throws checked 异常污染 controller 签名**
- **不要在 catch 里只 log 不 rethrow**（除非是有意的 fallback）
- **不要 catch Throwable / Exception**（太宽）
- **catch + rethrow 时用 `cause`**：`throw new ServiceError("x failed", e)`

---

## 6. JPA / 数据库

### Entity 设计
```java
// ✅ 不可变 ID + 显式关系
@Entity
public class Order {
    @Id @GeneratedValue
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    private User user;

    @OneToMany(mappedBy = "order", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<OrderItem> items = new ArrayList<>();

    // getter / 业务方法
    public void addItem(OrderItem item) {
        items.add(item);
        item.setOrder(this);
    }
}
```

### N+1 防护
```java
// ✅ 用 JOIN FETCH 或 @EntityGraph
@Query("SELECT o FROM Order o JOIN FETCH o.items WHERE o.id = :id")
Optional<Order> findByIdWithItems(@Param("id") Long id);

// ✅ 批量加载
@BatchSize(size = 100)
@OneToMany(mappedBy = "order")
private List<OrderItem> items;
```

### 事务边界
```java
// ✅ @Transactional 在 service（不是 controller）
@Service
public class OrderService {
    @Transactional
    public Order placeOrder(CreateOrderRequest req) { ... }
}

// ❌ 在 controller 加事务（web 请求持锁太危险）
```

---

## 7. Spring Boot 3 / Java 21 现代特性

### Virtual Threads（**JVM 21+ 强烈推荐用于 IO 密集**）
```properties
# application.properties
spring.threads.virtual.enabled=true
```

```java
// 自动对所有 @Async / Tomcat 请求生效
// 不需要改代码
```

### Pattern Matching
```java
// ✅ switch 模式匹配
public String describe(Object obj) {
    return switch (obj) {
        case Integer i -> "int: " + i;
        case String s -> "str: " + s;
        case null -> "null";
        default -> "other";
    };
}

// ✅ instanceof 模式变量
if (obj instanceof String s) {
    return s.length();
}
```

### Text Blocks + formatted
```java
String sql = """
    SELECT * FROM users
    WHERE email = '%s'
    """.formatted(email);  // 注意：仍然要参数化
```

---

## 8. 测试（JUnit 5 + Mockito）

```java
@ExtendWith(MockitoExtension.class)
class UserServiceTest {

    @Mock UserRepository repo;
    @Mock EmailSender email;

    @InjectMocks UserService service;

    @Test
    void findUser_throws_whenNotFound() {
        when(repo.findById("u1")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.findUser("u1"))
            .isInstanceOf(UserNotFoundException.class);
    }

    @Test
    void createUser_sendsWelcomeEmail() {
        when(repo.save(any())).thenReturn(testUser);

        service.createUser(req);

        verify(email).sendWelcome(testUser);
    }
}
```

### 规则
- **用 AssertJ 不用 JUnit 原生 assert**（可读性 + 链式）
- **@Mock + @InjectMocks**——别 `@SpringBootTest` 跑全栈
- **集成测试** → 用 `@DataJpaTest` / `@WebMvcTest` 等切片
- **不要在单测里调真实 DB / 真实 HTTP**

---

## 9. 日志

```java
// ✅ SLF4J
log.info("user created: {}", user.id());  // 参数化，不拼字符串
log.error("order failed", exception);       // 异常作最后一个参数

// ❌ 拼字符串
log.info("user created: " + user.id());  // 浪费 CPU
log.error(exception.getMessage());         // 丢 stack trace
```

---

## 10. 项目结构（推荐）

```
src/main/java/com/example/
├── api/                 # controller
│   └── UserController.java
├── core/                # 配置、异常、通用
│   ├── GlobalExceptionHandler.java
│   └── ErrorResponse.java
├── domain/              # 业务模型 + 领域服务
│   ├── user/
│   │   ├── User.java
│   │   ├── UserRepository.java
│   │   └── UserService.java
│   └── order/
├── infra/               # DB / 缓存 / 第三方
│   └── EmailSender.java
└── Application.java
```

---

## 高频反模式（自查清单）

- [ ] 没用 `@Autowired` 字段注入
- [ ] 没用 `Optional` 作字段
- [ ] 没用 class（用 record 不可变）
- [ ] catch 没只 log 不 rethrow
- [ ] 事务在 service 而非 controller
- [ ] N+1 用了 JOIN FETCH 或 @EntityGraph
- [ ] 日志用 `{}` 参数化
- [ ] 单测用 Mockito 不起 Spring
- [ ] 没 catch Exception / Throwable 太宽
- [ ] 没暴露可变内部集合
