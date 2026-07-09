# Scaling Strategy

> Scale is not a feature. It is an emergent property of correct architecture.

## Philosophy

1. **Horizontal by default:** Add nodes, not bigger nodes
2. **Stateless services:** No local state that prevents scaling
3. **Async processing:** Do not block on slow operations
4. **Partition everything:** Split data and work across nodes
5. **Cache aggressively:** Do not recompute what you already computed
6. **Measure before optimizing:** Data-driven scaling decisions

## Scaling Dimensions

### Current vs Target Scale

| Dimension | Current (M0) | Phase 1 (1K APIs) | Phase 2 (5K APIs) | Phase 3 (15K APIs) | Phase 4 (20K+ APIs) |
|-----------|-------------|-------------------|-------------------|-------------------|---------------------|
| **APIs** | 0 | 1,000 | 5,000 | 15,000 | 20,000+ |
| **Languages** | 0 | 5 | 8 | 10 | 12+ |
| **Generated Files** | 0 | 1M | 10M | 50M | 100M+ |
| **LOC Generated** | 0 | 250M | 1.25B | 3.75B | 5B+ |
| **Concurrent Workers** | 0 | 100 | 1,000 | 5,000 | 10,000+ |
| **Storage** | 0 | 10 TB | 100 TB | 500 TB | 1 PB+ |
| **Requests/sec** | 0 | 1,000 | 10,000 | 50,000 | 100,000+ |
| **Kafka Throughput** | 0 | 10K msg/s | 100K msg/s | 500K msg/s | 1M+ msg/s |
| **DB QPS** | 0 | 10K | 100K | 500K | 1M+ |
| **Search Queries** | 0 | 100/sec | 1,000/sec | 5,000/sec | 10,000+/sec |
| **CDN Bandwidth** | 0 | 1 Gbps | 10 Gbps | 50 Gbps | 100+ Gbps |
| **Monthly Cost** | $0 | $50K | $200K | $1M | $2M+ |

## Service-Level Scaling

### Discovery Engine

**Scaling Characteristics:** I/O-bound (network crawling), CPU-bound (parsing)

**Current:** 3 replicas
**Target:** 20-100 replicas

**Strategy:**
- Horizontal scaling via HPA (CPU + memory metrics)
- Rate limiting per domain (Redis token bucket)
- Politeness delays (configurable per domain)
- Distributed crawl frontier (Redis sorted set)
- Result deduplication (content hash in Redis)
- Batch processing (crawl in batches, not one-by-one)

**Bottlenecks:**
- External API rate limits (not under our control)
- Network bandwidth (mitigated by geo-distributed workers)
- Parse CPU (mitigated by Rust parser)

### SDK Generator

**Scaling Characteristics:** CPU-bound (AST manipulation, code rendering)

**Current:** 5 replicas
**Target:** 100-1,000 replicas

**Strategy:**
- Dedicated compute-optimized node pool (high CPU, high memory)
- Job queue (Kafka) with partition scaling
- Worker pool auto-scaling based on queue depth (KEDA)
- Content-addressable storage (deduplication eliminates redundant work)
- Deterministic generation (cache results by input hash)
- Parallel language generation (one API -> multiple languages in parallel)

**Bottlenecks:**
- CPU (mitigated by compute-optimized instances)
- Memory (mitigated by streaming generation, not loading everything into memory)
- Storage I/O (mitigated by async writes, batch uploads)

### API Registry

**Scaling Characteristics:** I/O-bound (database reads/writes), read-heavy

**Current:** 3 replicas
**Target:** 30-100 replicas

**Strategy:**
- Read replicas (CockroachDB follower reads)
- Write sharding (by API ID hash)
- Caching (Redis for hot data)
- Search offloading (OpenSearch for full-text queries)
- Graph offloading (Neo4j for relationship queries)
- Event sourcing (append-only, no updates in place)

### Queue System (Kafka)

**Scaling Characteristics:** Network I/O, disk I/O

**Current:** 3 brokers
**Target:** 50+ brokers

**Strategy:**
- Partition scaling (64 -> 1024 partitions per topic)
- Broker scaling (add brokers for throughput)
- Replication factor 3 (minimum)
- Min ISR 2 (availability vs durability trade-off)
- Compacted topics for event sourcing (reduce storage)
- Consumer group scaling (add consumers for parallelism)

### Metadata Database (CockroachDB)

**Scaling Characteristics:** Mixed (reads + writes)

**Current:** 3 nodes
**Target:** 100+ nodes

**Strategy:**
- Node scaling (add nodes for capacity)
- Automatic rebalancing (CockroachDB handles this)
- Geo-partitioning (data near users)
- Follower reads (reduce read latency)
- Partitioning by time (for append-heavy tables)
- Index optimization (covering indexes, partial indexes)

### Search Engine (OpenSearch)

