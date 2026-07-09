# ADR-006: CockroachDB for Primary Metadata Storage

**Status:** Accepted  
**Date:** 2026-07-09  
**Deciders:** Chief Architect, Database Lead  
**Category:** Data

## Context

Colossus needs a relational database that can:
- Store structured metadata for 20,000+ APIs
- Handle millions of generated artifacts
- Scale horizontally across regions
- Provide strong consistency for critical data
- Support complex queries and transactions
- Be PostgreSQL-compatible for tooling

## Decision

Use CockroachDB as the primary metadata database.

Key decisions:
- CockroachDB for all structured metadata (API records, jobs, releases, packages)
- PostgreSQL wire protocol compatibility
- Distributed SQL with ACID transactions
- Automatic rebalancing and replication
- Follower reads for read-heavy workloads
- Backup to S3-compatible storage

Schema Design:
- UUIDv7 primary keys (time-sortable, distributed-safe)
- JSONB columns for flexible schema evolution
- Partitioning by time for append-heavy tables
- Soft deletes with `deleted_at` timestamp
- Optimistic locking with `version` column

Read Replicas:
- Hot data: In-memory cache (Redis)
- Warm data: CockroachDB follower reads
- Cold data: S3 (Parquet format)

## Consequences

### Positive

- Horizontal scaling: Add nodes to increase capacity
- PostgreSQL compatibility: Existing tools, ORMs, drivers work
- Strong consistency: Serializable default isolation
- Multi-region: Native support for geo-partitioning
- Automatic recovery: Self-healing, automatic rebalancing
- Open source: CockroachDB Core is Apache 2.0

### Negative

- Complexity: Distributed systems are harder to operate
- Latency: Cross-node transactions have higher latency
- Resource usage: Higher overhead than single-node PostgreSQL
- Learning curve: Distributed SQL has different optimization patterns

## Alternatives Considered

### PostgreSQL with Patroni
Rejected: Excellent but requires manual setup for horizontal scaling. CockroachDB provides this out of the box.

### TiDB
Rejected: Similar to CockroachDB but MySQL-compatible. PostgreSQL ecosystem is preferred.

### YugabyteDB
Rejected: Similar capabilities. CockroachDB has stronger PostgreSQL compatibility and larger community.

### Spanner (Google Cloud)
Rejected: Proprietary, vendor lock-in. Colossus must be cloud-agnostic.

## Related ADRs

- ADR-003: Event-Driven Architecture
- ADR-007: Redis for Caching
- ADR-008: S3 for Object Storage

## References

- [CockroachDB Documentation](https://www.cockroachlabs.com/docs/)
- [CockroachDB Architecture](https://www.cockroachlabs.com/docs/stable/architecture/overview.html)
- [Google Spanner Paper](https://research.google/pubs/pub39966/)
