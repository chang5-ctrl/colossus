# ADR-003: Event-Driven Architecture with Apache Kafka

**Status:** Accepted  
**Date:** 2026-07-09  
**Deciders:** Chief Architect, Data Engineering Lead  
**Category:** Architecture

## Context

Colossus must handle thousands of concurrent jobs, process millions of events, and maintain audit trails.
Services need to react to state changes without tight coupling.

Requirements:
- Loose coupling between services
- Guaranteed message delivery
- Message ordering for certain workflows
- Replay capability for debugging and recovery
- Audit trail for compliance
- Horizontal scalability

## Decision

Adopt event-driven architecture with Apache Kafka as the primary message broker.

Key decisions:
- All state changes are published as events to Kafka
- Services consume relevant events and update their own state
- Event sourcing for critical domains (API lifecycle, generation jobs)
- CQRS (Command Query Responsibility Segregation) for read-heavy services
- Kafka topics are the source of truth for event streams

Event Categories:
- Domain events: `APIDiscovered`, `GenerationCompleted`, `ReleasePublished`
- Integration events: `CacheInvalidated`, `IndexUpdated`
- System events: `WorkerStarted`, `WorkerFailed`, `ScalingEvent`
- Audit events: `UserAction`, `PermissionChange`

Kafka Configuration:
- Replication factor: 3
- Min ISR: 2
- Retention: Compacted for event sourcing topics, time-based for operational
- Schema: Avro with Confluent Schema Registry

## Consequences

### Positive

- Loose coupling: Services don't need to know about each other
- Scalability: Kafka scales to millions of messages/second
- Durability: Messages persisted to disk, replicated
- Replay: Can replay events for recovery, debugging, new service bootstrapping
- Audit trail: Complete history of all state changes
- Backpressure: Consumers process at their own pace

### Negative

- Complexity: Event-driven systems are harder to reason about
- Eventual consistency: Services may be temporarily out of sync
- Debugging: Harder to trace request flow across events
- Schema evolution: Must carefully manage event schema changes
- Operational overhead: Kafka cluster requires dedicated operations

## Alternatives Considered

### Synchronous REST Only
Rejected: Would create tight coupling and cascading failures. Would not handle backpressure well.

### RabbitMQ
Rejected: Excellent for simple queuing but lacks Kafka's throughput, replay, and log compaction features.

### NATS JetStream
Rejected: Promising but less mature ecosystem. Would reconsider in future if Kafka becomes a bottleneck.

### Pulsar
Rejected: Feature-rich but smaller community. Kafka's ecosystem maturity is critical for a 20-year project.

## Related ADRs

- ADR-001: Microservices Architecture
- ADR-002: gRPC for Internal Communication
- ADR-006: CockroachDB for Metadata

## References

- [Kafka Documentation](https://kafka.apache.org/documentation/)
- [Designing Event-Driven Systems](https://www.confluent.io/designing-event-driven-systems/) by Ben Stopford
- [Event Sourcing](https://martinfowler.com/eaaDev/EventSourcing.html) by Martin Fowler
