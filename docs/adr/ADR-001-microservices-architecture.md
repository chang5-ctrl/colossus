# ADR-001: Microservices Over Monolith

**Status:** Accepted  
**Date:** 2026-07-09  
**Deciders:** Chief Architect, Platform Engineering Lead  
**Category:** Architecture

## Context

Project Colossus must scale to 20,000+ APIs, 28 subsystems, and thousands of concurrent workers. 
We need a system where each subsystem can be independently developed, deployed, and scaled.

Key constraints:
- Different subsystems have different scaling characteristics (CPU-bound generation vs I/O-bound discovery)
- Teams will work on different subsystems in parallel
- Some subsystems may be replaced entirely as technology evolves
- Failure isolation is critical at this scale

## Decision

Adopt a microservices architecture with 28 independently deployable services.

Each service:
- Has its own codebase (in `services/<service-name>/`)
- Owns its own data (database per service, no shared databases)
- Communicates via gRPC (internal) and REST (external)
- Uses Kafka for asynchronous event-driven communication
- Is containerized with Docker
- Deployed independently via Kubernetes

Services are grouped by function but remain independent:
- Control plane services manage the platform
- Data plane services process and generate artifacts
- Shared infrastructure services provide cross-cutting concerns

## Consequences

### Positive

- Independent scaling: Each service scales based on its own load
- Independent deployment: Changes to one service don't require redeploying others
- Technology diversity: Each service can use the best language for its workload
- Fault isolation: Failure in one service doesn't cascade
- Team autonomy: Teams can own services end-to-end
- Replaceability: Services can be rewritten or replaced without system-wide changes

### Negative

- Operational complexity: 28 services to monitor, deploy, and debug
- Network overhead: Inter-service communication adds latency
- Data consistency: Distributed transactions require careful design
- Testing complexity: Integration testing across services is harder
- Cognitive load: Engineers must understand the system as a whole

## Alternatives Considered

### Monolith
Rejected: Would not allow independent scaling of generation (CPU-heavy) vs registry (I/O-heavy). Would create a massive codebase that becomes unmaintainable.

### Serverless (Functions)
Rejected: While attractive for some workloads, cold start latency is unacceptable for generation workers. Vendor lock-in is a concern for a 20-year project.

### Modular Monolith
Rejected: Better than pure monolith but still couples deployment. Does not solve the scaling problem for different workload types.

## Related ADRs

- ADR-002: gRPC as Primary Inter-Service Protocol
- ADR-003: Event-Driven Architecture
- ADR-004: Kubernetes for Orchestration

## References

- [The Twelve-Factor App](https://12factor.net/)
- [Building Microservices](https://samnewman.io/books/building_microservices/) by Sam Newman
- [Google SRE Book](https://sre.google/sre-book/table-of-contents/)
