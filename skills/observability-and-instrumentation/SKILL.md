# Observability & Instrumentation — 上线后看得到

> 来自 addy `observability-and-instrumentation`：**结构化日志 / RED 指标 / OpenTelemetry / symptom-based alerting**。上线不是结束——**上线后能定位问题才是结束**。

## 触发场景

- `release-manager` 上线前 checklist 必查
- 写新功能（**每个**功能都要带可观测性）
- 加外部 API 调用（DB / HTTP / 消息队列）
- 加后台任务 / cron / 异步 job
- 收到"用户说 XX 挂了" 类工单（往往发现根本没埋点）

**不适用**：
- 纯前端组件（前端 observability 是另一套）
- 一次性脚本（< 100 行不重用）

## 核心原则

> **没观测 = 没上线**。 上线后出问题不知道在哪 = 没测过 = 没真上。

| 原则 | 含义 |
|------|------|
| **Symptom-based** | 告警按"用户看到的现象"组织（"付款失败率"），不是按"机器指标"（"CPU 80%"） |
| **Measure first** | 不优化没测过的；不告警没观察的 |
| **As you build** | 写代码时同时埋点；不在最后一周集中加 |
| **Three pillars** | 日志 + 指标 + trace 缺一不可 |

## 3 大支柱

### 1. 结构化日志（Structured Logging）

**为什么**：text log = 难查 = 没用。结构化 = JSON / key-value = 可聚合 = 可报警。

```python
# ❌ BAD: text log
print(f"Order {order_id} created for customer {customer_id}")

# ✅ GOOD: structured log
logger.info("order_created", extra={
    "order_id": order_id,
    "customer_id": customer_id,
    "amount_cents": amount_cents,
    "trace_id": trace_id,  # ← 关联到 trace
    "duration_ms": duration_ms,
})
```

**必备字段**（每条 log 都带）：
- `timestamp` (ISO 8601)
- `level` (DEBUG / INFO / WARN / ERROR)
- `message` (事件名，`order_created` 不是 `"Order created"`)
- `trace_id` / `span_id` （关联 trace）
- `service` (哪个服务)
- `env` (dev / staging / prod)
- **业务字段**（order_id / user_id 等）

**禁止**：
- ❌ `print(...)`（生产环境无 print）
- ❌ f-string 拼成 text（不可解析）
- ❌ log 密码 / token / PII / 卡号
- ❌ log 完整堆栈到 INFO（堆栈到 ERROR）
- ❌ 多行 log（难聚合）

### 2. RED 指标（Rate / Errors / Duration）

**RED = 来自 Google SRE 书的金标准**——**任何服务 3 个必埋**。

| 指标 | 含义 | 例 |
|------|------|-----|
| **Rate** | QPS / RPS（每秒多少请求） | `http_requests_total{status="200"}` |
| **Errors** | 失败率（5xx / 4xx / 业务失败） | `http_requests_total{status="500"}` |
| **Duration** | 延迟（p50 / p95 / p99） | `http_request_duration_seconds_bucket{le="0.2"}` |

**命名规范**（Prometheus 风格）：
- `<service>_<entity>_<action>_<unit>` 
- 例：`order_service_orders_created_total` / `order_service_create_order_duration_seconds`
- **不要**重复单位（`_total_total`）

**为什么 RED**：
- **Rate 跌 = 流量异常**（可能被攻击 / 上游挂了）
- **Errors 涨 = 质量异常**（用户看到失败）
- **Duration 涨 = 性能异常**（用户在等）

**USE**（补充）：CPU / 内存 / 磁盘 — 是机器视角；**RED 是用户视角**——告警用 RED。

### 3. Trace（OpenTelemetry）

**为什么**：一个请求跨 5 个服务（日志看不出链路），trace 画出完整链路。

```python
# 用 OpenTelemetry
from opentelemetry import trace
tracer = trace.get_tracer(__name__)

with tracer.start_as_current_span("create_order") as span:
    span.set_attribute("order.id", order_id)
    span.set_attribute("customer.id", customer_id)
    
    with tracer.start_as_current_span("validate_inventory"):
        # ... 业务逻辑
        ...
    
    with tracer.start_as_current_span("save_to_db"):
        # ... 业务逻辑
        ...
```

**关键属性**（必带）：
- `service.name` / `service.version`
- `http.method` / `http.route` / `http.status_code`
- `db.statement`（SQL 模板，不是参数）
- **业务属性**（`order.id` / `customer.tier`）

**3 关键决策**：
- **采样率**（默认 1%—10%，看量级）
- **存储**（Jaeger / Tempo / DataDog）
- **关联**（trace_id 进 log 字段）

## Symptom-based Alerting（**告警的金标准**）

**反模式**：按机器指标告警
```
❌ "CPU > 80%" → 半夜告警 → 你醒来 → 看 CPU 没事 → 关掉
```

