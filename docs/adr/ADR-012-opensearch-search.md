# ADR-012: OpenSearch for Full-Text and Semantic Search

**Status:** Accepted  
**Date:** 2026-07-09  
**Deciders:** Chief Architect, Search Lead  
**Category:** Data

## Context

Colossus needs a search engine capable of:
- Full-text search across millions of API specs, docs, and generated artifacts
- Faceted search (filter by language, protocol, auth type, etc.)
- Semantic search using vector embeddings
- Autocomplete and query suggestions
- High availability and horizontal scaling
- Open source license (Apache 2.0)

## Decision

Use OpenSearch (Elasticsearch fork) as the primary search engine.

Key decisions:
- OpenSearch 2.x for full-text search, aggregations, and k-NN (vector search)
- Index sharding by API category or hash for distribution
- Hot/warm/cold data tiering
- Snapshot to S3 for durability
- Ingest pipelines for data transformation
- Index templates for consistent mapping

Index Design:
- `apis` — API metadata, tags, descriptions
- `specs` — API specification content (OpenAPI, GraphQL SDL, etc.)
- `docs` — Generated documentation
- `sdks` — SDK package metadata and README content
- `examples` — Example code snippets
- `tutorials` — Tutorial content

Search Features:
- BM25 scoring for full-text
- Vector embeddings via OpenSearch k-NN (for semantic search)
- Faceted aggregations for filtering
- Suggesters for autocomplete
- Highlighting for search results

Scaling:
- Dedicated master nodes (3+)
- Hot nodes for recent data
- Warm nodes for older data
- Cold nodes for archived data

## Consequences

### Positive

- Mature: Battle-tested at massive scale
- Feature-rich: Full-text, aggregations, k-NN, geo-search
- Ecosystem: Kibana/OpenSearch Dashboards, Beats, Logstash
- Open source: Apache 2.0, no licensing concerns
- Horizontal scaling: Add data nodes for capacity

### Negative

- Resource intensive: Requires significant memory and CPU
- Operational complexity: Cluster management, shard balancing
- JVM-based: GC pauses, heap tuning required
- Split from Elasticsearch: Smaller ecosystem than Elasticsearch

## Alternatives Considered

### Elasticsearch
Rejected: License changed to SSPL in 7.11+. Not acceptable for open-source project.

### Meilisearch
Rejected: Easier to operate but lacks horizontal scaling and advanced features.

### Typesense
Rejected: Good for smaller scale. Not proven at the scale Colossus requires.

### Solr
Rejected: Mature but less active development, smaller ecosystem than OpenSearch.

## Related ADRs

- ADR-006: CockroachDB for Metadata
- ADR-008: S3 for Object Storage

## References

- [OpenSearch Documentation](https://opensearch.org/docs/)
- [OpenSearch k-NN](https://opensearch.org/docs/latest/search-plugins/knn/)
- [Designing Data-Intensive Applications](https://dataintensive.net/) by Martin Kleppmann
