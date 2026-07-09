# ADR-013: Neo4j for Knowledge Graph

**Status:** Accepted  
**Date:** 2026-07-09  
**Deciders:** Chief Architect, Data Engineering Lead  
**Category:** Data

## Context

Colossus needs to model complex relationships between:
- APIs and their endpoints
- APIs and the services they depend on
- APIs and the technologies they use
- APIs and the organizations that provide them
- APIs and security patterns
- APIs and performance characteristics

These relationships form a graph that enables:
- Impact analysis (what breaks if API X changes?)
- Discovery (find APIs similar to Stripe)
- Migration planning (map dependencies)
- Security analysis (identify shared auth patterns)

## Decision

Use Neo4j Enterprise with Causal Clustering for the knowledge graph.

Key decisions:
- Neo4j 5.x with Causal Clustering (3+ core servers, read replicas)
- Cypher query language for graph traversal
- APOC library for advanced procedures
- Graph Data Science library for analytics
- Bolt protocol for client connections

Graph Model:
- Nodes: `API`, `Endpoint`, `Schema`, `Domain`, `Organization`, `Technology`, `Concept`, `SecurityPattern`
- Relationships: `DEPENDS_ON`, `CALLS`, `IMPLEMENTS`, `EXTENDS`, `RELATED_TO`, `BELONGS_TO`, `USES`, `REQUIRES`

Use Cases:
- Impact analysis: Traverse `DEPENDS_ON` and `CALLS` relationships
- Discovery: Similarity scoring based on shared relationships
- Migration: Pathfinding between API versions
- Security: Pattern matching for vulnerability detection

Scaling:
- Causal Clustering for read scaling
- Read replicas for query load
- Graph partitioning by domain for very large graphs
- Materialized views for common traversal patterns

## Consequences

### Positive

- Native graph storage: Optimized for graph traversals
- Cypher: Expressive query language for graph patterns
- Mature: Proven in production for large graphs
- Ecosystem: APOC, GDS, Bloom visualization
- ACID: Full ACID transactions

### Negative

- Cost: Enterprise license for clustering features
- Scale: Single graph size limits (though sharding is improving)
- Operational complexity: Cluster management
- Write scaling: Writes go through core servers

## Alternatives Considered

### JanusGraph
Rejected: Better for very large graphs but requires external index (Elasticsearch) and storage (Cassandra/HBase). Adds operational complexity.

### ArangoDB
Rejected: Multi-model but graph performance not as optimized as Neo4j.

### Amazon Neptune
Rejected: Proprietary, vendor lock-in. Must be cloud-agnostic.

## Related ADRs

- ADR-006: CockroachDB for Metadata
- ADR-012: OpenSearch for Search

## References

- [Neo4j Documentation](https://neo4j.com/docs/)
- [Graph Databases](https://neo4j.com/graph-databases-book/) by Ian Robinson
- [Cypher Query Language](https://neo4j.com/docs/cypher-manual/current/)
