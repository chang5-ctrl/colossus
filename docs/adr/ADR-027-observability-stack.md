# ADR-027: Prometheus + Thanos + Loki + Jaeger for Observability

**Status:** Accepted  
**Date:** 2026-07-09  
**Deciders:** Chief Architect, Observability Lead  
**Category:** Infrastructure

## Context

Colossus needs comprehensive observability for:
- 28+ services
- Thousands of workers
- Millions of generated artifacts
- Petabytes of data
- Thousands of contributors

Observability pillars:
- Metrics: Performance, throughput, errors, business metrics
- Logs: Structured logs from all services
- Traces: Distributed tracing across services
- Alerts: Proactive alerting on anomalies

## Decision

Use the following observability stack:

## Metrics: Prometheus + Thanos
- Prometheus for metrics collection and alerting
- Thanos for long-term storage and global query view
- ServiceMonitor CRDs for automatic discovery
- Recording rules for pre-aggregated metrics
- Alertmanager for alert routing

## Logs: Loki
- Loki for log aggregation
- Promtail for log collection
- Structured JSON logging from all services
- LogQL for querying
- Correlation IDs for traceability

## Traces: Jaeger
- Jaeger for distributed tracing
- OpenTelemetry for instrumentation
- Sampling: 1% default, 100% for errors
- Trace retention: 7 days

## Dashboards: Grafana
- Grafana for visualization
- Pre-built dashboards for each service
- SLO dashboard
- Business metrics dashboard

## Alerting
- PagerDuty for P0/P1 alerts
- Slack for P2/P3 alerts
- Email for informational alerts
- On-call rotation via PagerDuty

## Consequences

### Positive

- Open source: All components are open source
- Mature: Battle-tested at massive scale
- Integration: Works well together (Prometheus + Loki + Grafana)
- Scalability: Thanos and Loki scale horizontally
- Standard: Industry standard for cloud-native observability

### Negative

- Resource usage: Significant CPU, memory, and storage
- Operational complexity: Each component requires care and feeding
- Cardinality: High cardinality metrics can overwhelm Prometheus
- Cost: Storage for metrics, logs, and traces is expensive at scale

## Alternatives Considered

### Datadog
Rejected: SaaS, vendor lock-in, expensive at this scale.

### New Relic
Rejected: Similar concerns to Datadog.

### Elastic Stack
Rejected: Good for logs but less mature for metrics and traces. Licensing concerns.

### OpenTelemetry Collector + CloudWatch
Rejected: Vendor lock-in. Must be cloud-agnostic.

## Related ADRs

- ADR-004: Kubernetes for Orchestration
- ADR-024: Istio Service Mesh

## References

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Thanos](https://thanos.io/)
- [Loki](https://grafana.com/docs/loki/latest/)
- [Jaeger](https://www.jaegertracing.io/)
- [OpenTelemetry](https://opentelemetry.io/)
