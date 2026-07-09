# ADR-021: Plugin System Architecture

**Status:** Accepted  
**Date:** 2026-07-09  
**Deciders:** Chief Architect, Platform Engineering Lead  
**Category:** Architecture

## Context

Colossus needs a comprehensive plugin system that allows the community to extend the platform without modifying core code.

Extension points needed:
- Code generators for new programming languages
- Validators for custom quality gates
- Publishers for private or specialized package registries
- Discovery sources for niche API ecosystems
- Metrics exporters for custom observability stacks
- Notification channels (Slack, Discord, PagerDuty, etc.)
- Template sets for custom code generation styles

## Decision

Design a plugin system with the following architecture:

## Plugin Lifecycle

1. **Discovery:** Plugin registry (Git repository) lists available plugins
2. **Installation:** Plugin downloaded, verified (signature), installed
3. **Activation:** Plugin registered with the platform, capabilities declared
4. **Execution:** Plugin invoked via WASM runtime or gRPC
5. **Monitoring:** Plugin execution monitored, metrics collected
6. **Update:** Plugin updated via registry, rolling update
7. **Deprecation:** Plugin deprecated, users notified
8. **Removal:** Plugin uninstalled, resources cleaned up

## Plugin Registry

- Git repository: `colossus-plugins` (separate from main repo)
- Each plugin: Directory with manifest, code, tests, docs
- Manifest: `plugin.yaml` with metadata, capabilities, dependencies
- Versioning: Semantic versioning
- Signing: GPG signatures for plugin verification

## Plugin Manifest

```yaml
apiVersion: colossus.io/v1
kind: Plugin
metadata:
  name: my-custom-generator
  version: 1.0.0
  author: "Author Name"
  description: "Custom generator for X language"
spec:
  type: generator
  runtime: wasm
  capabilities:
    - generate:sdk
    - generate:client
  dependencies:
    - colossus-core >= 1.0.0
  resources:
    memory: 512Mi
    cpu: 1000m
    timeout: 300s
```

## Execution Model

- WASM plugins: Run in Wasmtime sandbox (preferred for security)
- gRPC plugins: Run as sidecars (for complex plugins needing external tools)
- Both models support the same plugin API

## Consequences

### Positive

- Extensibility: Platform grows without core changes
- Community: Enables third-party contributions
- Innovation: New languages, protocols, tools can be added quickly
- Isolation: Plugins can't crash the platform
- Governance: Plugin registry enables curation and quality control

### Negative

- Complexity: Plugin system is a significant subsystem itself
- Performance: WASM has overhead compared to native code
- Compatibility: Plugin API must be carefully versioned
- Security: Must audit plugins before allowing in registry

## Alternatives Considered

### Fork-and-modify
Rejected: Would fragment the ecosystem, make upgrades hard.

### Webhooks
Rejected: Good for notifications but not for code generation or validation.

### Configuration-only
Rejected: Too limited. Can't express complex logic.

## Related ADRs

- ADR-020: WASM for Plugin System
- ADR-022: Contributor Framework

## References

- [Plugin Architecture Patterns](https://martinfowler.com/articles/plugin-based-frameworks.html)
- [WASM Component Model](https://component-model.bytecodealliance.org/)
- [HashiCorp Plugin System](https://github.com/hashicorp/go-plugin)
