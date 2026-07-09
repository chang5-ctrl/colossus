# ADR-022: Contributor Framework and Governance

**Status:** Accepted  
**Date:** 2026-07-09  
**Deciders:** Chief Architect, Community Lead  
**Category:** Governance

## Context

Colossus is designed to be the largest open-source project ever attempted.
This requires:
- Thousands of contributors
- Clear contribution guidelines
- Automated code review
- Quality gates
- Recognition and reputation system
- Decision-making processes
- Conflict resolution

## Decision

Establish a comprehensive contributor framework:

## Governance Model

- **Benevolent Dictator (Chief Architect):** Final decision maker for architecture
- **Core Maintainers:** Review and merge code, make technical decisions
- **Service Owners:** Own specific services, make service-level decisions
- **Contributors:** Submit PRs, report issues, write documentation
- **Community Members:** Participate in discussions, provide feedback

## Contribution Workflow

1. **Fork & Branch:** Fork repo, create feature branch
2. **Develop:** Write code, tests, documentation
3. **Test:** Run local tests, CI passes
4. **Submit PR:** Open pull request with description
5. **Review:** Automated + human review
6. **Merge:** Squash merge after approval
7. **Release:** Included in next release

## Automated Quality Gates

- CI must pass (build, test, lint, security scan)
- Code coverage must not decrease
- ADR required for architectural changes
- Documentation required for user-facing changes
- Breaking changes require migration guide

## Recognition

- Contributor leaderboard
- Badges for contributions (code, docs, tests, reviews)
- Hall of Fame for significant contributions
- Core maintainer promotion path

## Consequences

### Positive

- Scalability: Framework supports thousands of contributors
- Quality: Automated gates ensure code quality
- Community: Recognition system encourages contributions
- Sustainability: Clear governance prevents project stagnation

### Negative

- Bureaucracy: More process can slow down contributions
- Maintenance: Governance system requires maintenance
- Conflict: Decision-making can be contentious
- Burnout: Maintainers can burn out without support

## Alternatives Considered

### Anarchy (no governance)
Rejected: Would lead to chaos, low quality, contributor attrition.

### Corporate-controlled
Rejected: Would discourage community contributions, create conflicts of interest.

### Foundation-controlled
Rejected: Too early. May be considered when project matures.

## Related ADRs

- ADR-021: Plugin System Architecture
- ADR-023: Git Workflow

## References

- [Open Source Governance Models](https://opensource.guide/leadership-and-governance/)
- [Kubernetes Governance](https://github.com/kubernetes/community/blob/master/governance.md)
- [Rust Governance](https://www.rust-lang.org/governance)