**Scaling Characteristics:** Memory-bound (inverted index), CPU-bound (queries)

**Current:** 3 nodes
**Target:** 50+ nodes

**Strategy:**
- Index sharding (by API category or hash)
- Hot/warm/cold data tiers
- Dedicated master nodes (3+)
- Read replicas (for query scaling)
- Index lifecycle management (roll over, delete old)
- Query optimization (filter caching, request caching)

### Storage (S3)

**Scaling Characteristics:** Effectively unlimited

**Strategy:**
- S3 is designed for unlimited scale
- Content-addressable storage (natural deduplication)
- Lifecycle policies (move old data to cheaper tiers)
- Cross-region replication (for availability)
- CloudFront CDN (for read performance)
- Multi-part uploads (for large files)

**Cost Optimization:**
| Tier | Storage Class | Cost | Use Case |
|------|--------------|------|----------|
| Hot | S3 Standard | $0.023/GB | Current artifacts |
| Warm | S3 Standard-IA | $0.0125/GB | Previous versions |
| Cold | S3 Glacier | $0.004/GB | Old versions |
| Archive | S3 Glacier Deep Archive | $0.00099/GB | Very old versions |

## Capacity Planning

### Methodology

1. **Measure current:** Baseline metrics for all services
2. **Project growth:** Extrapolate from roadmap milestones
3. **Identify bottlenecks:** Find the limiting factor
4. **Plan scaling:** Add capacity before it is needed
5. **Test at scale:** Load test at 10x expected capacity
6. **Optimize:** Reduce cost per unit of work

### Quarterly Capacity Review

| Review Item | Data Source | Decision |
|-------------|------------|----------|
| Compute utilization | Prometheus | Scale up/down nodes |
| Storage growth | S3 metrics | Adjust lifecycle policies |
| Network bandwidth | CDN metrics | Add CDN capacity |
| Database QPS | CockroachDB metrics | Add nodes or optimize queries |
| Queue depth | Kafka metrics | Add consumers or brokers |
| Cost per LOC | Financial data | Optimize or accept |
| Error rates | All services | Investigate or scale |

## Performance Budgets

| Metric | Budget | CI Gate | Alert | Action |
|--------|--------|---------|-------|--------|
| Build time | < 5 min | Block PR | P2 | Optimize build |
| Unit test time | < 30 sec/test | Block PR | P3 | Parallelize tests |
| Integration test time | < 10 min | Block PR | P2 | Optimize setup |
| E2E test time | < 30 min | Block PR | P2 | Optimize flows |
| Docker image size | < 500 MB | Block PR | P3 | Multi-stage build |
| Container startup | < 10 sec | Block PR | P2 | Optimize init |
| API response time | P95 < 100ms | Block PR | P1 | Optimize code |
| DB query time | P95 < 10ms | Block PR | P1 | Add index |
| Memory per request | < 10 MB | Block PR | P2 | Reduce allocations |
| CPU per request | < 10ms | Block PR | P2 | Optimize algorithm |

## Load Testing

### Load Test Types

| Type | Frequency | Target | Duration | Environment |
|------|-----------|--------|----------|-------------|
| **Smoke** | Every PR | 10 RPS | 1 min | CI |
| **Baseline** | Daily | 100 RPS | 10 min | Staging |
| **Load** | Weekly | 1,000 RPS | 1 hour | Staging |
| **Stress** | Monthly | 10,000 RPS | 4 hours | Staging |
| **Spike** | Monthly | 100,000 RPS | 10 min | Staging |
| **Soak** | Quarterly | 1,000 RPS | 72 hours | Staging |
| **Production** | Continuous | Real traffic | Ongoing | Production |

## Cost Optimization

### Cost per LOC Target

| Year | Target | Notes |
|------|--------|-------|
| 2026 | $0.10 | Early stage, high R&D cost |
| 2027 | $0.01 | Efficiency gains from scale |
| 2028 | $0.005 | Mature platform, optimization |
| 2029 | $0.002 | Advanced caching, AI optimization |
| 2030 | $0.001 | Fully optimized, economies of scale |

### Optimization Strategies

1. **Spot instances:** 70% cost reduction for fault-tolerant workloads
2. **Reserved instances:** 40% cost reduction for baseline capacity
3. **Right-sizing:** Match instance type to workload (no over-provisioning)
4. **Auto-scaling:** Scale to zero for idle services
5. **Caching:** Reduce compute by caching at every layer
6. **Deduplication:** Content-addressable storage eliminates redundant storage
7. **Compression:** Zstd for metrics, gzip for logs, Brotli for CDN
8. **Tiered storage:** Move old data to cheaper tiers
9. **Query optimization:** Reduce database load with better queries
10. **Batch processing:** Process in batches, not one-by-one

---

*This scaling strategy is a living document. All changes require ADR review and quarterly capacity planning.*
