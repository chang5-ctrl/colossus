# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| Latest release | Yes |
| Previous minor | Yes |
| Older versions | No |

## Reporting a Vulnerability

**DO NOT** open a public issue for security vulnerabilities.

Instead, email: security@colossus.io

Include:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

## Response Timeline

| Step | Timeline |
|------|----------|
| Acknowledgment | 24 hours |
| Initial assessment | 72 hours |
| Fix development | 1-2 weeks |
| Disclosure | After fix deployed |

## Security Measures

- All dependencies scanned daily (Snyk, Dependabot)
- SAST in CI (Semgrep, CodeQL)
- Container scanning (Trivy)
- Secrets scanning (GitGuardian)
- Penetration testing: Quarterly
- Bug bounty program: Planned

## Security Contacts

- security@colossus.io
- PGP Key: [security.pub](https://colossus.io/security.pub)
