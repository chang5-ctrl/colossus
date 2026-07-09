# ADR-017: Deterministic Code Generation

**Status:** Accepted  
**Date:** 2026-07-09  
**Deciders:** Chief Architect, Code Generation Lead  
**Category:** Engineering

## Context

Colossus generates billions of lines of code. For this to be maintainable:
- Same inputs must produce same outputs (reproducibility)
- Changes must be detectable via diff (auditability)
- Generated code must be auditable by humans
- Build systems must cache generated artifacts
- Content-addressable storage must work

## Decision

All code generation must be deterministic.

Key decisions:
- Same API spec + same generator version + same template = same output
- No non-deterministic elements (random IDs, timestamps, ordering)
- If timestamps are needed, they are derived from the API spec version
- Sort all collections before generation (maps, sets, lists)
- Use stable hashing for identifiers
- Pin all dependencies (generator version, template version, toolchain version)

Implementation:
- Generators sort all schema properties alphabetically
- Generators use deterministic naming (no random suffixes)
- Generators use stable import ordering
- Build system (Bazel) enforces hermeticity
- CI verifies determinism (generate twice, compare hashes)

Verification:
- `colossus validate-determinism --api <id> --version <version>`
- Compares SHA-256 of two generation runs
- Fails if hashes differ

Benefits:
- Content-addressable storage works
- Diff-based change detection
- Reproducible builds
- Confidence in generation correctness
- Efficient caching

## Consequences

### Positive

- Reproducibility: Same inputs always produce same outputs
- Auditability: Changes are visible in diffs
- Caching: Build systems can cache generated code
- Storage efficiency: Content-addressable deduplication
- Testing: Easy to verify generation correctness

### Negative

- Constraints: Some language features are inherently non-deterministic (e.g., random UUID generation)
- Complexity: Must carefully design generators to avoid non-determinism
- Timestamps: Can't include build timestamps in generated code
- Ordering: Must sort everything, which may not match human expectations

## Alternatives Considered

### Non-deterministic generation
Rejected: Would break content-addressable storage, caching, and auditability.

### Timestamp-based versioning
Rejected: Would cause unnecessary changes on every generation.

### Hash-based but with noise
Rejected: Any non-determinism defeats the purpose.

## Related ADRs

- ADR-016: Content-Addressable Storage
- ADR-015: Bazel for Build System

## References

- [Reproducible Builds](https://reproducible-builds.org/)
- [Deterministic Compilation](https://en.wikipedia.org/wiki/Deterministic_compilation)
- [Bazel Hermeticity](https://bazel.build/concepts/hermeticity)
