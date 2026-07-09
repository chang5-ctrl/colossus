# Observability Strategy

> You cannot manage what you cannot observe.
> Every subsystem, every request, every failure must be observable.

## Philosophy

Observability is not monitoring. Monitoring asks "Is the system up?" 
Observability asks "Why is the system behaving this way?"

Colossus observability is built on three pillars:
1. **Metrics** — Quantify system behavior over time
2. **Logs** — Explain what happened in detail
3. **Traces** — Follow requests across distributed services

Plus two critical additions:
4. **Profiles** — Understand resource consumption at code level
5. **SLOs** — Define and measure reliability commitments

## Three Pillars

### 1. Metrics (Prometheus + Thanos)

**Purpose:** Measure everything that can be measured.

**Metric Types:**

| Type | Use Case | Example |
|------|----------|---------|
| Counter | Events that only increase | `discovery_apis_found_total` |
| Gauge | Values that go up and down | `sdk_generator_workers_active` |
| Histogram | Distributions of values | `http_request_duration_seconds` |
| Summary | Quantiles (client-calculated) | `generation_latency_seconds` |

**Metric Categories:**

#### Service-Level Metrics (RED Method)
- **Rate:** `http_requests_per_second`, `kafka_messages_consumed_per_second`
- **Errors:** `http_requests_failed_total`, `generation_jobs_failed_total`
- **Duration:** `http_request_duration_seconds`, `generation_duration_seconds`

#### Business-Level Metrics
- `colossus_apis_discovered_total` — Total APIs discovered
- `colossus_sdks_generated_total` — Total SDKs generated
- `colossus_releases_published_total` — Total releases published
- `colossus_packages_downloaded_total` — Total package downloads
- `colossus_lines_of_code_generated_total` — Cumulative LOC generated
- `colossus_active_apis` — Currently maintained APIs
- `colossus_api_sync_latency_seconds` — Time from upstream change to detection

#### Infrastructure Metrics
- `node_cpu_utilization_percent`
- `node_memory_utilization_percent`
- `node_disk_io_wait_seconds`
- `node_network_bytes_transmitted`
- `container_cpu_usage_seconds_total`
- `container_memory_working_set_bytes`
- `container_fs_usage_bytes`

#### Kafka Metrics
- `kafka_consumer_lag` — Critical for auto-scaling
- `kafka_topic_messages_in_per_second`
- `kafka_topic_messages_out_per_second`
- `kafka_broker_request_latency_seconds`

#### Database Metrics
- `cockroachdb_sql_queries_total`
- `cockroachdb_sql_query_latency_seconds`
- `cockroachdb_storage_capacity_bytes`
- `redis_commands_processed_total`
- `redis_keyspace_hits_total`
- `redis_keyspace_misses_total`
- `redis_memory_used_bytes`

**Prometheus Configuration:**
```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    cluster: colossus-prod
    replica: '{{.ExternalURL}}'

scrape_configs:
  - job_name: 'kubernetes-pods'
    kubernetes_sd_configs:
      - role: pod
        namespaces:
          names:
            - colossus
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
        action: replace
        target_label: __metrics_path__
        regex: (.+)
      - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
        action: replace
        regex: ([^:]+)(?::\d+)?;(\d+)
        replacement: $1:$2
        target_label: __address__
      - action: labelmap
        regex: __meta_kubernetes_pod_label_(.+)
      - source_labels: [__meta_kubernetes_namespace]
        action: replace
        target_label: kubernetes_namespace
      - source_labels: [__meta_kubernetes_pod_name]
        action: replace
        target_label: kubernetes_pod_name
```

**Thanos for Long-Term Storage:**
- Sidecar mode on each Prometheus instance
- Object storage (S3) for metric blocks
- Compactor for downsampling old data
- Query layer for global view across clusters
- Store Gateway for historical queries

**Retention:**
| Resolution | Retention | Use Case |
|------------|-----------|----------|
| Raw (15s) | 15 days | Debugging, alerting |
| 5-minute | 1 year | Trend analysis |
| 1-hour | 5 years | Capacity planning |

### 2. Logs (Loki)

**Purpose:** Structured, queryable logs from every service.

**Log Levels:**
| Level | Use Case | Volume |
|-------|----------|--------|
| DEBUG | Development, detailed tracing | High (dev only) |
| INFO | Normal operations, state changes | Medium |
| WARN | Degraded performance, retries | Low |
| ERROR | Failures, exceptions | Low |
| FATAL | System cannot continue | Very low |

