# ADR-025: Multi-CDN Strategy for Global Content Delivery

**Status:** Accepted  
**Date:** 2026-07-09  
**Deciders:** Chief Architect, Infrastructure Lead  
**Category:** Infrastructure

## Context

Colossus serves:
- Generated documentation (millions of pages)
- Generated SDK packages
- Static website assets
- API playground resources

These must be:
- Fast globally (low latency)
- Highly available
- Cost-effective
- Resilient to CDN outages

## Decision

Use a multi-CDN strategy:

Primary CDN: Cloudflare
- Global Anycast network
- DDoS protection
- Edge caching
- Workers for edge computing
- Image optimization

Secondary CDN: AWS CloudFront
- Origin failover from Cloudflare
- Regional optimization
- Integration with AWS services
- Signed URLs for private content

Origin: S3 + Colossus API Gateway
- S3 for static content
- API Gateway for dynamic content

Failover:
- DNS-based failover (Route 53 health checks)
- If primary CDN fails, traffic routes to secondary
- Both CDNs cache from same S3 origin

Cache Strategy:
- Generated docs: Cache forever, invalidate on generation
- SDK packages: Cache forever, immutable
- Website assets: Cache with versioning
- API responses: Short cache for dynamic content

## Consequences

### Positive

- Performance: Global edge caching, low latency
- Availability: Multi-CDN failover
- Cost: Offloads origin, reduces bandwidth costs
- Security: DDoS protection, WAF
- Scalability: CDN handles traffic spikes

### Negative

- Complexity: Managing two CDNs
- Cost: CDN bandwidth costs
- Cache invalidation: Must carefully manage cache invalidation
- Consistency: Cache staleness during updates

## Alternatives Considered

### Single CDN
Rejected: Single point of failure. Multi-CDN provides resilience.

### Self-hosted CDN
Rejected: Would require global edge infrastructure. Not feasible.

### P2P Distribution
Rejected: Interesting for the future but not reliable enough for production.

## Related ADRs

- ADR-008: S3 for Object Storage
- ADR-026: Public Website

## References

- [Cloudflare Documentation](https://developers.cloudflare.com/)
- [AWS CloudFront](https://docs.aws.amazon.com/cloudfront/)
- [Multi-CDN Best Practices](https://www.cloudflare.com/learning/cdn/what-is-a-cdn/)
