# ADR-008: S3-Compatible Object Storage for Artifacts and Blobs

**Status:** Accepted  
**Date:** 2026-07-09  
**Deciders:** Chief Architect, Storage Lead  
**Category:** Data

## Context

Colossus generates millions of files (SDKs, docs, tests, examples) totaling petabytes of data.
This data must be:
- Durable (99.999999999% durability)
- Available (99.99% availability)
- Cost-effective (tiered storage)
- Globally accessible (CDN integration)
- Versioned (keep history of generated artifacts)
- Queryable (analytics, search indexing)

## Decision

Use S3-compatible object storage as the primary blob store.

Key decisions:
- Primary: AWS S3 (or cloud provider equivalent)
- Backup: Cross-region replication
- Cold storage: S3 Glacier for old versions
- Interface: S3 API (de facto standard)
- Versioning: Enabled on all buckets
- Encryption: Server-side encryption (AES-256)
- Access: IAM policies + signed URLs

Bucket Structure:
```
colossus-artifacts/
  ├── sdks/{api_id}/{version}/{language}/
  ├── docs/{api_id}/{version}/
  ├── tests/{api_id}/{version}/{language}/
  ├── examples/{api_id}/{version}/{language}/
  ├── specs/{api_id}/{version}/
  ├── backups/{date}/
  └── analytics/{date}/
```

Lifecycle Policies:
- Current versions: Standard storage
- Versions > 1 year: Infrequent Access
- Versions > 3 years: Glacier
- Versions > 10 years: Delete (configurable)

## Consequences

### Positive

- Durability: 11 nines durability
- Scalability: Effectively unlimited
- Cost: Very low per GB, tiered pricing
- Standard: S3 API is the de facto standard
- Integration: Works with CDNs, analytics tools, backup tools
- Versioning: Built-in object versioning

### Negative

- Latency: Higher than block storage for small, frequent accesses
- Cost: Egress charges for data transfer
- Complexity: Lifecycle policies, IAM, cross-region replication
- Vendor lock-in: API is standard but features vary by provider

## Alternatives Considered

### Distributed Filesystem (Ceph, MinIO)
Rejected: Would be considered for on-prem or multi-cloud deployments. S3 is the standard.

### NFS
Rejected: Not scalable, not durable enough for this scale.

### Database Blobs
Rejected: Databases are not designed for petabyte-scale blob storage.

## Related ADRs

- ADR-006: CockroachDB for Metadata
- ADR-007: Redis for Caching
- ADR-025: CDN Strategy

## References

- [AWS S3 Documentation](https://docs.aws.amazon.com/s3/)
- [S3 API Specification](https://docs.aws.amazon.com/AmazonS3/latest/API/Welcome.html)
- [MinIO](https://min.io/) (S3-compatible open source)
