# Disaster Recovery Strategy

> Hope is not a strategy. We plan for failure, test recovery, and measure readiness.

## Philosophy

Disaster recovery is not a document. It is a practice.

1. **Assume failure:** Every component will fail eventually
2. **Test recovery:** DR drills are not optional
3. **Measure readiness:** RPO and RTO are measured, not estimated
4. **Automate everything:** Manual recovery is too slow and error-prone
5. **Practice regularly:** Quarterly game days, monthly DR drills

## Definitions

| Term | Definition | Colossus Target |
|------|-----------|-----------------|
| **RPO** (Recovery Point Objective) | Maximum acceptable data loss | 0 for critical data, 1 hour for events |
| **RTO** (Recovery Time Objective) | Maximum acceptable downtime | 1 hour for core services, 4 hours for workers |
| **MTTR** (Mean Time to Repair) | Average time to recover | < 1 hour for P0 incidents |
| **MTTD** (Mean Time to Detect) | Average time to detect failure | < 5 minutes |

## Multi-Region Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Global Load Balancer                         │
│                    (Route 53 + Health Checks)                        │
└─────────────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┼───────────────┐
              ▼               ▼               ▼
    ┌─────────────────┐ ┌─────────────┐ ┌─────────────┐
    │   us-east-1     │ │  us-west-2  │ │ eu-west-1   │
    │   (Primary)     │ │ (Secondary) │ │ (Secondary) │
    │                 │ │             │ │             │
    │ ┌─────────────┐ │ │ ┌─────────┐ │ │ ┌─────────┐ │
    │ │  K8s Cluster │ │ │ │ K8s     │ │ │ │ K8s     │ │
    │ │  (Full)      │ │ │ │ (Read)  │ │ │ │ (Read)  │ │
    │ │              │ │ │ │         │ │ │ │         │ │
    │ │ Services     │ │ │ │ Services│ │ │ │ Services│ │
    │ │ Workers      │ │ │ │ Workers │ │ │ │ Workers │ │
    │ │ Databases    │ │ │ │ DB Replicas│ │ │ DB Replicas│ │
    │ └─────────────┘ │ │ └─────────┘ │ │ └─────────┘ │
    │                 │ │             │ │             │
    │ ┌─────────────┐ │ │ ┌─────────┐ │ │ ┌─────────┐ │
    │ │  S3 (Primary)│ │ │ │ S3     │ │ │ │ S3     │ │ │
    │ │  + Versioning│ │ │ (Replica)│ │ │ (Replica)│ │ │
    │ └─────────────┘ │ │ └─────────┘ │ │ └─────────┘ │
    └─────────────────┘ └─────────────┘ └─────────────┘
```

**Region Roles:**

| Region | Role | Write | Read | Failover Priority |
|--------|------|-------|------|-------------------|
| us-east-1 | Primary | Yes | Yes | 1 (default) |
| us-west-2 | Secondary | No (async) | Yes | 2 |
| eu-west-1 | Secondary | No (async) | Yes | 3 |
| ap-southeast-1 | Tertiary | No | No (cold) | 4 |

## Data Protection Matrix

| System | Primary Store | Backup Strategy | RPO | RTO | Cross-Region | Encryption |
|--------|--------------|-----------------|-----|-----|-------------|------------|
| **API Metadata** | CockroachDB | Continuous backup + PITR | 0 | 1h | Sync replication | AES-256 |
| **API Specs** | S3 | Versioning + replication | 0 | 1h | Cross-region replication | AES-256 |
| **Generated Artifacts** | S3 | Versioning + replication | 0 | 4h | Cross-region replication | AES-256 |
| **Events** | Kafka | MirrorMaker 2 + compaction | 1h | 2h | MirrorMaker 2 | TLS 1.3 |
| **Metrics** | Prometheus + Thanos | Object store snapshots | 24h | 4h | Thanos global query | AES-256 |
| **Logs** | Loki | S3 export | 24h | 4h | S3 cross-region | AES-256 |
| **Traces** | Jaeger | S3 export | 24h | 4h | S3 cross-region | AES-256 |
| **Knowledge Graph** | Neo4j | Online backup every 6h | 6h | 2h | Backup to S3 | AES-256 |
| **Search Index** | OpenSearch | Snapshot every 6h | 6h | 2h | Snapshot to S3 | AES-256 |
| **Cache** | Redis | AOF + RDB snapshots | 1h | 30min | Reconstruct from DB | AES-256 |
| **Config** | Git + ConfigMap | Git history | 0 | 15min | Git remote | — |

## Backup Procedures

### CockroachDB Backup

**Full Backup (Daily):**
```sql
BACKUP INTO 's3://colossus-backups/cockroachdb/full/{date}?AWS_ACCESS_KEY_ID=...&AWS_SECRET_ACCESS_KEY=...'
  AS OF SYSTEM TIME '-10s'
  WITH revision_history;
