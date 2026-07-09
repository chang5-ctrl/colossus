# ADR-024: Istio Service Mesh

**Status:** Accepted  
**Date:** 2026-07-09  
**Deciders:** Chief Architect, Platform Engineering Lead  
**Category:** Infrastructure

## Context

Colossus has 28+ services communicating over the network.
Need to manage:
- Mutual TLS (mTLS) between services
- Traffic routing and splitting
- Circuit breaking and retries
- Observability (metrics, traces, logs)
- Rate limiting
- Authentication between services
- Canary deployments

## Decision

Use Istio as the service mesh.

Key decisions:
- Istio 1.20+ with ambient mesh (sidecar-less where possible)
- mTLS enabled for all inter-service communication
- Istio Gateway for ingress traffic
- VirtualServices for traffic routing
- DestinationRules for load balancing and circuit breaking
- PeerAuthentication for mTLS policy
- AuthorizationPolicy for access control

Features:
- **mTLS:** Automatic certificate management, encrypted service-to-service
- **Traffic Management:** Routing, splitting, retries, timeouts
- **Observability:** Automatic metrics, traces, access logs
- **Security:** Authorization policies, rate limiting
- **Resilience:** Circuit breaking, fault injection

Configuration:
- Istio configs stored in Git (GitOps)
- ArgoCD for continuous deployment of Istio configs
- Canary analysis with Flagger

## Consequences

### Positive

- Security: mTLS without application changes
- Observability: Automatic metrics and traces
- Resilience: Circuit breaking, retries, timeouts
- Traffic Management: Canary, blue-green, A/B testing
- Standard: Widely adopted, mature ecosystem

### Negative

- Complexity: Adds significant operational overhead
- Resource usage: Sidecars consume CPU and memory
- Debugging: Network issues harder to debug with proxy in path
- Learning curve: Istio has many concepts and configurations

## Alternatives Considered

### Linkerd
Rejected: Simpler than Istio but fewer features. Istio's ecosystem and feature set are worth the complexity.

### Cilium Service Mesh
Rejected: eBPF-based, promising but newer. Less mature ecosystem.

### No Service Mesh
Rejected: Would require implementing mTLS, routing, observability in each service. Too much duplication.

## Related ADRs

- ADR-004: Kubernetes for Orchestration
- ADR-019: OAuth 2.0 + OPA for Auth

## References

- [Istio Documentation](https://istio.io/latest/docs/)
- [Istio Ambient Mesh](https://istio.io/latest/docs/ambient/)
- [Service Mesh Patterns](https://www.oreilly.com/library/view/service-mesh-patterns/9781492086444/)
