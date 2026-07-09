# ADR-028: Multi-Region Disaster Recovery Strategy

**Status:** Accepted  
**Date:** 2026-07-09  
**Deciders:** Chief Architect, SRE Lead  
**Category:** Operations

## Context

Colossus must survive:
- Single region outages
- Database corruption
- Kafka cluster failures
- Worker pool failures
- CDN failures
- Human error (accidental deletion)

Recovery targets:
- RPO (Recovery Point Objective): Minimal data loss
- RTO (Recovery Time Objective): Fast recovery

## Decision

Implement a comprehensive disaster recovery strategy:

## Multi-Region Deployment
- Primary region: Full deployment (read + write)
- Secondary regions: Read replicas + worker pools
- Tertiary region: Backup only (cold standby)

## Data Protection

| System | Backup Strategy | RPO | RTO |
|--------|----------------|-----|-----|
| CockroachDB | Continuous backup + PITR | 0 | 1 hour |
| S3 | Versioning + cross-region replication | 0 | 1 hour |
| Kafka | MirrorMaker 2 + compaction | 1 hour | 2 hours |
| Redis | AOF + RDB snapshots | 1 hour | 30 minutes |
| Neo4j | Online backup every 6 hours | 6 hours | 2 hours |
| OpenSearch | Snapshot to S3 every 6 hours | 6 hours | 2 hours |

## Runbooks
- Automated runbooks for common failures
- Playbooks for manual intervention
- Regular disaster recovery drills (quarterly)
- Chaos engineering for resilience testing

## Monitoring
- RPO/RTO dashboards
- Backup health monitoring
- Replication lag alerts
- Failover automation

## Consequences

### Positive

- Resilience: Survives region-level failures
- Data protection: Minimal data loss
- Automation: Reduces human error during recovery
- Confidence: Regular drills ensure readiness

### Negative

- Cost: Multi-region deployment is expensive
- Complexity: More infrastructure to manage
- Latency: Cross-region replication adds latency
- Testing: DR drills are time-consuming

## Alternatives Considered

### Single region with backups
Rejected: Would have hours of downtime for region outage.

### Active-active multi-region
Rejected: Complex, expensive. Active-passive is sufficient for current needs.

### Cloud provider DR services
Rejected: Vendor lock-in. Must be cloud-agnostic.

## Related ADRs

- ADR-004: Kubernetes for Orchestration
- ADR-006: CockroachDB for Metadata
- ADR-008: S3 for Object Storage

## References

- [Google SRE Book: Emergency Response](https://sre.google/sre-book/emergency-response/)
- [AWS Well-Architected: Reliability Pillar](https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/welcome.html)
- [Chaos Engineering](https://principlesofchaos.org/)
