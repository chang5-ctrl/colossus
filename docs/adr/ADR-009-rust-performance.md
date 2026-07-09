# ADR-009: Rust for Performance-Critical Components

**Status:** Accepted  
**Date:** 2026-07-09  
**Deciders:** Chief Architect, Language Lead  
**Category:** Engineering

## Context

Colossus has performance-critical paths that must handle:
- Parsing millions of API specifications
- Generating billions of lines of code
- Validating artifacts at high throughput
- Processing Kafka streams with low latency

These components need:
- Zero-cost abstractions
- Memory safety without GC pauses
- High concurrency
- Deterministic performance

## Decision

Use Rust for performance-critical components:

Rust Services:
- SDK Generator core (AST manipulation, code generation)
- Validation Engine (static analysis, compilation)
- Discovery Engine (web crawling, spec parsing)
- Queue consumers (Kafka consumers for high-throughput topics)
- API Gateway (Envoy extensions, custom filters)

Rust Libraries:
- `libs/codegen` — Code generation engine
- `libs/protocols` — Protocol parsers (OpenAPI, GraphQL, gRPC, etc.)
- `libs/core` — Core abstractions and utilities

Tooling:
- Cargo for dependency management
- Clippy for linting
- Rustfmt for formatting
- cargo-audit for security scanning
- criterion.rs for benchmarking

## Consequences

### Positive

- Performance: Zero-cost abstractions, no GC pauses
- Safety: Memory safety guaranteed at compile time
- Concurrency: Fearless concurrency with ownership model
- Ecosystem: Excellent for systems programming, networking, parsing
- Determinism: Predictable performance characteristics

### Negative

- Learning curve: Steep for developers new to Rust
- Compile times: Slower than Go or Python
- Ecosystem: Smaller than JavaScript/Python for some domains
- Hiring: Smaller talent pool

## Alternatives Considered

### C++
Rejected: Performance is excellent but memory safety is a major concern at this scale. Rust provides similar performance with safety guarantees.

### Go
Rejected: Excellent for services but GC pauses are unacceptable for high-throughput stream processing and code generation.

### Java
Rejected: JVM warm-up time and GC pauses are concerns. Rust provides predictable latency.

## Related ADRs

- ADR-010: Go for Services
- ADR-011: Python for Data/ML

## References

- [The Rust Programming Language](https://doc.rust-lang.org/book/)
- [Rust API Guidelines](https://rust-lang.github.io/api-guidelines/)
- [Rust Performance Book](https://nnethercote.github.io/perf-book/)
