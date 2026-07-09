# ADR-007: Redis Cluster for Caching and Real-Time Operations

**Status:** Accepted  
**Date:** 2026-07-09  
**Deciders:** Chief Architect, Performance Lead  
**Category:** Data

## Context

Colossus needs a fast, in-memory data store for:
- Caching hot data (API metadata, generated artifact metadata)
- Rate limiting (per API, per user, per worker)
- Session storage
- Real-time leaderboards and metrics
- Distributed locks
- Job queues for lightweight tasks
- Pub/sub for cache invalidation

## Decision

Use Redis Cluster for caching, rate limiting, and real-time operations.

Key decisions:
- Redis Cluster mode for horizontal scaling
- Redis Streams for lightweight event streaming (secondary to Kafka)
- Redis Pub/Sub for cache invalidation broadcasts
- Redis Sorted Sets for priority queues and leaderboards
- Redis Lua scripts for atomic operations

Data Types by Use Case:
- Strings: Simple key-value caching
- Hashes: API metadata caching
- Sets: Unique job IDs, worker pools
- Sorted Sets: Priority queues, rate limiting windows
- Streams: Lightweight event log
- Pub/Sub: Cache invalidation

Persistence:
- AOF (Append-Only File) for durability
- RDB snapshots for backup
- Neither for pure cache data (reconstruct from source)

Eviction Policy:
- `allkeys-lru` for general cache
- `volatile-lru` for data with TTL
- `noeviction` for critical data (rate limits, locks)

## Consequences

### Positive

- Performance: Sub-millisecond latency
- Simplicity: Simple data structures, easy to reason about
- Scalability: Redis Cluster scales to 1000+ nodes
- Versatility: Multiple data structures for different use cases
- Maturity: Battle-tested, extensive ecosystem

### Negative

- Memory constraints: All data must fit in RAM
- Durability: Not a primary data store (use with persistence or reconstruct)
- Operational complexity: Cluster mode requires careful setup
- Single-threaded: CPU-bound operations can bottleneck

## Alternatives Considered

### Memcached
Rejected: Simpler but lacks data structures, persistence, and clustering.

### KeyDB
Rejected: Redis fork with multi-threading. Less mature, smaller community.

### Dragonfly
Rejected: Promising but newer. Would evaluate for future phases.

### Cloud Provider Cache (ElastiCache, Memorystore)
Rejected: Vendor lock-in. Must be deployable on any cloud or on-prem.

## Related ADRs

- ADR-006: CockroachDB for Metadata
- ADR-008: S3 for Object Storage
- ADR-019: Authentication Framework

## References

- [Redis Documentation](https://redis.io/documentation)
- [Redis Cluster Specification](https://redis.io/topics/cluster-spec)
- [Redis Streams](https://redis.io/topics/streams-intro)
