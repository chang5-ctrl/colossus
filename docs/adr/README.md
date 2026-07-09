# Architecture Decision Record (ADR) Index

> The canonical index of all architectural decisions for Project Colossus.
> Every significant decision is documented, debated, and recorded here.

## Status Legend

| Status | Meaning |
|--------|---------|
| **Accepted** | Decision approved and implemented |
| **Proposed** | Decision under discussion |
| **Deprecated** | Decision superseded by newer ADR |
| **Rejected** | Decision explicitly rejected |

## ADR Registry

| # | Title | Status | Date | Category |
|---|-------|--------|------|----------|
| [ADR-001](ADR-001-microservices-architecture.md) | Microservices Over Monolith | Accepted | 2026-07-09 | Architecture |
| [ADR-002](ADR-002-grpc-rest-protocols.md) | gRPC for Internal, REST for External | Accepted | 2026-07-09 | Communication |
| [ADR-003](ADR-003-event-driven-kafka.md) | Event-Driven Architecture with Kafka | Accepted | 2026-07-09 | Architecture |
| [ADR-004](ADR-004-kubernetes-orchestration.md) | Kubernetes for Orchestration | Accepted | 2026-07-09 | Infrastructure |
| [ADR-005](ADR-005-docker-containerization.md) | Docker for Containerization | Accepted | 2026-07-09 | Infrastructure |
| [ADR-006](ADR-006-cockroachdb-metadata.md) | CockroachDB for Primary Metadata | Accepted | 2026-07-09 | Data |
| [ADR-007](ADR-007-redis-caching.md) | Redis Cluster for Caching | Accepted | 2026-07-09 | Data |
| [ADR-008](ADR-008-s3-object-storage.md) | S3-Compatible Object Storage | Accepted | 2026-07-09 | Data |
| [ADR-009](ADR-009-rust-performance.md) | Rust for Performance-Critical Components | Accepted | 2026-07-09 | Engineering |
| [ADR-010](ADR-010-go-services.md) | Go for Service Implementation | Accepted | 2026-07-09 | Engineering |
| [ADR-011](ADR-011-python-data-ml.md) | Python for Data Processing and ML | Accepted | 2026-07-09 | Engineering |
| [ADR-012](ADR-012-opensearch-search.md) | OpenSearch for Search | Accepted | 2026-07-09 | Data |
| [ADR-013](ADR-013-neo4j-knowledge-graph.md) | Neo4j for Knowledge Graph | Accepted | 2026-07-09 | Data |
| [ADR-014](ADR-014-temporal-workflows.md) | Temporal.io for Workflow Orchestration | Accepted | 2026-07-09 | Architecture |
| [ADR-015](ADR-015-bazel-build-system.md) | Bazel for Monorepo Build | Accepted | 2026-07-09 | Engineering |
| [ADR-016](ADR-016-content-addressable-storage.md) | Content-Addressable Storage | Accepted | 2026-07-09 | Data |
| [ADR-017](ADR-017-deterministic-generation.md) | Deterministic Code Generation | Accepted | 2026-07-09 | Engineering |
| [ADR-018](ADR-018-semantic-versioning.md) | Semantic Versioning for All Artifacts | Accepted | 2026-07-09 | Engineering |
| [ADR-019](ADR-019-oauth-opa-auth.md) | OAuth 2.0 + OIDC + OPA for Auth | Accepted | 2026-07-09 | Security |
| [ADR-020](ADR-020-wasm-plugins.md) | WebAssembly for Plugin System | Accepted | 2026-07-09 | Architecture |
| [ADR-021](ADR-021-plugin-system-architecture.md) | Plugin System Architecture | Accepted | 2026-07-09 | Architecture |
| [ADR-022](ADR-022-contributor-framework.md) | Contributor Framework and Governance | Accepted | 2026-07-09 | Governance |
| [ADR-023](ADR-023-git-workflow.md) | Git Workflow and Branching Strategy | Accepted | 2026-07-09 | Engineering |
| [ADR-024](ADR-024-istio-service-mesh.md) | Istio Service Mesh | Accepted | 2026-07-09 | Infrastructure |
| [ADR-025](ADR-025-cdn-strategy.md) | Multi-CDN Strategy | Accepted | 2026-07-09 | Infrastructure |
| [ADR-026](ADR-026-nextjs-website.md) | Next.js for Public Website | Accepted | 2026-07-09 | Engineering |
| [ADR-027](ADR-027-observability-stack.md) | Prometheus + Thanos + Loki + Jaeger | Accepted | 2026-07-09 | Infrastructure |
| [ADR-028](ADR-028-disaster-recovery.md) | Multi-Region Disaster Recovery | Accepted | 2026-07-09 | Operations |

## Statistics

- **Total ADRs:** 28
- **Accepted:** 28
- **Proposed:** 0
- **Deprecated:** 0
- **Rejected:** 0
- **Categories:** Architecture (6), Communication (1), Infrastructure (7), Data (6), Engineering (7), Security (1), Governance (1), Operations (1)

## How to Propose a New ADR

1. Create a new file: `docs/adr/ADR-XXX-short-title.md`
2. Use the [ADR template](ADR-001-microservices-architecture.md) as a starting point
3. Open a GitHub Discussion for community input
4. Submit a PR with the ADR
5. ADR check workflow will validate format
6. Core maintainers review and approve
7. Merge and update this index

## ADR Lifecycle

```
Proposed -> Discussion -> Accepted -> Implemented -> (Deprecated -> Superseded)
     |           |           |            |
     |           |           |            |
     v           v           v            v
  Rejected   Modified   Merged      Updated
```

---

*This index is maintained automatically. Do not edit manually.*