**Structured Log Format (JSON):**
```json
{
  "timestamp": "2026-07-09T12:34:56.789Z",
  "level": "INFO",
  "service": "sdk-generator",
  "version": "1.2.3",
  "message": "SDK generation completed",
  "correlation_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "trace_id": "abc123def456",
  "span_id": "span789",
  "attributes": {
    "api_id": "stripe-api",
    "api_version": "2024-01-01",
    "language": "typescript",
    "duration_ms": 45000,
    "lines_of_code": 15000,
    "worker_id": "worker-123"
  }
}
```

**Correlation ID Propagation:**
Every request gets a `correlation_id` (UUIDv7) that flows through:
1. API Gateway → generates correlation_id
2. All downstream services → propagate in headers and logs
3. Kafka messages → include in message metadata
4. Database queries → log with correlation_id
5. Response → include correlation_id for support

**Loki Configuration:**
```yaml
auth_enabled: false

server:
  http_listen_port: 3100
  grpc_listen_port: 9096

ingester:
  lifecycler:
    ring:
      kvstore:
        store: inmemory
      replication_factor: 1
  chunk_idle_period: 5m
  chunk_retain_period: 30s
  max_transfer_retries: 0

schema_config:
  configs:
    - from: 2026-01-01
      store: boltdb-shipper
      object_store: s3
      schema: v11
      index:
        prefix: index_
        period: 24h

storage_config:
  boltdb_shipper:
    active_index_directory: /loki/index
    cache_location: /loki/index_cache
    shared_store: s3
  aws:
    s3: s3://us-east-1/colossus-logs
    insecure: false
    sse_encryption: true

compactor:
  working_directory: /loki/compactor
  shared_store: s3
  compaction_interval: 10m

limits_config:
  reject_old_samples: true
  reject_old_samples_max_age: 168h
  ingestion_rate_mb: 100
  ingestion_burst_size_mb: 200
  max_query_length: 720h
  max_query_parallelism: 32
```

**Log Retention:**
| Environment | Hot (Loki) | Warm (S3) | Cold (Glacier) |
|-------------|-----------|-----------|----------------|
| Production | 7 days | 30 days | 1 year |
| Staging | 3 days | 7 days | 30 days |

### 3. Traces (Jaeger + OpenTelemetry)

**Purpose:** Follow a single request across all 28 services.

**Trace Structure:**
```
Trace: api-change-detected -> generation-job -> sdk-generation -> validation -> release
  |
  ├─ Span: api-change-detection (5ms)
  |   ├─ Span: fetch-spec (2ms)
  |   └─ Span: diff-calculation (1ms)
  |
  ├─ Span: scheduler (10ms)
  |   ├─ Span: job-creation (3ms)
  |   └─ Span: worker-assignment (2ms)
  |
  ├─ Span: sdk-generation (45000ms)
  |   ├─ Span: spec-parsing (500ms)
  |   ├─ Span: ast-generation (10000ms)
  |   ├─ Span: code-rendering (20000ms)
  |   └─ Span: formatting (5000ms)
  |
  ├─ Span: validation (30000ms)
  |   ├─ Span: compilation (15000ms)
  |   ├─ Span: unit-tests (10000ms)
  |   └─ Span: static-analysis (5000ms)
  |
  └─ Span: release (5000ms)
      ├─ Span: changelog-generation (1000ms)
      ├─ Span: package-building (2000ms)
      └─ Span: registry-publish (2000ms)
```

**Sampling Strategy:**
| Scenario | Sampling Rate | Rationale |
|----------|--------------|-----------|
| Default | 1% | Volume control |
| Errors | 100% | Always trace failures |
| Slow requests (>P95) | 100% | Debug performance |
| Critical paths | 10% | Higher fidelity for important flows |
| Debug mode | 100% | On-demand for specific users |

**OpenTelemetry Configuration:**
```yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318

processors:
  batch:
    timeout: 1s
    send_batch_size: 1024
  resource:
    attributes:
      - key: service.namespace
        value: colossus
        action: upsert

exporters:
  jaeger:
    endpoint: jaeger-collector:14250
    tls:
      insecure: true
  prometheusremotewrite:
    endpoint: http://prometheus:9090/api/v1/write

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [batch, resource]
      exporters: [jaeger]
    metrics:
      receivers: [otlp]
      processors: [batch, resource]
      exporters: [prometheusremotewrite]
```

