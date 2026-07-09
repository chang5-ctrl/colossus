# ADR-019: OAuth 2.0 + OIDC + OPA for Authentication and Authorization

**Status:** Accepted  
**Date:** 2026-07-09  
**Deciders:** Chief Architect, Security Lead  
**Category:** Security

## Context

Colossus needs:
- Authentication for platform users (developers, contributors, admins)
- Authorization for API access (who can do what)
- Multi-tenant isolation (organizations can't see each other's data)
- Fine-grained permissions (per API, per service, per action)
- Integration with external identity providers (GitHub, Google, etc.)
- Audit trail of all access decisions

## Decision

Use a layered approach:

1. **Authentication: OAuth 2.0 + OpenID Connect (OIDC)**
   - Keycloak as the identity provider (self-hosted)
   - Support for external IdPs (GitHub, Google, SAML)
   - JWT tokens for session management
   - Refresh tokens for long-lived sessions

2. **Authorization: Open Policy Agent (OPA) + Rego**
   - OPA as the policy decision point
   - Rego policies for fine-grained authorization
   - Policies stored in Git (policy-as-code)
   - OPA sidecars in Kubernetes for low-latency decisions

3. **Secrets: HashiCorp Vault**
   - Dynamic secrets (database credentials, API keys)
   - Short-lived tokens
   - Secret rotation
   - Audit logging

4. **Multi-tenancy:**
   - Tenant isolation at the database level (row-level security)
   - Tenant-specific namespaces in Kubernetes
   - Tenant-specific Kafka topics

Policy Examples:
```rego
package colossus.auth

allow {
  input.user.role == "admin"
}

allow {
  input.user.tenant == input.resource.tenant
  input.user.permissions[_] == input.action
}
```

## Consequences

### Positive

- Standards-based: OAuth 2.0 and OIDC are industry standards
- Flexible: OPA policies can express any authorization logic
- Auditable: All decisions logged
- Multi-tenant: Strong isolation guarantees
- Extensible: Easy to add new identity providers

### Negative

- Complexity: Three separate systems (Keycloak, OPA, Vault)
- Latency: OPA evaluation adds latency (mitigated by caching)
- Operational overhead: Keycloak and Vault require care and feeding
- Learning curve: Rego is a new language for most developers

## Alternatives Considered

### Custom auth system
Rejected: Would require building and maintaining authentication from scratch. Security-critical, better to use battle-tested solutions.

### Auth0 / Okta
Rejected: SaaS solutions introduce vendor lock-in and ongoing costs. Self-hosted preferred for open-source project.

### Casbin
Rejected: Good for authorization but less mature than OPA. OPA has better ecosystem and tooling.

## Related ADRs

- ADR-004: Kubernetes for Orchestration
- ADR-024: Service Mesh with Istio

## References

- [OAuth 2.0 RFC](https://tools.ietf.org/html/rfc6749)
- [OpenID Connect](https://openid.net/connect/)
- [Open Policy Agent](https://www.openpolicyagent.org/)
- [HashiCorp Vault](https://www.vaultproject.io/)
