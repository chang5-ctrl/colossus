# ADR-015: Bazel for Monorepo Build System

**Status:** Accepted  
**Date:** 2026-07-09  
**Deciders:** Chief Architect, Build Engineering Lead  
**Category:** Engineering

## Context

Colossus is a monorepo with:
- 28+ services in multiple languages (Rust, Go, Python)
- Shared libraries used across services
- Generated code that must be reproducible
- Millions of files in artifacts/
- Need for fast, incremental builds
- Need for hermetic, reproducible builds
- Need for remote caching and execution

## Decision

Use Bazel as the monorepo build system.

Key decisions:
- Bazel 7.x with bzlmod for dependency management
- Remote build execution (RBE) for distributed builds
- Remote caching for build artifact sharing
- Hermetic builds (pinned dependencies, fixed toolchains)
- Reproducible builds (same inputs → same outputs)

Build Targets:
- `//services/<name>` — Service binaries and Docker images
- `//libs/<name>` — Shared libraries
- `//tools/<name>` — CLI tools and scripts
- `//tests/...` — Test suites
- `//infra/...` — Infrastructure definitions

Languages:
- rules_rust for Rust
- rules_go for Go
- rules_python for Python
- rules_docker for Docker images
- rules_k8s for Kubernetes manifests
- rules_proto for Protocol Buffers

CI Integration:
- Bazel CI for continuous integration
- Build event protocol for metrics
- Test result streaming to dashboards

## Consequences

### Positive

- Speed: Incremental builds, parallel execution, remote caching
- Hermeticity: Reproducible builds, no "works on my machine"
- Scalability: Proven at Google scale (billions of lines of code)
- Multi-language: Single build system for all languages
- Remote execution: Distribute builds across many machines
- Caching: Share build artifacts across CI and developers

### Negative

- Learning curve: Complex configuration language (Starlark)
- Setup: Requires careful toolchain configuration
- IDE support: Good but not as mature as language-specific tools
- Build file maintenance: Must keep BUILD files in sync with code

## Alternatives Considered

### Nx
Rejected: TypeScript-focused. Not suitable for Rust/Go/Python monorepo.

### Pants
Rejected: Good for Python but less mature for Rust and Go.

### Buck2
Rejected: Meta's build system, promising but smaller community than Bazel.

### Language-specific tools (Cargo, Go modules, Poetry)
Rejected: Would fragment the build system. Bazel provides unified builds.

## Related ADRs

- ADR-009: Rust for Performance-Critical Components
- ADR-010: Go for Services
- ADR-011: Python for Data/ML

## References

- [Bazel Documentation](https://bazel.build/docs)
- [Bazel Best Practices](https://bazel.build/docs/best-practices)
- [Bazel at Google Scale](https://research.google/pubs/pub43438/)