### 4. Profiles (Pyroscope / Parca)

**Purpose:** Understand CPU and memory usage at the function level.

**Profiling Types:**
- **CPU profiling:** Hot paths, function-level CPU usage
- **Memory profiling:** Heap allocations, memory leaks
- **Goroutine profiling:** Go routine dumps, deadlocks
- **Block profiling:** Blocking operations, mutex contention
- **Mutex profiling:** Lock contention

**Continuous Profiling:**
- Every service emits profiles every 10 seconds
- Profiles stored in object storage (S3)
- Query via time range and service
- Compare profiles before/after deployments

**Integration:**
```go
import "github.com/grafana/pyroscope-golang"

func main() {
    pyroscope.Start(pyroscope.Config{
        ApplicationName: "sdk-generator",
        ServerAddress:    "http://pyroscope:4040",
        ProfileTypes: []pyroscope.ProfileType{
            pyroscope.ProfileCPU,
            pyroscope.ProfileAllocObjects,
            pyroscope.ProfileInuseObjects,
            pyroscope.ProfileGoroutines,
        },
    })
}
```

### 5. SLOs (Service Level Objectives)

**Purpose:** Define reliability commitments and measure against them.

**SLO Framework:**

| SLO | SLI | Target | Error Budget | Measurement Window |
|-----|-----|--------|-------------|-------------------|
| **System Availability** | Successful HTTP requests / Total requests | 99.99% | 0.01% (52.6 min/year) | 30 days |
| **API Discovery Success** | Successful discoveries / Total attempts | 99.9% | 0.1% | 7 days |
| **Generation Success** | Successful generations / Total jobs | 99.5% | 0.5% | 7 days |
| **Validation Pass Rate** | Passed validations / Total validations | 98% | 2% | 7 days |
| **Release Success** | Successful releases / Total releases | 99.9% | 0.1% | 30 days |
| **API Sync Latency** | Time from upstream change to detection | P95 < 5 min | P95 > 10 min | 7 days |
| **End-to-End Pipeline** | Time from API change to published SDK | P95 < 2 hours | P95 > 4 hours | 7 days |
| **Search Query Latency** | Time to return search results | P95 < 100ms | P95 > 500ms | 30 days |
| **SDK Download Latency** | Time to serve SDK package | P95 < 50ms | P95 > 200ms | 30 days |
| **Log Ingestion Latency** | Time from log emission to queryable | P95 < 5s | P95 > 30s | 7 days |
| **Trace Ingestion Latency** | Time from span emitted to queryable | P95 < 10s | P95 > 60s | 7 days |

**Error Budget Policy:**

| Error Budget Consumption | Action |
|-------------------------|--------|
| < 50% | Normal operations |
| 50-75% | Alert team, review recent changes |
| 75-90% | Freeze non-critical deployments |
| 90-100% | Freeze all deployments, incident response |
| > 100% | SLO breach, post-mortem required |

**Burn Rate Alerts:**

| Burn Rate | Lookback | Alert Severity | Meaning |
|-----------|----------|---------------|---------|
| 1x | 30 days | P3 | Will exhaust budget in 30 days |
| 2x | 6 days | P2 | Will exhaust budget in 3 days |
| 14x | 1 hour | P1 | Will exhaust budget in 2 hours |
| 100x | 5 min | P0 | Will exhaust budget in 5 minutes |

## Alerting

### Alert Hierarchy

| Severity | Response Time | Escalation | Channel | Auto-Page |
|----------|--------------|------------|---------|-----------|
| P0 (Critical) | 5 min | On-call engineer | PagerDuty + Phone | Yes |
| P1 (High) | 15 min | On-call engineer | PagerDuty + Slack | Yes |
| P2 (Medium) | 1 hour | Team lead | Slack | No |
| P3 (Low) | 24 hours | Team | Slack + Ticket | No |
| P4 (Info) | — | Dashboard only | Grafana | No |

### Alert Rules (Prometheus)

