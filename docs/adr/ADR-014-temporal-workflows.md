# ADR-014: Temporal.io for Workflow Orchestration

**Status:** Accepted  
**Date:** 2026-07-09  
**Deciders:** Chief Architect, Platform Engineering Lead  
**Category:** Architecture

## Context

Colossus has complex, long-running workflows:
- API discovery pipeline (crawl → parse → validate → register)
- SDK generation pipeline (detect change → generate → validate → publish)
- Release pipeline (build → test → sign → publish → notify)
- Migration pipeline (detect breaking change → generate migration guide → validate)

These workflows:
- Take minutes to hours to complete
- Have multiple steps with dependencies
- Need retry logic, timeouts, and compensation
- Must be durable (survive worker crashes)
- Need visibility into progress and state

## Decision

Use Temporal.io for workflow orchestration.

Key decisions:
- Temporal Server for workflow state management
- Temporal SDKs (Go, Java, TypeScript) for workflow definitions
- PostgreSQL or Cassandra for persistence
- Elasticsearch for workflow visibility

Workflow Types:
- `DiscoveryWorkflow` — End-to-end API discovery
- `GenerationWorkflow` — SDK generation pipeline
- `ReleaseWorkflow` — Release coordination
- `ValidationWorkflow` — Artifact validation
- `MigrationWorkflow` — Version migration

Features Used:
- Activities: Individual workflow steps
- Child workflows: Sub-workflows for parallelization
- Signals: External events (cancel, pause, resume)
- Queries: Read workflow state without mutation
- Retries: Automatic retry with exponential backoff
- Timeouts: Activity and workflow timeouts
- Sagas: Compensation for failed workflows

## Consequences

### Positive

- Durability: Workflows survive process crashes
- Visibility: Query workflow state at any time
- Scalability: Temporal handles millions of concurrent workflows
- Language support: SDKs for Go, Java, TypeScript, Python, .NET
- Testing: Unit test workflows without running the server
- Community: Active, growing community

### Negative

- Complexity: Adds another distributed system to operate
- Learning curve: New paradigm (code as workflow definition)
- Persistence: Requires PostgreSQL or Cassandra
- Operational overhead: Temporal Server requires care and feeding

## Alternatives Considered

### Apache Airflow
Rejected: DAG-based, not code-based. Better for data pipelines than general workflow orchestration.

### Cadence (Temporal predecessor)
Rejected: Temporal is the evolution of Cadence with better SDKs and community.

### Custom Solution
Rejected: Would require building durable execution from scratch. Temporal solves this well.

## Related ADRs

- ADR-004: Kubernetes for Orchestration
- ADR-006: CockroachDB for Metadata

## References

- [Temporal Documentation](https://docs.temporal.io/)
- [Temporal Concepts](https://docs.temporal.io/concepts/)
- [Designing Data-Intensive Applications](https://dataintensive.net/) by Martin Kleppmann
