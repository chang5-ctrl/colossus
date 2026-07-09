# ADR-004: Kubernetes for Container Orchestration

**Status:** Accepted  
**Date:** 2026-07-09  
**Deciders:** Chief Architect, Infrastructure Lead  
**Category:** Infrastructure

## Context

Colossus needs to run 28+ services, thousands of workers, multiple databases, and observability stacks across multiple regions.

Requirements:
- Automatic scaling based on load
- Self-healing (restart failed containers)
- Rolling updates with zero downtime
- Resource isolation and quotas
- Multi-region deployment
- Service discovery and load balancing
- Secret management

## Decision

Use Kubernetes as the container orchestration platform.

Key decisions:
- Each service runs as a Kubernetes Deployment
- Workers run as Kubernetes Jobs or CronJobs
- Databases run as StatefulSets with persistent volumes
- Service mesh (Istio) for mTLS, traffic management, observability
- KEDA for event-driven auto-scaling
- Helm for package management
- ArgoCD for GitOps-based deployments

Cluster Topology:
- Control plane cluster: Core services, databases
- Data plane cluster: Workers, batch jobs
- Observability cluster: Monitoring, logging, tracing
- Public cluster: Website, API gateway

Multi-region:
- Primary region: Full deployment
- Secondary regions: Read replicas, worker pools
- Global load balancer for traffic distribution

## Consequences

### Positive

- Industry standard: Massive ecosystem, extensive tooling
- Auto-scaling: Horizontal Pod Autoscaler + KEDA for event-driven scaling
- Self-healing: Automatic restarts, health checks
- Rolling updates: Zero-downtime deployments
- Resource management: CPU/memory limits, quotas
- Extensibility: CRDs, operators, custom controllers
- Multi-cloud: Runs on AWS, GCP, Azure, on-prem

### Negative

- Complexity: Steep learning curve, operational overhead
- Resource overhead: Control plane consumes resources
- Debugging: Distributed systems are harder to debug
- Vendor complexity: Cloud provider Kubernetes has quirks

## Alternatives Considered

### Nomad
Rejected: Simpler than Kubernetes but smaller ecosystem. Would be considered for edge deployments.

### Docker Swarm
Rejected: Deprecated by Docker Inc. Not suitable for production at this scale.

### Serverless (AWS Lambda, etc.)
Rejected: Cold start latency unacceptable for generation workers. Vendor lock-in concern for 20-year project.

### VMs with Custom Orchestration
Rejected: Would require building our own orchestration layer. Kubernetes solves this problem well.

## Related ADRs

- ADR-001: Microservices Architecture
- ADR-005: Docker for Containerization
- ADR-024: Service Mesh with Istio

## References

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Kubernetes Up & Running](https://www.oreilly.com/library/view/kubernetes-up/9781492046523/) by Kelsey Hightower
- [Site Reliability Engineering](https://sre.google/sre-book/table-of-contents/) by Google
