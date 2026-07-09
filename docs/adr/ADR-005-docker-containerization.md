# ADR-005: Docker for Containerization

**Status:** Accepted  
**Date:** 2026-07-09  
**Deciders:** Chief Architect, DevOps Lead  
**Category:** Infrastructure

## Context

All Colossus services must be packaged consistently for deployment across development, staging, and production environments.

Requirements:
- Reproducible builds
- Consistent runtime environment
- Efficient resource utilization
- Fast startup times
- Small image sizes
- Multi-arch support (AMD64, ARM64)

## Decision

Use Docker for containerization with the following standards:

Base Images:
- Production: `distroless` or `alpine` for minimal attack surface
- Development: `debian:slim` for debugging tools
- Language-specific: Official language images for build stages

Build Strategy:
- Multi-stage builds to minimize final image size
- BuildKit for parallel builds and caching
- Layer caching optimization (frequently changing layers last)
- Non-root user execution in all containers

Image Registry:
- Primary: GitHub Container Registry (ghcr.io)
- Backup: Docker Hub (for public images)
- Internal: Private registry for sensitive images

Tagging:
- `latest` for development
- `v{semver}` for releases
- `sha-{git-sha}` for CI builds
- `pr-{number}` for pull requests

## Consequences

### Positive

- Consistency: Same container runs everywhere
- Isolation: Services don't interfere with each other
- Portability: Runs on any Docker-compatible platform
- Efficiency: Shared kernel, lower overhead than VMs
- Ecosystem: Massive tooling, registries, scanning tools

### Negative

- Image size: Can be large if not optimized
- Security: Container escape vulnerabilities
- Complexity: Additional layer of abstraction
- Storage: Images consume disk space

## Alternatives Considered

### Podman
Rejected: Good alternative but smaller ecosystem. May be used in development.

### LXC/LXD
Rejected: More VM-like, less suitable for microservices.

### Raw Binaries
Rejected: No isolation, dependency management nightmare at scale.

## Related ADRs

- ADR-004: Kubernetes for Orchestration
- ADR-024: Service Mesh with Istio

## References

- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Distroless Images](https://github.com/GoogleContainerTools/distroless)
- [OCI Specification](https://opencontainers.org/)
