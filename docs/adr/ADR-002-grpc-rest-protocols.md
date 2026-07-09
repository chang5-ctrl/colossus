# ADR-002: gRPC for Internal, REST for External Communication

**Status:** Accepted  
**Date:** 2026-07-09  
**Deciders:** Chief Architect, API Design Lead  
**Category:** Communication

## Context

Colossus services need to communicate efficiently internally while exposing APIs to external consumers (developers, CI systems, web UI).

Requirements:
- High-performance internal communication (binary protocol, streaming)
- Strong typing and schema evolution
- Wide language support (services in Rust, Go, Python)
- External APIs must be accessible from any HTTP client
- Browser compatibility for web UI

## Decision

Use gRPC for internal service-to-service communication and REST (HTTP/JSON) for external APIs.

Internal (gRPC):
- Protocol Buffers for schema definition
- HTTP/2 for transport
- Bidirectional streaming for real-time features
- gRPC-Gateway for REST translation where needed

External (REST):
- OpenAPI 3.1 specification for all external APIs
- JSON request/response format
- Standard HTTP methods and status codes
- Rate limiting and authentication at the gateway

All APIs are versioned in the URL path: `/v1/...`, `/v2/...`

Schema Registry:
- Confluent Schema Registry for Avro (Kafka messages)
- Buf Schema Registry for Protobuf (gRPC services)

## Consequences

### Positive

- gRPC performance: Binary serialization, HTTP/2 multiplexing, ~5-10x faster than REST
- Type safety: Protobuf schemas prevent runtime type errors
- Code generation: Client/server stubs generated from schemas
- Streaming: Real-time progress updates, log streaming
- REST accessibility: Any HTTP client can call external APIs
- Industry standard: Widely adopted, mature ecosystem

### Negative

- Complexity: Two protocols to maintain
- Tooling: gRPC tooling less mature than REST in some languages
- Debugging: Binary protocols harder to inspect than JSON
- Browser support: Requires gRPC-Web proxy for browser clients

## Alternatives Considered

### REST Only
Rejected: Would sacrifice internal performance. JSON parsing overhead is significant at scale.

### GraphQL
Rejected: Excellent for external APIs but adds unnecessary complexity for internal service communication. Would be considered for public API v2.

### tRPC
Rejected: TypeScript-only, not suitable for polyglot service architecture.

## Related ADRs

- ADR-001: Microservices Architecture
- ADR-003: Event-Driven Architecture
- ADR-019: Authentication Framework

## References

- [gRPC Documentation](https://grpc.io/docs/)
- [Protocol Buffers](https://protobuf.dev/)
- [OpenAPI Specification](https://spec.openapis.org/)