```yaml
groups:
  - name: colossus-critical
    rules:
      - alert: ColossusSystemDown
        expr: up{job=~"colossus-.*"} == 0
        for: 2m
        labels:
          severity: p0
          team: sre
        annotations:
          summary: "Colossus service {{ $labels.service }} is down"
          description: "Service {{ $labels.service }} has been down for more than 2 minutes"
          runbook_url: "https://wiki.colossus.io/runbooks/service-down"

      - alert: ColossusHighErrorRate
        expr: |
          (
            sum(rate(http_requests_failed_total{job=~"colossus-.*"}[5m]))
            /
            sum(rate(http_requests_total{job=~"colossus-.*"}[5m]))
          ) > 0.01
        for: 5m
        labels:
          severity: p0
          team: sre
        annotations:
          summary: "High error rate in {{ $labels.service }}"
          description: "Error rate is {{ $value | humanizePercentage }} for the last 5 minutes"

      - alert: ColossusHighLatency
        expr: |
          histogram_quantile(0.95,
            sum(rate(http_request_duration_seconds_bucket{job=~"colossus-.*"}[5m])) by (le, service)
          ) > 1
        for: 10m
        labels:
          severity: p1
          team: platform
        annotations:
          summary: "High latency in {{ $labels.service }}"
          description: "P95 latency is {{ $value }}s for the last 10 minutes"

      - alert: ColossusKafkaConsumerLag
        expr: kafka_consumer_lag > 10000
        for: 15m
        labels:
          severity: p1
          team: platform
        annotations:
          summary: "High Kafka consumer lag"
          description: "Consumer lag is {{ $value }} for group {{ $labels.group }}"

      - alert: ColossusGenerationFailureRate
        expr: |
          (
            sum(rate(generation_jobs_failed_total[1h]))
            /
            sum(rate(generation_jobs_total[1h]))
          ) > 0.05
        for: 30m
        labels:
          severity: p1
          team: codegen
        annotations:
          summary: "High generation failure rate"
          description: "{{ $value | humanizePercentage }} of generation jobs failed in the last hour"

      - alert: ColossusSLOBurnRate
        expr: |
          (
            sum(rate(http_requests_failed_total{job=~"colossus-.*"}[1h]))
            /
            sum(rate(http_requests_total{job=~"colossus-.*"}[1h]))
          ) > 0.0014  # 14x burn rate for 99.99% SLO
        for: 5m
        labels:
          severity: p0
          team: sre
        annotations:
          summary: "SLO burn rate is critical"
          description: "Error budget will be exhausted in 2 hours at current rate"

      - alert: ColossusDatabaseConnections
        expr: cockroachdb_sql_conns > 10000
        for: 10m
        labels:
          severity: p2
          team: sre
        annotations:
          summary: "High database connection count"
          description: "{{ $value }} active connections to CockroachDB"

      - alert: ColossusDiskSpaceLow
        expr: |
          (
            node_filesystem_avail_bytes{mountpoint="/"}
            /
            node_filesystem_size_bytes{mountpoint="/"}
          ) < 0.1
        for: 5m
        labels:
          severity: p1
          team: sre
        annotations:
          summary: "Disk space is low on {{ $labels.instance }}"
          description: "Only {{ $value | humanizePercentage }} disk space remaining"

      - alert: ColossusMemoryPressure
        expr: |
          (
            node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes
          )
          /
          node_memory_MemTotal_bytes > 0.9
        for: 10m
        labels:
          severity: p1
          team: sre
        annotations:
          summary: "Memory pressure on {{ $labels.instance }}"
          description: "{{ $value | humanizePercentage }} memory utilization"
```

## Dashboards

### Grafana Dashboards

| Dashboard | Panels | Refresh | Audience |
|-----------|--------|---------|----------|
| **SLO Overview** | SLO compliance, error budget, burn rate | 30s | Leadership, SRE |
| **Service Health** | RED metrics per service | 10s | Service owners |
| **Platform Overview** | All services, infrastructure, Kafka | 10s | Platform team |
| **Generation Pipeline** | Job queue, worker utilization, success rate | 10s | Codegen team |
| **Discovery Pipeline** | Crawl rate, API found rate, parse errors | 30s | Discovery team |
| **Business Metrics** | APIs, SDKs, downloads, users | 1m | Product team |
| **Cost Analysis** | Compute, storage, bandwidth costs | 1h | Finance |
| **Security Overview** | Vulnerabilities, scan results, access logs | 5m | Security team |
| **Chaos Engineering** | Experiment results, resilience scores | 5m | SRE team |
| **On-Call** | Active alerts, recent incidents, runbooks | 10s | On-call engineer |

### Dashboard Standards