```

**Incremental Backup (Every 6 hours):**
```sql
BACKUP INTO LATEST IN 's3://colossus-backups/cockroachdb/full/'
  AS OF SYSTEM TIME '-10s'
  WITH revision_history;
```

**Point-in-Time Recovery (PITR):**
```sql
RESTORE DATABASE colossus FROM 's3://colossus-backups/cockroachdb/full/'
  AS OF SYSTEM TIME '2026-07-09 10:00:00';
```

**Backup Retention:**
- Daily full backups: 30 days
- Incremental backups: 7 days
- PITR capability: 30 days
- Archive backups: 1 year (monthly)

### S3 Backup

**Configuration:**
```json
{
  "VersioningConfiguration": {
    "Status": "Enabled"
  },
  "ReplicationConfiguration": {
    "Role": "arn:aws:iam::account:role/s3-replication",
    "Rules": [
      {
        "Status": "Enabled",
        "Priority": 1,
        "DeleteMarkerReplication": { "Status": "Enabled" },
        "Destination": {
          "Bucket": "arn:aws:s3:::colossus-artifacts-backup-us-west-2"
        }
      }
    ]
  },
  "LifecycleConfiguration": {
    "Rules": [
      {
        "Status": "Enabled",
        "Transitions": [
          { "Days": 30, "StorageClass": "STANDARD_IA" },
          { "Days": 90, "StorageClass": "GLACIER" }
        ],
        "NoncurrentVersionTransitions": [
          { "NoncurrentDays": 30, "StorageClass": "STANDARD_IA" },
          { "NoncurrentDays": 90, "StorageClass": "GLACIER" }
        ]
      }
    ]
  }
}
```

### Kafka Backup

**MirrorMaker 2 Configuration:**
```properties
# Source cluster
source.cluster.bootstrap.servers=kafka-us-east-1:9092
source.cluster.security.protocol=SASL_SSL

# Target cluster (secondary)
target.cluster.bootstrap.servers=kafka-us-west-2:9092
target.cluster.security.protocol=SASL_SSL

# Replication
topics=.*
groups=.*
replication.factor=3
sync.topic.configs.enabled=true
sync.topic.acls.enabled=true
```

**Topic Retention:**
- Operational topics: 7 days
- Audit topics: 30 days (compacted)
- Event sourcing topics: Forever (compacted)

### Neo4j Backup

**Online Backup:**
```bash
neo4j-admin backup --from=neo4j-us-east-1:6362 \
  --backup-dir=/backups/neo4j \
  --database=neo4j \
  --type=FULL \
  --check-consistency=true
```

**Schedule:** Every 6 hours
**Retention:** 7 days locally, 30 days in S3

### OpenSearch Backup

**Snapshot Repository:**
```json
PUT /_snapshot/colossus-backups
{
  "type": "s3",
  "settings": {
    "bucket": "colossus-backups",
    "base_path": "opensearch",
    "region": "us-east-1",
    "compress": true
  }
}
```

**Snapshot Schedule:** Every 6 hours (incremental), daily (full)
**Retention:** 7 snapshots locally, 30 days in S3

## Recovery Procedures

### Scenario 1: Single Service Failure

**Impact:** One service (e.g., discovery-engine) is down
**RTO:** 5 minutes
**RPO:** 0

**Recovery Steps:**
1. **Detection:** Kubernetes liveness probe fails, alert fires
2. **Automatic:** Kubernetes restarts pod (self-healing)
3. **Verification:** Health check passes, traffic resumes
4. **Investigation:** Check logs for root cause
5. **Prevention:** Fix bug, deploy new version

**Runbook:**
```bash
# Check pod status
kubectl get pods -n colossus -l app=discovery-engine

# Check logs
kubectl logs -n colossus -l app=discovery-engine --tail=100

# Restart deployment
kubectl rollout restart deployment/discovery-engine -n colossus

