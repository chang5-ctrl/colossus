# Contributing to Project Colossus

> Thank you for considering contributing to the largest open-source software engineering project ever attempted.

## Getting Started

1. **Read the docs:** [docs/engineering/getting-started.md](../docs/engineering/getting-started.md)
2. **Join the community:** [GitHub Discussions](https://github.com/chang5-ctrl/colossus/discussions)
3. **Pick an issue:** Look for `good-first-issue` or `help-wanted` labels
4. **Ask questions:** No question is too small

## Development Setup

```bash
# Fork the repo on GitHub, then:
git clone https://github.com/YOUR_USERNAME/colossus.git
cd colossus

# Set up development environment
make dev-setup

# Verify everything works
make verify
```

## Workflow

### 1. Create a Branch

```bash
git checkout -b feature/my-feature-name
```

Branch naming:
- `feature/<description>` — New features
- `fix/<description>` — Bug fixes
- `docs/<description>` — Documentation
- `refactor/<description>` — Code refactoring
- `test/<description>` — Test additions
- `chore/<description>` — Maintenance

### 2. Make Changes

- Follow [coding standards](../docs/engineering/coding-standards.md)
- Write tests for new code
- Update documentation
- Keep commits focused and atomic

### 3. Commit

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
feat(discovery-engine): add support for GraphQL introspection

This commit adds support for discovering GraphQL APIs via
introspection queries. It includes:
- GraphQL schema parser
- Introspection query builder
- Unit tests
- Documentation

Closes #123
```

Types:
- `feat:` — New feature
- `fix:` — Bug fix
- `docs:` — Documentation
- `style:` — Formatting
- `refactor:` — Code restructuring
- `perf:` — Performance improvement
- `test:` — Tests
- `chore:` — Build, tooling
- `ci:` — CI/CD

### 4. Push and Open PR

```bash
git push origin feature/my-feature-name
```

Then open a Pull Request on GitHub.

### 5. PR Requirements

- [ ] CI passes (build, test, lint, security scan)
- [ ] Code coverage does not decrease
- [ ] At least one review approval
- [ ] No merge conflicts
- [ ] ADR included for architectural changes
- [ ] Documentation updated for user-facing changes

### 6. Review Process

- Automated checks run first
- Maintainers review within 3 business days
- Address feedback promptly
- Squash merge after approval

## Types of Contributions

### Code
- New features
- Bug fixes
- Performance improvements
- Refactoring

### Documentation
- README improvements
- API documentation
- Tutorials and guides
- ADRs

### Testing
- Unit tests
- Integration tests
- Performance benchmarks
- Chaos engineering experiments

### Design
- UI/UX improvements
- Architecture proposals
- ADR reviews

### Community
- Answer questions
- Write blog posts
- Give talks
- Organize meetups

## Recognition

- Contributor leaderboard (updated monthly)
- Badges for contributions
- Hall of Fame for significant contributions
- Core maintainer promotion path

## Questions?

- [GitHub Discussions](https://github.com/chang5-ctrl/colossus/discussions)
- [Discord](https://discord.gg/colossus)
- Email: community@colossus.io

## License

By contributing, you agree that your contributions will be licensed under the Apache-2.0 License.