Every service dashboard must include:
1. **Service Health Panel:** Rate, Errors, Duration (RED)
2. **Dependency Health:** Upstream and downstream service health
3. **Resource Usage:** CPU, memory, disk, network
4. **Business Metrics:** Service-specific business metrics
5. **Alert Panel:** Active alerts for the service
6. **Log Panel:** Recent logs (via Loki)
7. **Trace Panel:** Recent traces (via Jaeger)

## On-Call

### Rotation
- **Primary:** 1 week rotations
- **Secondary:** 1 week rotations (offset by 3 days)
- **Shadow:** New engineers shadow for 2 weeks before going solo
- **Handoff:** Structured handoff document at rotation end

### Runbooks
Every alert must have a runbook:
- **Symptom:** What does this alert mean?
- **Impact:** What is affected?
- **Diagnosis:** How to investigate?
- **Mitigation:** How to fix immediately?
- **Resolution:** How to fix permanently?
- **Escalation:** When and who to escalate to?

### Incident Response

| Phase | Time | Actions |
|-------|------|---------|
| Detection | 0 min | Alert fires, PagerDuty pages |
| Acknowledgment | < 5 min | Engineer acknowledges, starts investigation |
| Triage | < 15 min | Determine severity, impact, scope |
| Mitigation | < 1 hour | Stop the bleeding (rollback, scale, circuit break) |
| Resolution | < 4 hours | Fix the root cause |
| Post-mortem | < 48 hours | Write post-mortem, identify action items |
| Follow-up | < 1 week | Implement action items |

### Post-Mortem Template
```markdown
# Incident Post-Mortem: [TITLE]

**Date:** YYYY-MM-DD
**Duration:** X hours Y minutes
**Severity:** P0/P1/P2
**Impact:** [What was affected, how many users, which services]

## Summary
[One paragraph summary]

## Timeline
| Time | Event |
|------|-------|
| 12:00 | Alert fires |
| 12:05 | Engineer acknowledges |
| ... | ... |

## Root Cause
[What caused the incident?]

## Impact Analysis
[Quantify the impact: users affected, data lost, revenue impact]

## Lessons Learned
[What went well? What could have gone better?]

## Action Items
| Action | Owner | Due Date | Priority |
|--------|-------|----------|----------|
| Fix X | @user | YYYY-MM-DD | P0 |

## Prevention
[How do we prevent this from happening again?]
```

## Observability Maturity Model

| Level | Name | Characteristics |
|-------|------|----------------|
| 1 | **Monitoring** | Basic uptime checks, manual investigation |
| 2 | **Metrics** | Dashboards, alerting, some automation |
| 3 | **Logging** | Structured logs, log aggregation, correlation IDs |
| 4 | **Tracing** | Distributed tracing, request flow visibility |
| 5 | **SLOs** | Error budgets, burn rate alerts, data-driven decisions |
| 6 | **Chaos** | Chaos engineering, resilience testing, game days |
| 7 | **Autonomous** | Self-healing, predictive alerts, auto-remediation |

**Current Target:** Level 5 (SLOs) by end of Year 1
**Long-term Goal:** Level 7 (Autonomous) by Year 4

## Cost Management

Observability at scale is expensive. Cost controls:

| Control | Implementation |
|---------|---------------|
| Metric cardinality limits | Drop high-cardinality labels |
| Log sampling | Sample DEBUG logs at 1% |
| Trace sampling | 1% default, 100% for errors |
| Retention tiers | Hot/Warm/Cold storage |
| Compression | Snappy for metrics, gzip for logs |
| Aggregation | Pre-aggregate common queries |
| Downsampling | Thanos compactor for old data |
| Alert tuning | Reduce false positives |

**Target:** Observability cost < 5% of total infrastructure cost

## Future Improvements

- [ ] **ML-based anomaly detection:** Detect patterns humans miss
- [ ] **Predictive alerting:** Alert before failure, not after
- [ ] **Auto-remediation:** Automatically fix common issues
- [ ] **Natural language querying:** "Why is the SDK generator slow?"
- [ ] **Cost attribution:** Per-service, per-API cost tracking
- [ ] **User experience monitoring:** Real user monitoring (RUM)
- [ ] **Synthetic monitoring:** Simulated API calls from global locations
- [ ] **eBPF-based observability:** Kernel-level visibility without sidecars

---

*This observability strategy is a living document. All changes require ADR review.*