# Verify
kubectl rollout status deployment/discovery-engine -n colossus
```

### Scenario 2: Database Corruption

**Impact:** CockroachDB data is corrupted
**RTO:** 1 hour
**RPO:** 0 (with PITR)

**Recovery Steps:**
1. **Detection:** Database errors, consistency check failures
2. **Stop writes:** Pause all write operations
3. **Assess damage:** Identify corrupted ranges
4. **Restore from backup:** Use PITR to restore to last known good state
5. **Verify:** Run consistency checks
6. **Resume:** Gradually resume traffic
7. **Investigate:** Root cause analysis

**Runbook:**
```bash
# 1. Stop writes (circuit break)
kubectl patch configmap colossus-config -n colossus \
  --patch '{"data":{"COLOSSUS_READ_ONLY":"true"}}'

# 2. Identify corrupted ranges
cockroach sql --host=cockroachdb:26257 \
  --execute "SELECT * FROM crdb_internal.check_consistency(true, '', '');"

# 3. Restore from backup
cockroach sql --host=cockroachdb:26257 \
  --execute "RESTORE DATABASE colossus FROM 's3://colossus-backups/cockroachdb/full/' AS OF SYSTEM TIME '2026-07-09 08:00:00';"

# 4. Verify consistency
cockroach sql --host=cockroachdb:26257 \
  --execute "SELECT * FROM crdb_internal.check_consistency(true, '', '');"

# 5. Resume writes
kubectl patch configmap colossus-config -n colossus \
  --patch '{"data":{"COLOSSUS_READ_ONLY":"false"}}'
```

### Scenario 3: Primary Region Outage

**Impact:** us-east-1 is completely unavailable
**RTO:** 1 hour
**RPO:** 0 for metadata, 1 hour for events

**Recovery Steps:**
1. **Detection:** Health checks fail, Route 53 marks region unhealthy
2. **Automatic failover:** Traffic routes to us-west-2
3. **Promote secondary:** Promote us-west-2 CockroachDB to primary
4. **Verify reads:** Confirm read operations work
5. **Assess data loss:** Check replication lag
6. **Resume writes:** Enable writes from us-west-2
7. **Investigate:** Root cause of region outage
8. **Restore primary:** When us-east-1 recovers, restore as secondary

**Runbook:**
```bash
# 1. Verify failover
kubectl --context=us-west-2 get pods -n colossus

# 2. Promote CockroachDB secondary
cockroach sql --host=cockroachdb-us-west-2:26257 \
  --execute "ALTER DATABASE colossus PRIMARY REGION 'us-west-2';"

# 3. Verify replication lag
cockroach sql --host=cockroachdb-us-west-2:26257 \
  --execute "SELECT * FROM crdb_internal.kv_node_status;"

# 4. Update DNS
aws route53 change-resource-record-sets \
  --hosted-zone-id Z123456789 \
  --change-batch '{"Changes":[{"Action":"UPSERT","ResourceRecordSet":{"Name":"api.colossus.io","Type":"A","TTL":60,"ResourceRecords":[{"Value":"us-west-2-lb-ip"}]}}]}'

# 5. Verify traffic
kubectl --context=us-west-2 logs -n colossus -l app=api-gateway --tail=100
```

### Scenario 4: Kafka Cluster Failure

**Impact:** Message queue is unavailable
**RTO:** 2 hours
**RPO:** 1 hour (messages in MirrorMaker 2 lag)

**Recovery Steps:**
1. **Detection:** Producer errors, consumer lag spikes
2. **Switch to secondary:** Route producers to us-west-2 Kafka
3. **Assess data loss:** Check replication lag
4. **Rebuild primary:** When primary recovers, restore from backups
5. **Reconcile:** Merge any divergent messages

**Runbook:**
```bash
# 1. Check cluster health
kafka-broker-api-versions --bootstrap-server kafka-us-east-1:9092

# 2. Switch to secondary
kubectl patch configmap colossus-config -n colossus \
  --patch '{"data":{"KAFKA_BROKERS":"kafka-us-west-2:9092"}}'

# 3. Restart services with new config
kubectl rollout restart deployment/discovery-engine -n colossus
kubectl rollout restart deployment/sdk-generator -n colossus

# 4. Check replication lag
kafka-consumer-groups --bootstrap-server kafka-us-west-2:9092 \
  --describe --group mirror-maker-2
