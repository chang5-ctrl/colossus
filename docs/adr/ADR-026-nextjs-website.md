# ADR-026: Next.js for Public Website Frontend

**Status:** Accepted  
**Date:** 2026-07-09  
**Deciders:** Chief Architect, Frontend Lead  
**Category:** Engineering

## Context

Colossus needs a public-facing website for:
- Browsing the API catalog
- Reading generated documentation
- Downloading SDKs
- Searching APIs
- Interactive API playground
- User accounts and preferences
- Contributor portal

## Decision

Use Next.js (React) for the public website frontend.

Key decisions:
- Next.js 14+ with App Router
- Server-side rendering (SSR) for SEO
- Static site generation (SSG) for documentation pages
- Incremental static regeneration (ISR) for dynamic content
- TypeScript for type safety
- Tailwind CSS for styling
- React Query for data fetching
- Zustand for state management

Backend:
- Go API gateway (ADR-010)
- gRPC to internal services
- REST for frontend consumption

Features:
- API catalog with faceted search
- Interactive documentation
- SDK download with package manager commands
- API playground (try APIs in browser)
- User dashboard
- Contributor leaderboard

Performance:
- Edge caching via CDN
- Image optimization (Next.js Image)
- Code splitting
- Lazy loading

## Consequences

### Positive

- SEO: SSR and SSG for search engine optimization
- Performance: Edge caching, code splitting, image optimization
- Developer experience: TypeScript, hot reload, excellent tooling
- Ecosystem: Massive React ecosystem
- Vercel: Optional deployment platform (but can run anywhere)

### Negative

- Complexity: Next.js has many features, can be overwhelming
- Server requirements: SSR requires Node.js server (or edge runtime)
- Bundle size: React is larger than vanilla JS
- Build time: SSG for millions of pages could be slow

## Alternatives Considered

### Astro
Rejected: Excellent for content sites but less mature for dynamic applications.

### Remix
Rejected: Similar to Next.js but smaller ecosystem.

### Vanilla JS + SSR
Rejected: Would require building everything from scratch. Next.js provides proven patterns.

## Related ADRs

- ADR-025: CDN Strategy
- ADR-010: Go for Services

## References

- [Next.js Documentation](https://nextjs.org/docs)
- [React Documentation](https://react.dev/)
- [Tailwind CSS](https://tailwindcss.com/)
