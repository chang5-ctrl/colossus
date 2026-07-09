# ADR-011: Python for Data Processing and Machine Learning

**Status:** Accepted  
**Date:** 2026-07-09  
**Deciders:** Chief Architect, ML Lead  
**Category:** Engineering

## Context

Colossus needs data processing and ML capabilities for:
- API specification parsing and normalization
- Natural language processing (doc generation, example generation)
- Analytics and reporting
- Data pipeline ETL
- ML-assisted generation (future)
- Jupyter notebooks for exploration

## Decision

Use Python for data processing, ML, and analytics workloads:

Python Services:
- Translation Engine (spec format conversion)
- Example Generator (template + ML-assisted)
- Analytics Platform (data pipelines, reporting)
- Doc Generator (NLP for documentation)

Python Libraries:
- `libs/testing` — Test generation frameworks
- `libs/models` — Data models and schemas

Tooling:
- Poetry for dependency management
- Ruff for linting and formatting
- pytest for testing
- mypy for type checking
- black for formatting
- Jupyter for exploration

## Consequences

### Positive

- Ecosystem: Unmatched for data science and ML
- Productivity: Rapid prototyping, readable code
- Libraries: NumPy, Pandas, PyTorch, Transformers, etc.
- Community: Massive, active community

### Negative

- Performance: Slower than Rust/Go for CPU-bound tasks
- GIL: Limits true parallelism in threads
- Packaging: Dependency management can be complex
- Type safety: Optional typing (mypy helps but isn't enforced)

## Alternatives Considered

### Julia
Rejected: Excellent for numerical computing but smaller ecosystem and community.

### R
Rejected: Domain-specific for statistics. Not suitable for general service development.

### Scala
Rejected: Good for Spark but JVM-based. Python has better ML libraries.

## Related ADRs

- ADR-009: Rust for Performance-Critical Components
- ADR-010: Go for Services

## References

- [Python Documentation](https://docs.python.org/3/)
- [Poetry](https://python-poetry.org/)
- [Google Python Style Guide](https://google.github.io/styleguide/pyguide.html)
