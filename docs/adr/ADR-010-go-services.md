# ADR-010: Go for Service Implementation

**Status:** Accepted  
**Date:** 2026-07-09  
**Deciders:** Chief Architect, Language Lead  
**Category:** Engineering

## Context

Colossus has 28+ services that need:
- Fast compilation and deployment
- Efficient concurrency (goroutines)
- Strong standard library
- Excellent gRPC support
- Good developer productivity
- Large hiring pool

## Decision

Use Go for the majority of microservices:

Go Services:
- API Registry
- Metadata Database service layer
- Search Engine service layer
- Scheduler
- CI/CD Coordinator
- Release Manager
- Package Publisher
- Version Monitor
- API Change Detection
- Auth Framework
- Public Website backend
- Monitoring Stack collectors
- Analytics Platform ETL

Go Libraries:
- `libs/utils` — Common utilities
- `libs/config` — Configuration management
- `libs/observability` — Metrics, logging, tracing
- `libs/events` — Event publishing/consuming
- `libs/storage` — Storage abstractions

Tooling:
- Go modules for dependency management
- golangci-lint for linting
- gofmt for formatting
- go test for testing
- pprof for profiling

## Consequences

### Positive

- Productivity: Fast compilation, simple syntax
- Concurrency: Goroutines and channels are excellent for I/O-bound services
- Standard library: Comprehensive, well-designed
- gRPC: First-class support
- Ecosystem: Massive, mature
- Hiring: Large talent pool

### Negative

- GC: Pause times are generally low but can spike
- Generics: Added in Go 1.18, ecosystem still adapting
- Error handling: Verbose compared to other languages
- Dependency management: Modules work well but have edge cases

## Alternatives Considered

### Java
Rejected: JVM startup time and memory footprint are concerns. Go compiles to a single binary.

### Node.js
Rejected: Single-threaded event loop is a bottleneck for CPU-bound tasks. Type safety is weaker.

### Python
Rejected: GIL limits concurrency. Better suited for data/ML tasks.

## Related ADRs

- ADR-009: Rust for Performance-Critical Components
- ADR-011: Python for Data/ML

## References

- [Effective Go](https://go.dev/doc/effective_go)
- [Go Code Review Comments](https://github.com/golang/go/wiki/CodeReviewComments)
- [Uber Go Style Guide](https://github.com/uber-go/guide/blob/master/style.md)