```

### Scenario 5: Ransomware / Malicious Data Deletion

**Impact:** Data is encrypted or deleted by attacker
**RTO:** 4 hours
**RPO:** 0 (with immutable backups)

**Recovery Steps:**
1. **Detection:** Unusual deletion patterns, encryption activity
2. **Isolate:** Cut off attacker access, revoke credentials
3. **Assess scope:** Identify affected data
4. **Restore from immutable backups:** S3 Object Lock prevents deletion
5. **Verify integrity:** Checksums, consistency checks
6. **Resume:** Gradual traffic restoration
7. **Investigate:** Forensic analysis, security review

**Immutable Backup Configuration:**
```json
{
  "ObjectLockConfiguration": {
    "ObjectLockEnabled": "Enabled",
    "Rule": {
      "DefaultRetention": {
        "Mode": "GOVERNANCE",
        "Days": 30
      }
    }
  }
}
```

### Scenario 6: Complete Platform Destruction

**Impact:** All infrastructure is destroyed
**RTO:** 4 hours
**RPO:** 0 for metadata, 1 hour for events

**Recovery Steps:**
1. **Provision new infrastructure:** Terraform apply to new region
2. **Restore databases:** From latest backups
3. **Restore object storage:** S3 cross-region replication
4. **Restore Kafka:** From MirrorMaker 2
5. **Restore search index:** Rebuild from database
6. **Restore knowledge graph:** Rebuild from database
7. **Verify:** Full system health check
8. **Resume traffic:** Gradual cutover

**Runbook:**
```bash
# 1. Provision infrastructure
cd infra/terraform
terraform init
terraform workspace new disaster-recovery
terraform apply -var="region=ap-southeast-1"

# 2. Restore databases
cockroach sql --host=cockroachdb-new:26257 \
  --execute "RESTORE DATABASE colossus FROM 's3://colossus-backups/cockroachdb/full/';"

# 3. Verify object storage
aws s3 ls s3://colossus-artifacts-backup-ap-southeast-1/

# 4. Deploy services
kubectl apply -k infra/kustomize/overlays/disaster-recovery

# 5. Verify health
for service in discovery-engine sdk-generator api-registry; do
  kubectl wait --for=condition=available --timeout=300s deployment/$service -n colossus
done

# 6. Run smoke tests
bazel test //tests/e2e/smoke/...
```

## DR Drills

### Schedule

| Drill Type | Frequency | Scope | Duration |
|-----------|-----------|-------|----------|
| **Tabletop** | Monthly | Single scenario, discussion only | 1 hour |
| **Functional** | Quarterly | Single service recovery | 2 hours |
| **Full DR** | Bi-annually | Complete region failover | 4 hours |
| **Chaos** | Weekly | Random failure injection | 1 hour |
| **Game Day** | Quarterly | Simulated major incident | Full day |

### Drill Process

1. **Planning:** Define scenario, success criteria, abort conditions
2. **Notification:** Inform team (not users for functional drills)
3. **Execution:** Run the drill, document everything
4. **Measurement:** Measure actual RPO and RTO
5. **Review:** Post-mortem, identify gaps
6. **Improvement:** Update runbooks, fix issues
7. **Report:** Report to leadership

### Drill Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Actual RPO | <= Target RPO | Data loss measured during drill |
| Actual RTO | <= Target RTO | Downtime measured during drill |
| Recovery Success Rate | 100% | % of drills that succeed |
| Runbook Accuracy | 100% | % of steps that work as documented |
| Team Confidence | > 8/10 | Post-drill survey |

## Automation

### Automated Recovery

| Scenario | Automation Level | Implementation |
|----------|---------------|----------------|
| Pod restart | Fully automated | Kubernetes self-healing |
| Node failure | Fully automated | Kubernetes rescheduling |
| Service degradation | Semi-automated | Circuit breaker + auto-scaling |
| Database failover | Semi-automated | CockroachDB automatic failover |
| Region failover | Manual | Runbook + Terraform |
| Complete destruction | Manual | Runbook + Terraform |

### Recovery Automation Scripts

```bash
#!/bin/bash
# infra/scripts/dr-failover-region.sh
# Automated region failover script

set -euo pipefail

SOURCE_REGION="${1:-us-east-1}"
TARGET_REGION="${2:-us-west-2}"
ENVIRONMENT="${3:-production}"

