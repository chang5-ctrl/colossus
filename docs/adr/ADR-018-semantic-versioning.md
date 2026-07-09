# ADR-018: Semantic Versioning for All Artifacts

**Status:** Accepted  
**Date:** 2026-07-09  
**Deciders:** Chief Architect, Release Engineering Lead  
**Category:** Engineering

## Context

Colossus generates SDKs, documentation, and other artifacts that are consumed by developers.
These artifacts need clear versioning to communicate:
- Breaking changes
- New features
- Bug fixes
- Compatibility with upstream API versions

## Decision

Use Semantic Versioning (SemVer) 2.0.0 for all generated artifacts.

Key decisions:
- `MAJOR.MINOR.PATCH` format
- MAJOR: Breaking changes (API schema changes, removed endpoints)
- MINOR: New features (new endpoints, new optional parameters)
- PATCH: Bug fixes (documentation corrections, generated code fixes)
- Pre-release versions: `1.0.0-alpha.1`, `1.0.0-beta.2`
- Build metadata: `1.0.0+build.123` (not used in version resolution)

Version Mapping:
- Generated SDK version maps to upstream API version
- If upstream API is `v2.1.3`, generated SDK might be `2.1.3` or `2.1.3-colossus.1`
- Colossus generator version is separate (e.g., `colossus-gen-v1.2.3`)

Version Sources:
- Upstream API version (from spec or endpoint)
- Colossus generator version (from generator binary)
- Template version (from template repository)
- Combined into final artifact version

Changelog:
- Automatically generated from API diffs
- Breaking changes highlighted
- Migration guides generated for major version bumps

## Consequences

### Positive

- Clarity: Users understand impact of upgrading
- Compatibility: Version constraints work with package managers
- Automation: CI can detect breaking changes and bump versions
- Trust: Users can pin to specific versions

### Negative

- Complexity: Must accurately detect breaking vs non-breaking changes
- Upstream dependency: If upstream doesn't use SemVer, must infer version
- Version explosion: Many APIs × many languages = many versions
- Maintenance: Must maintain compatibility matrices

## Alternatives Considered

### Calendar versioning (CalVer)
Rejected: Doesn't communicate breaking changes. Better for applications than libraries.

### Hash-based versioning
Rejected: Not human-readable. Package managers don't support it well.

### Upstream-only versioning
Rejected: Doesn't account for generator changes that affect output.

## Related ADRs

- ADR-017: Deterministic Code Generation
- ADR-016: Content-Addressable Storage

## References

- [Semantic Versioning 2.0.0](https://semver.org/)
- [Keep a Changelog](https://keepachangelog.com/)
- [Conventional Commits](https://www.conventionalcommits.org/)