**正模式**：按用户现象告警
```
✅ "5xx 错误率 > 1% 持续 5 分钟"
   ✅ "p95 延迟 > 2s 持续 10 分钟"
   ✅ "订单创建失败率 > 0.5%"
```

**好的告警特征**（Google SRE book）：
- **Symptom**：用户能感受到的（"付款失败"）
- **Actionable**：收到后能采取行动（"查 DB"）
- **Specific**：不是泛泛"服务慢"
- **Page-worthy**：半夜叫醒你 = 必须修

**告警分级**：
| 级别 | 含义 | 行动 |
|------|------|------|
| **P0** | 用户数据丢失 / 资金损失 | 立即处理 |
| **P1** | 大比例用户受影响 | 1 小时内处理 |
| **P2** | 小比例用户 / 性能降级 | 当天处理 |
| **P3** | 边缘问题 | 下次迭代修 |

## 4 个埋点检查清单（**每个新功能必过**）

```
□ 关键路径有 structured log（开始 / 完成 / 失败）
□ RED 3 个指标埋了（rate / errors / duration）
□ Trace span 关键步骤都包了
□ 失败场景有专门告警（不是"CPU 80%"）
```

## 6 个常见坑

| 坑 | 修正 |
|----|------|
| log 一堆 text 没法查 | 改 structured（JSON） |
| 没埋 latency 后定位不到慢 | 加 histogram（不是 gauge） |
| 告警按 CPU 不用用户视角 | 改 symptom-based（5xx 率 / p95） |
| 埋点只在 happy path | 失败 / 异常也要 log |
| trace_id 不进 log | log 加 trace_id 字段 |
| "上线完事"不监控 | 上线 = "埋点 + 告警 + dashboard 都齐" |

## 实战示例（Spring Boot 3）

```java
@RestController
public class OrderController {
    
    private static final Logger log = LoggerFactory.getLogger(OrderController.class);
    private final MeterRegistry meterRegistry;
    private final Tracer tracer;
    
    @PostMapping("/orders")
    public Order createOrder(@RequestBody OrderRequest req) {
        var timer = Timer.start(meterRegistry);
        var span = tracer.nextSpan().name("create_order").start();
        try {
            // 业务逻辑
            Order order = orderService.create(req);
            
            // 1. log（带 trace_id + 业务字段）
            log.info("order_created",
                StructuredArguments.kv("order_id", order.getId()),
                StructuredArguments.kv("customer_id", req.getCustomerId()),
                StructuredArguments.kv("amount_cents", order.getAmountCents())
            );
            
            // 2. RED: 成功 metric
            meterRegistry.counter("orders.created.total", "status", "success").increment();
            
            return order;
        } catch (Exception e) {
            // 1. log（错误 + 堆栈）
            log.error("order_creation_failed",
                StructuredArguments.kv("customer_id", req.getCustomerId()),
                e
            );
            // 2. RED: 失败 metric
            meterRegistry.counter("orders.created.total", "status", "failure").increment();
            throw e;
        } finally {
            // 3. duration
            timer.stop(meterRegistry.timer("orders.create.duration"));
            span.end();
        }
    }
}
```

**对应 dashboard 必有**：
- 订单创建 QPS（rate）
- 订单创建失败率（errors）
- 订单创建 p95 延迟（duration）
- 告警：失败率 > 1% 持续 5min → PagerDuty

## 与 addy `observability-and-instrumentation` 对照

| addy 提的 | 我们做的 |
|----------|---------|
| Structured logging | ✅ 必备字段 + 反例 |
| RED metrics | ✅ 3 指标详解 |
| OpenTelemetry tracing | ✅ 3 关键决策 |
| Symptom-based alerting | ✅ SRE 金标准 + 分级 |
| Three pillars (logs/metrics/traces) | ✅ 全部 |
| 失败埋点也重要 | ✅ "6 个坑" 第 4 条 |

**吸收度：100%**。

## 跟其他 skill / agent 的关系

- **`release-manager`**：上线前必查 4 项（log / metric / trace / alert）
- **`coder`**：写新功能时 load 这个 skill——**边写边埋**
- **`silent-failure-hunter`**：发现"无埋点导致定位慢" → 派 coder 补埋点
- **`performance-analyzer`**：发现"延迟高" → 看 duration metric / trace
- **`vibecoding-discipline`**：纯函数 + 显式错误 + 埋点 = 可观测的代码

## 红线

- ❌ 任何 API / 任务没埋 duration + 错误率
- ❌ 任何错误没 log 业务上下文
- ❌ 任何告警没指定级别（P0/P1/P2/P3）
- ❌ log 里有密码 / token / PII / 卡号
- ❌ "上线完事"没接监控
- ❌ 告警按机器指标（CPU / 内存）不用用户指标（5xx / 延迟）

## 一句话总结

> **没观测 = 没上线。3 大支柱（log + RED + trace）+ symptom-based 告警。每个新功能必过 4 项 checklist。**
