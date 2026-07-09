# Getting Started with Project Colossus

> Welcome to the largest open-source software engineering project ever attempted.

## Prerequisites

- **Git** — Version control
- **Docker** — Containerization
- **Bazel** — Build system ([installation guide](https://bazel.build/install))
- **Kubernetes** — Local cluster (kind, minikube, or Docker Desktop)
- **kubectl** — Kubernetes CLI
- **Helm** — Kubernetes package manager
- **Terraform** — Infrastructure as Code
- **buf** — Protocol Buffers toolchain
- **Language toolchains:**
  - Rust (rustup, cargo)
  - Go (1.22+)
  - Python (3.12+, Poetry)
  - Node.js (20+, pnpm)

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/chang5-ctrl/colossus.git
cd colossus
```

### 2. Set Up Development Environment

```bash
# Install development dependencies
make dev-setup

# Verify installation
make verify
```

### 3. Build the Project

```bash
# Build all services
bazel build //...

# Build specific service
bazel build //services/discovery-engine

# Build and test
bazel test //...
```

### 4. Run Locally

```bash
# Start local Kubernetes cluster
make cluster-up

# Deploy all services
make deploy-local

# Check status
kubectl get pods -n colossus
```

### 5. Run Tests

```bash
# Unit tests
bazel test //services/...

# Integration tests
bazel test //tests/integration/...

# E2E tests
bazel test //tests/e2e/...

# Performance tests
bazel test //tests/performance/...
```

## Development Workflow

1. **Fork & Branch** — Create a feature branch from `main`
2. **Code** — Follow [coding standards](coding-standards.md)
3. **Test** — Write tests, ensure coverage
4. **Document** — Update docs for user-facing changes
5. **Commit** — Follow [Conventional Commits](https://www.conventionalcommits.org/)
6. **PR** — Open pull request, CI must pass
7. **Review** — At least one approval required
8. **Merge** — Squash merge to `main`

## Project Structure

```
colossus/
├── docs/           # Architecture, ADRs, engineering docs
├── services/       # Microservices (one per directory)
├── libs/           # Shared libraries
├── infra/          # Infrastructure as Code
├── data/           # Database schemas and migrations
├── tools/          # CLI tools and scripts
├── tests/          # Test suites
├── governance/     # Contribution guidelines
└── .github/        # CI/CD workflows
```

## Architecture

See [docs/architecture/README.md](../architecture/README.md) for the complete system architecture.

## Contributing

See [governance/CONTRIBUTING.md](../../governance/CONTRIBUTING.md)

## Support

- **Issues:** [GitHub Issues](https://github.com/chang5-ctrl/colossus/issues)
- **Discussions:** [GitHub Discussions](https://github.com/chang5-ctrl/colossus/discussions)
- **Security:** [SECURITY.md](../../governance/SECURITY.md)

## License

Apache-2.0 — See [LICENSE](../../../LICENSE)
