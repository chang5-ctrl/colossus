# Coding Standards

> Every line of code in Colossus must be production-grade.
> Assume enterprises depend on it. Assume developers will audit it.

## General Principles

1. **Clarity over cleverness** — Code is read more than written
2. **Explicit over implicit** — No magic, no hidden behavior
3. **Fail fast, fail loud** — Errors should be impossible to ignore
4. **Defensive programming** — Validate all inputs, handle all edge cases
5. **No premature optimization** — Profile first, optimize second
6. **Test everything** — If it is not tested, it is broken
7. **Document intent** — Comments explain why, not what

## Language-Specific Standards

### Rust

```rust
// Use Result for all fallible operations
fn parse_api_spec(input: &str) -> Result<ApiSpec, ParseError> {
    // Implementation
}

// Use thiserror for error types
#[derive(thiserror::Error, Debug)]
pub enum ParseError {
    #[error("invalid JSON: {0}")]
    InvalidJson(#[from] serde_json::Error),
    #[error("missing required field: {0}")]
    MissingField(String),
}

// Use tracing for structured logging
use tracing::{info, warn, error, debug};

info!(api_id = %api_id, version = %version, "discovered new API");

// Use tokio for async
#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Implementation
}
```

**Rules:**
- `clippy::all` must pass with zero warnings
- `rustfmt` must pass
- `cargo audit` must pass (no known vulnerabilities)
- All public APIs must have doc comments
- Use `?` for error propagation
- Prefer `Arc<str>` over `String` for shared immutable data
- Use `tokio::sync::RwLock` over `std::sync::RwLock` in async code

### Go

```go
// Use context for cancellation and deadlines
func ProcessAPI(ctx context.Context, apiID string) error {
    // Implementation
}

// Return errors, do not panic
if err != nil {
    return fmt.Errorf("failed to process API %s: %w", apiID, err)
}

// Use structured logging
logger.Info("processing API",
    zap.String("api_id", apiID),
    zap.String("version", version),
)

// Interface segregation
// Good: Small, focused interfaces
type APIReader interface {
    ReadAPI(ctx context.Context, id string) (*API, error)
}

type APIWriter interface {
    WriteAPI(ctx context.Context, api *API) error
}
```

**Rules:**
- `gofmt` must pass
- `golangci-lint` must pass with zero warnings
- `go vet` must pass
- All exported symbols must have doc comments
- Use `context.Context` as first parameter
- Return `(T, error)` for all fallible functions
- Use `errors.Is` and `errors.As` for error handling
- Prefer composition over inheritance
- Use `sync.RWMutex` for read-heavy data structures

### Python

```python
from typing import Optional, List, Dict, Any
from dataclasses import dataclass
import logging

logger = logging.getLogger(__name__)

@dataclass(frozen=True)
class APISpec:
    """Represents a parsed API specification."""
    name: str
    version: str
    endpoints: List[Endpoint]
    
    def validate(self) -> List[ValidationError]:
        """Validate the API specification."""
        errors: List[ValidationError] = []
        # Implementation
        return errors

def parse_api_spec(raw: str) -> APISpec:
    """Parse an API specification from a raw string.
    
    Args:
        raw: The raw API specification string.
        
    Returns:
        The parsed API specification.
        
    Raises:
        ParseError: If the specification is invalid.
    """
    # Implementation
```

**Rules:**
- `ruff` must pass (replaces flake8, black, isort)
- `mypy --strict` must pass
- `pytest` must pass with >90% coverage
- Use type hints everywhere
- Use `dataclasses` or `pydantic` for data models
- Use `structlog` for structured logging
- Use `asyncio` for async code
- Use `poetry` for dependency management

## Code Review Checklist

- [ ] Code follows language-specific standards
- [ ] All functions have doc comments
- [ ] Error handling is comprehensive
- [ ] Tests cover all branches
- [ ] No hardcoded secrets or credentials
- [ ] No TODOs without issue references
- [ ] Performance implications considered
- [ ] Security implications considered
- [ ] ADR referenced for architectural changes

## Testing Standards

### Unit Tests
- Test one thing per test
- Use descriptive test names: `TestProcessAPI_InvalidInput_ReturnsError`
- Use table-driven tests where appropriate
- Mock external dependencies
- Target: >90% coverage

### Integration Tests
- Test service interactions
- Use test containers for dependencies
- Clean up after tests
- Target: All happy paths + common error paths

### E2E Tests
- Test complete user workflows
- Run against staging environment
- Target: Critical user journeys

### Performance Tests
- Benchmark hot paths
- Set performance budgets
- Fail CI if budget exceeded

## Documentation Standards

- Every public API must have doc comments
- README.md in every service directory
- Architecture Decision Records for all significant decisions
- Runbooks for operational procedures
- ADRs must include: context, decision, consequences, alternatives

## Security Standards

- No secrets in code (use Vault)
- All inputs validated and sanitized
- SQL injection prevention (parameterized queries)
- XSS prevention (output encoding)
- CSRF protection for web endpoints
- Rate limiting on all public APIs
- Security headers on all responses
- Dependency scanning in CI
- SAST in CI (Semgrep, CodeQL)

## Performance Standards

- Profile before optimizing
- Set performance budgets
- Use caching where appropriate
- Minimize allocations in hot paths
- Use connection pooling
- Batch operations where possible
- Async I/O for network calls
- Streaming for large data transfers