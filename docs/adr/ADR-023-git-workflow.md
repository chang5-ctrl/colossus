# ADR-023: Git Workflow and Branching Strategy

**Status:** Accepted  
**Date:** 2026-07-09  
**Deciders:** Chief Architect, DevOps Lead  
**Category:** Engineering

## Context

Colossus has 28+ services, thousands of contributors, and continuous deployment.
Need a Git workflow that:
- Supports parallel development across services
- Enables continuous integration
- Allows safe experimentation
- Supports hotfixes
- Maintains clean history
- Works with automated tooling

## Decision

Adopt a trunk-based development workflow with feature flags.

## Branch Strategy

- `main` — Production-ready, always deployable
- `feature/<name>` — Feature branches, short-lived (hours to days)
- `hotfix/<name>` — Emergency fixes, branched from main
- `release/v{major}.{minor}` — Release branches, created from main

## Workflow

1. **Pull from main:** Always start from latest main
2. **Create feature branch:** `git checkout -b feature/my-feature`
3. **Develop:** Small, focused commits
4. **Push & PR:** Open PR when ready
5. **CI runs:** Automated tests, lint, security scan
6. **Review:** At least one approval required
7. **Squash merge:** Clean history on main
8. **Delete branch:** Keep repo clean

## Commit Convention

Use Conventional Commits:
```
<type>(<scope>): <subject>

<body>

<footer>
```

Types:
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation
- `style:` Formatting, no code change
- `refactor:` Code restructuring
- `perf:` Performance improvement
- `test:` Tests
- `chore:` Build, tooling, dependencies
- `ci:` CI/CD changes

Scopes:
- Service name: `feat(discovery-engine): ...`
- Library name: `fix(libs/codegen): ...`
- Infra: `chore(infra): ...`
- Docs: `docs(adr): ...`

## Feature Flags

- All new features behind feature flags
- Flags controlled via configuration (not code changes)
- Flags can be enabled per tenant, per region, or globally
- Flags are temporary, removed after feature is stable

## Consequences

### Positive

- Simplicity: Simple branching model, easy to understand
- CI-friendly: Short-lived branches, frequent integration
- Safety: Feature flags allow safe experimentation
- History: Clean, linear history on main
- Speed: Fast feedback loop, continuous deployment

### Negative

- Discipline: Requires discipline to keep branches short-lived
- Feature flags: Adds complexity, must be cleaned up
- Merge conflicts: Frequent integration can cause conflicts
- Main stability: Requires robust CI to keep main green

## Alternatives Considered

### GitFlow
Rejected: Too complex for continuous deployment. Release branches are overhead.

### GitHub Flow
Rejected: Similar to trunk-based but less explicit about feature flags and commit conventions.

### Forking Workflow
Rejected: Good for open source but adds overhead for core team.

## Related ADRs

- ADR-022: Contributor Framework
- ADR-015: Bazel for Build System

## References

- [Trunk-Based Development](https://trunkbaseddevelopment.com/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Feature Toggles](https://martinfowler.com/articles/feature-toggles.html) by Martin Fowler