echo "Initiating failover from $SOURCE_REGION to $TARGET_REGION..."

# 1. Verify target region health
echo "Checking target region health..."
kubectl --context=$TARGET_REGION get nodes

# 2. Update DNS
echo "Updating DNS..."
aws route53 change-resource-record-sets   --hosted-zone-id $(cat /secrets/route53-zone-id)   --change-batch file:///configs/failover-to-$TARGET_REGION.json

# 3. Promote database
echo "Promoting database in target region..."
cockroach sql --host=cockroachdb-$TARGET_REGION:26257   --execute "ALTER DATABASE colossus PRIMARY REGION '$TARGET_REGION';"

# 4. Verify
echo "Running verification..."
kubectl --context=$TARGET_REGION run smoke-test --rm -i   --restart=Never --image=curlimages/curl   -- curl -sf http://api-gateway.colossus:8080/health

echo "Failover complete!"
```

## Monitoring DR Health

### DR Dashboard

| Panel | Metric | Alert |
|-------|--------|-------|
| Backup Health | Last successful backup time | > 1 hour old |
| Replication Lag | Cross-region replication lag | > 5 minutes |
| RPO Compliance | Actual RPO vs target | Exceeds target |
| RTO Compliance | Actual RTO vs target | Exceeds target |
| DR Drill Status | Last drill date, result | > 3 months since last drill |
| Runbook Coverage | % of scenarios with runbooks | < 100% |

### Backup Verification

**Automated Backup Tests (Daily):**
```bash
#!/bin/bash
# infra/scripts/verify-backups.sh

# 1. Verify CockroachDB backup
latest_backup=$(aws s3 ls s3://colossus-backups/cockroachdb/full/ | tail -1)
aws s3 cp s3://colossus-backups/cockroachdb/full/$latest_backup /tmp/backup-test
# Restore to test cluster, run consistency checks

# 2. Verify S3 replication
aws s3api head-object --bucket colossus-artifacts-backup-us-west-2   --key test-object --expected-bucket-owner $(cat /secrets/aws-account-id)

# 3. Verify Kafka replication
kafka-consumer-groups --bootstrap-server kafka-us-west-2:9092   --describe --group mirror-maker-2

# 4. Report
# Send metrics to Prometheus, alert on failures
```

## Compliance & Auditing

### Audit Requirements

| Standard | Requirement | Implementation |
|----------|------------|----------------|
| **SOC 2 Type II** | Backup testing, recovery procedures | Quarterly drills, documented |
| **GDPR** | Right to deletion, data portability | Automated deletion workflows |
| **ISO 27001** | Business continuity planning | DR plan, testing, documentation |
| **PCI DSS** (if applicable) | Secure backup, recovery | Encryption, access controls |

### Audit Trail

All DR activities are logged:
- Backup creation and verification
- Restore operations
- Failover decisions
- Drill execution and results
- Runbook modifications

**Log Format:**
```json
{
  "timestamp": "2026-07-09T12:00:00Z",
  "event_type": "dr_drill_started",
  "drill_id": "drill-2026-07-09",
  "scenario": "primary_region_outage",
  "initiated_by": "sre-oncall@colossus.io",
  "target_rpo": "0",
  "target_rto": "1h",
  "environment": "staging"
}
```

## Cost Optimization

| Strategy | Savings | Implementation |
|----------|---------|---------------|
| Cold storage for old backups | 70% | S3 Glacier after 90 days |
| Selective replication | 50% | Only critical data cross-region |
| Compression | 30% | Zstd for backups, gzip for logs |
| Retention policies | 40% | Auto-delete old backups |
| Test environment sharing | 60% | Use staging for DR drills |

**Target:** DR infrastructure cost < 15% of total infrastructure cost

## Future Improvements

- [ ] **Automated region failover:** Reduce RTO to < 15 minutes
- [ ] **Continuous backup verification:** Real-time backup health
- [ ] **AI-assisted recovery:** Predict failures, suggest recovery actions
- [ ] **Immutable infrastructure:** Replace rather than repair
- [ ] **Multi-cloud DR:** AWS + GCP + Azure for ultimate resilience
- [ ] **Edge DR:** Local edge caches for critical content
- [ ] **Self-healing databases:** Automatic corruption detection and repair
- [ ] **Chaos as a service:** Continuous random failure injection

---

*This disaster recovery strategy is a living document. All changes require ADR review.*
