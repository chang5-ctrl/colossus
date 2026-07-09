# ADR-020: WebAssembly (WASM) for Plugin System

**Status:** Accepted  
**Date:** 2026-07-09  
**Deciders:** Chief Architect, Platform Engineering Lead  
**Category:** Architecture

## Context

Colossus needs a plugin system that allows:
- Custom generators for new languages
- Custom validators for domain-specific rules
- Custom publishers for private registries
- Custom discovery sources
- Custom metrics exporters
- Custom notification channels

Requirements:
- Language-agnostic (plugins in any language)
- Sandboxed (plugins can't crash the platform)
- Fast (low overhead)
- Versioned (plugins have their own lifecycle)
- Discoverable (plugin registry)

## Decision

Use WebAssembly (WASM) as the plugin runtime.

Key decisions:
- WASM runtime: Wasmtime (Bytecode Alliance, secure by default)
- WASI (WebAssembly System Interface) for sandboxed I/O
- Component Model for composable plugins
- Plugin registry: Git-backed with semantic versioning
- Plugin API: Defined via WIT (WASM Interface Types)

Plugin Types:
- `generator` — Custom code generators
- `validator` — Custom validation rules
- `publisher` — Custom package publishers
- `discovery` — Custom API discovery sources
- `exporter` — Custom metrics exporters
- `notifier` — Custom notification channels

Security:
- Sandboxed execution (no direct system calls)
- Resource limits (CPU, memory, execution time)
- Capability-based security (WASI capabilities)
- Code signing for plugin verification

Performance:
- Near-native performance (WASM is compiled to machine code)
- Fast instantiation (milliseconds)
- Shared-nothing architecture (no shared memory between plugins)

## Consequences

### Positive

- Language-agnostic: Plugins in Rust, Go, Python, C, etc.
- Sandboxed: Secure by default, no direct system access
- Fast: Near-native performance
- Portable: Runs anywhere WASM runtime is available
- Standard: Open standard, multiple implementations

### Negative

- Ecosystem: Still maturing, limited libraries
- Complexity: WASM compilation toolchain required for plugin authors
- Debugging: Harder to debug than native code
- I/O: WASI is still evolving, some I/O patterns are limited

## Alternatives Considered

### gRPC-based plugins
Rejected: Requires running separate processes, harder to sandbox, more resource overhead.

### Shared libraries (.so, .dll)
Rejected: Unsafe, can crash the host, platform-dependent.

### Lua
Rejected: Good for scripting but limited language support and ecosystem.

## Related ADRs

- ADR-021: Plugin System Architecture
- ADR-009: Rust for Performance-Critical Components

## References

- [WebAssembly](https://webassembly.org/)
- [Wasmtime](https://wasmtime.dev/)
- [WASI](https://wasi.dev/)
- [WASM Component Model](https://component-model.bytecodealliance.org/)
