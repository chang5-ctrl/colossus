# ADR-016: Content-Addressable Storage for Generated Artifacts

**Status:** Accepted  
**Date:** 2026-07-09  
**Deciders:** Chief Architect, Storage Lead  
**Category:** Data

## Context

Colossus generates millions of artifacts (SDKs, docs, tests). Many artifacts are identical across versions or APIs.

Requirements:
- Deduplication: Don't store the same artifact twice
- Integrity: Verify artifact hasn't been tampered with
- Reproducibility: Same inputs always produce same output
- Efficient storage: Minimize storage costs
- Fast retrieval: O(1) lookup by content hash

## Decision

Use content-addressable storage (CAS) for all generated artifacts.

Key decisions:
- Store artifacts by their cryptographic hash (SHA-256)
- Object key = `artifacts/{sha256_prefix}/{sha256}`
- Metadata database stores mapping: `(api_id, version, artifact_type) → sha256`
- Deduplication: Identical artifacts share the same storage object
- Integrity: Hash verification on read and write
- Reproducibility: Deterministic generation ensures same hash for same inputs

Storage Layout:
```
artifacts/
  ├── ab/                    # First 2 chars of SHA-256
  │   └── cd/                # Next 2 chars
  │       └── ef1234...      # Full SHA-256
  ├── 12/
  │   └── 34/
  │       └── 5678ab...
  └── ...
```

Benefits:
- Natural deduplication
- Immutable artifacts (can't modify without changing hash)
- Cache-friendly (hash as cache key)
- Git-like content addressing

Integration:
- S3 for blob storage
- CockroachDB for metadata (API → hash mappings)
- Redis for hot cache

## Consequences

### Positive

- Deduplication: Saves storage for identical artifacts
- Integrity: Cryptographic verification
- Immutability: Artifacts can't be accidentally modified
- Caching: Hash is perfect cache key
- Reproducibility: Foundation for reproducible builds

### Negative

- Complexity: Requires metadata layer for human-readable names
- Hash collisions: Theoretically possible with SHA-256 (practically impossible)
- Garbage collection: Orphaned artifacts need periodic cleanup
- Listing: Hard to list all artifacts for an API (requires metadata DB)

## Alternatives Considered

### UUID-based naming
Rejected: No deduplication, no integrity verification.

### Git LFS
Rejected: Good for version control but not suitable for high-throughput artifact storage.

### IPFS
Rejected: Decentralized but adds unnecessary complexity. S3 is sufficient.

## Related ADRs

- ADR-008: S3 for Object Storage
- ADR-006: CockroachDB for Metadata

## References

- [Content-Addressable Storage](https://en.wikipedia.org/wiki/Content-addressable_storage)
- [Git Internals](https://git-scm.com/book/en/v2/Git-Internals-Git-Objects)
- [CAS Systems](https://blog.bazel.build/2017/03/10/introducing-remote-caching.html)
