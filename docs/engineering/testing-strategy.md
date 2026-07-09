# Testing Strategy

> Comprehensive testing strategy for Project Colossus.
> Every generated artifact must be production-grade. Every service must be resilient.

## Philosophy

1. **Shift-left:** Catch issues as early as possible
2. **Automate everything:** No manual testing in CI/CD
3. **Test in production:** Use feature flags, canary deployments, and real traffic
4. **Chaos engineering:** Break things intentionally to build resilience
5. **Determinism:** Same inputs must always produce same outputs

## Testing Pyramid

```
         /\
        /  \
       / E2E \      <- 5% of tests, critical user journeys
      /--------\
     /   Integ   \   <- 15% of tests, service interactions
    /--------------\
   /     Unit        \ <- 80% of tests, fast, isolated
  /--------------------\
 /   Static Analysis     \ <- Zero runtime cost
/--------------------------\
```

## Test Categories

### 1. Static Analysis (Zero Runtime Cost)

**Purpose:** Catch issues before code runs.

**Tools:**
- **Go:** golangci-lint (govet, staticcheck, errcheck, gosec)
- **Rust:** Clippy, rustfmt, cargo-audit
- **Python:** Ruff, mypy, bandit
- **All:** Semgrep, CodeQL, SonarQube
- **Containers:** Hadolint, Trivy
- **Infrastructure:** tfsec, checkov, kube-bench

**Pipeline:**
```
Code Commit -> Lint -> Format Check -> Security Scan -> Type Check -> Build
```

**SLI:** 100% of PRs must pass all static analysis before merge.

### 2. Unit Tests (80% of Test Suite)

**Purpose:** Test individual functions, classes, and modules in isolation.

**Characteristics:**
- Fast: < 100ms per test
- Isolated: No external dependencies
- Deterministic: Same result every time
- Repeatable: Can run in any order

**Coverage Targets:**
| Component | Target | Minimum |
|-----------|--------|---------|
| Core libraries | 95% | 90% |
| Services | 90% | 85% |
| Generated code | 80% | 70% |
| Infrastructure code | 70% | 60% |

**Tools:**
- **Go:** `go test` + testify + gomock
- **Rust:** `cargo test` + mockall
- **Python:** pytest + pytest-mock + factory-boy
- **All:** Bazel for test execution and caching

**Example (Go):**
```go
func TestDiscoveryEngine_ParseOpenAPI(t *testing.T) {
    tests := []struct {
        name     string
        input    string
        wantErr  bool
        wantAPIs int
    }{
        {
            name:     "valid OpenAPI 3.0",
            input:    loadFixture("openapi30_valid.json"),
            wantErr:  false,
            wantAPIs: 5,
        },
        {
            name:     "invalid JSON",
            input:    "not json",
            wantErr:  true,
            wantAPIs: 0,
        },
        {
            name:     "missing required fields",
            input:    loadFixture("openapi30_missing_info.json"),
            wantErr:  true,
            wantAPIs: 0,
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            engine := NewDiscoveryEngine()
            apis, err := engine.ParseOpenAPI([]byte(tt.input))

            if tt.wantErr {
                require.Error(t, err)
                return
            }

            require.NoError(t, err)
            assert.Len(t, apis, tt.wantAPIs)
        })
    }
}
```

**Determinism Tests:**
Every code generator must have a determinism test:
```go
func TestSDKGenerator_Deterministic(t *testing.T) {
    spec := loadFixture("stripe_openapi.json")

    gen1, err := generator.Generate(spec, "typescript")
    require.NoError(t, err)

    gen2, err := generator.Generate(spec, "typescript")
    require.NoError(t, err)

    hash1 := sha256sum(gen1)
    hash2 := sha256sum(gen2)

    assert.Equal(t, hash1, hash2, "generation must be deterministic")
}
```

### 3. Integration Tests (15% of Test Suite)

**Purpose:** Test service interactions and database interactions.

**Characteristics:**
- Test service boundaries
- Use real databases (test containers)
- Test Kafka message flows
- Test API contracts

**Tools:**
- **Test Containers:** Docker-based ephemeral databases
- **Kafka Test Containers:** Embedded Kafka for testing
- **WireMock:** Mock external APIs
- **Contract Testing:** Pact for consumer-driven contracts

**Test Containers Setup:**
```go
func TestAPIRegistry_Integration(t *testing.T) {
    ctx := context.Background()

    // Start CockroachDB container
    cockroach, err := testcontainers.GenericContainer(ctx, testcontainers.GenericContainerRequest{
        ContainerRequest: testcontainers.ContainerRequest{
            Image:        "cockroachdb/cockroach:latest-v23.1",
            ExposedPorts: []string{"26257/tcp", "8080/tcp"},
            Cmd:          []string{"start-single-node", "--insecure"},
            WaitingFor:   wait.ForHTTP("/health").WithPort("8080/tcp"),
        },
        Started: true,
    })
    require.NoError(t, err)
    defer cockroach.Terminate(ctx)

    // Run tests against real database
    registry := NewAPIRegistry(getDBConnection(cockroach))
    // ... tests
}
```

**Contract Testing (Pact):**
```go
func TestSDKGenerator_ConsumerContract(t *testing.T) {
    pact := dsl.Pact{
        Consumer: "sdk-generator",
        Provider: "api-registry",
    }

    pact.AddInteraction().
        Given("API exists").
        UponReceiving("a request for API spec").
        WithRequest(dsl.Request{
            Method:  "GET",
            Path:    dsl.String("/v1/apis/123/spec"),
        }).
        WillRespondWith(dsl.Response{
            Status:  200,
            Headers: dsl.MapMatcher{"Content-Type": dsl.String("application/json")},
            Body:    dsl.Match(APIResponse{}),
        })

    // Verify consumer contract
    // Provider verifies separately in CI
}
```

### 4. E2E Tests (5% of Test Suite)

**Purpose:** Test complete user workflows from end to end.

**Characteristics:**
- Run against staging environment
- Test real infrastructure
- Test critical user journeys
- Slow but comprehensive

**Critical User Journeys:**
1. **Discovery Flow:** Submit API URL -> Discovery completes -> API registered -> Spec stored
2. **Generation Flow:** API registered -> Generation job queued -> SDK generated -> Validation passes -> Release published
3. **API Change Detection:** Upstream API changes -> Change detected -> New generation triggered -> New release published
4. **User Subscription:** User subscribes to API -> API changes -> User notified
5. **Search Flow:** User searches -> Results returned -> API details displayed -> SDK downloaded

**Tools:**
- **Cypress:** Browser-based E2E testing
- **Playwright:** Cross-browser E2E testing
- **k6:** API-level E2E testing
- **Custom:** Go-based E2E test runner

**Example (k6):**
```javascript
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '2m', target: 100 },
    { duration: '5m', target: 100 },
    { duration: '2m', target: 200 },
    { duration: '5m', target: 200 },
    { duration: '2m', target: 0 },
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'],
    http_req_failed: ['rate<0.01'],
  },
};

export default function () {
  const res = http.get('https://api.colossus.io/v1/apis');
  check(res, {
    'status is 200': (r) => r.status === 200,
    'response time < 500ms': (r) => r.timings.duration < 500,
  });
  sleep(1);
}
```

### 5. Performance Tests

**Purpose:** Ensure system meets performance requirements.

**Performance Budgets:**
| Metric | Target | Budget | CI Failure Threshold |
|--------|--------|--------|---------------------|
| API Discovery Latency | P95 < 1h | P95 < 30min | P95 > 2h |
| SDK Generation Latency | P95 < 30min | P95 < 15min | P95 > 1h |
| Validation Latency | P95 < 15min | P95 < 10min | P95 > 30min |
| API Sync Latency | P95 < 5min | P95 < 2min | P95 > 10min |
| End-to-End Pipeline | P95 < 2h | P95 < 1h | P95 > 4h |
| Search Query Latency | P95 < 100ms | P95 < 50ms | P95 > 500ms |
| SDK Download Latency | P95 < 50ms | P95 < 20ms | P95 > 200ms |

**Tools:**
- **k6:** Load testing
- **Locust:** Python-based load testing
- **JMeter:** GUI-based load testing
- **Custom:** Go-based benchmark harness

**Benchmarking (Go):**
```go
func BenchmarkSDKGenerator_Generate(b *testing.B) {
    spec := loadLargeSpec("stripe_openapi.json")
    generator := NewSDKGenerator()

    b.ResetTimer()
    for i := 0; i < b.N; i++ {
        _, err := generator.Generate(spec, "typescript")
        if err != nil {
            b.Fatal(err)
        }
    }
}
```

### 6. Chaos Engineering

**Purpose:** Verify system resilience under failure conditions.

**Chaos Experiments:**

| Experiment | Target | Expected Behavior | Abort Condition |
|------------|--------|-------------------|-----------------|
| Kill discovery-engine pod | Discovery Engine | Kafka consumer group rebalances, no data loss | > 1% message loss |
| Network partition (CockroachDB) | Database | Automatic failover, reads continue | > 30s unavailability |
| CPU saturation (SDK Generator) | Generation Worker | HPA scales up, queue doesn't overflow | > 1000 message lag |
| Memory pressure (Redis) | Cache | Eviction policy works, DB fallback | > 10% error rate |
| Kafka broker failure | Message Queue | ISR maintains availability, producers retry | > 5s producer latency |
| CDN failure | Content Delivery | Fallback to secondary CDN, origin serves | > 1min without CDN |

**Tools:**
- **Chaos Mesh:** Kubernetes-native chaos engineering
- **Litmus:** Cloud-native chaos engineering
- **Gremlin:** SaaS chaos engineering platform
- **Custom:** Custom chaos experiments

**Example (Chaos Mesh):**
```yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: PodChaos
metadata:
  name: discovery-engine-failure
  namespace: chaos-mesh
spec:
  action: pod-kill
  mode: one
  selector:
    namespaces:
      - colossus
    labelSelectors:
      app: discovery-engine
  duration: 30s
  scheduler:
    cron: "@every 10m"
```

### 7. Security Tests

**Purpose:** Ensure system and generated artifacts are secure.

**Security Test Categories:**

| Category | Tools | Frequency |
|----------|-------|-----------|
| SAST | Semgrep, CodeQL, SonarQube | Every PR |
| DAST | OWASP ZAP, Burp Suite | Weekly |
| Dependency Scan | Snyk, OWASP Dependency-Check, cargo-audit | Every PR |
| Secret Scan | TruffleHog, GitGuardian | Every PR |
| Container Scan | Trivy, Clair | Every build |
| Fuzzing | libFuzzer, AFL, go-fuzz | Nightly |
| Penetration Testing | Manual + automated | Quarterly |

**Fuzzing Example (Go):**
```go
func FuzzParseOpenAPI(f *testing.F) {
    f.Add([]byte(`{"openapi":"3.0.0","info":{"title":"Test","version":"1.0.0"}}`))

    f.Fuzz(func(t *testing.T, data []byte) {
        engine := NewDiscoveryEngine()
        _, _ = engine.ParseOpenAPI(data)
        // Should not panic, should not hang
    })
}
```

**Generated Code Security:**
Every generated SDK must pass:
- SAST (Semgrep rules for each language)
- Dependency scan (no known vulnerabilities)
- No hardcoded secrets
- No insecure defaults
- Proper input validation

### 8. Determinism Tests

**Purpose:** Verify that code generation is deterministic.

**Test:**
1. Generate SDK for a given API spec
2. Generate again with same inputs
3. Compare SHA-256 hashes
4. Must be identical

**CI Integration:**
```yaml
- name: Determinism Check
  run: |
    for api in test-apis/*; do
      for lang in typescript python go rust; do
        bazel run //tools/cli:colossus -- generate --api $api --lang $lang --output /tmp/gen1
        bazel run //tools/cli:colossus -- generate --api $api --lang $lang --output /tmp/gen2
        diff -r /tmp/gen1 /tmp/gen2 || exit 1
      done
    done
```

### 9. Compatibility Tests

**Purpose:** Verify generated SDKs work with real APIs.

**Test Matrix:**
| Language | Version | Test Against |
|----------|---------|-------------|
| TypeScript | Node 18, 20, 22 | Stripe API, GitHub API |
| Python | 3.10, 3.11, 3.12 | Stripe API, GitHub API |
| Go | 1.20, 1.21, 1.22 | Stripe API, GitHub API |
| Rust | stable, beta | Stripe API, GitHub API |
| Java | 17, 21 | Stripe API, GitHub API |

**Contract Testing:**
Generated SDKs are tested against:
- Mock servers (WireMock, Prism)
- Sandbox APIs (Stripe test mode, GitHub sandbox)
- Real APIs (read-only operations)

### 10. Accessibility Tests

**Purpose:** Ensure public website is accessible.

**Tools:**
- axe-core
- Lighthouse
- Pa11y
- WAVE

**Requirements:**
- WCAG 2.1 AA compliance
- Keyboard navigation
- Screen reader compatibility
- Color contrast ratios

## Test Environments

| Environment | Purpose | Data | Availability |
|-------------|---------|------|-------------|
| Unit Test | Fast feedback | Mock/fake | Local + CI |
| Integration Test | Service interactions | Test containers | CI |
| Staging | E2E + Performance | Synthetic | 24/7 |
| Production | Canary + Real traffic | Real | 24/7 |
| Chaos | Resilience testing | Synthetic | Scheduled |

## Test Data Management

### Test Data Strategy
- **Synthetic data:** Generated for each test run
- **Snapshot data:** Real API specs (anonymized) stored in repo
- **Seed data:** Database seeds for integration tests
- **Property-based:** Hypothesis/QuickCheck for generative testing

### Data Privacy
- No real user data in tests
- All PII anonymized
- Secrets rotated after test runs

## CI/CD Test Pipeline

```
PR Opened
    |
    v
Static Analysis (parallel)
    |-- Lint & Format
    |-- Security Scan (SAST, secrets, deps)
    |-- Type Check
    |
    v
Build
    |-- Compile all services
    |-- Build Docker images
    |
    v
Unit Tests (parallel by service)
    |-- >90% coverage
    |-- Determinism check
    |
    v
Integration Tests (parallel by service)
    |-- Test containers
    |-- Contract tests
    |
    v
E2E Tests (staging)
    |-- Critical user journeys
    |-- Performance tests
    |
    v
Merge to main
    |
    v
Nightly
    |-- Full test suite
    |-- Chaos engineering
    |-- Fuzzing
    |-- DR drill
    |-- Dependency audit
```

## Test Metrics

| Metric | Target | Dashboard |
|--------|--------|-----------|
| Test Coverage | >90% | Grafana |
| Test Execution Time | < 30 min (PR) | Grafana |
| Flaky Test Rate | < 1% | Grafana |
| Bug Escape Rate | < 0.1% | Grafana |
| MTTD (Mean Time to Detect) | < 5 min | PagerDuty |
| MTTR (Mean Time to Repair) | < 1 hour | PagerDuty |

## Test Ownership

| Test Type | Owner | Reviewer |
|-----------|-------|----------|
| Unit tests | Service owner | Any maintainer |
| Integration tests | Service owner | Platform team |
| E2E tests | QA team | Product team |
| Performance tests | Platform team | SRE team |
| Chaos tests | SRE team | All teams |
| Security tests | Security team | All teams |
| Determinism tests | Codegen team | Architecture team |

## Future Improvements

- [ ] Formal verification for critical generation paths
- [ ] Symbolic execution for edge case detection
- [ ] ML-based test generation
- [ ] Self-healing tests (auto-repair flaky tests)
- [ ] Mutation testing for coverage quality
- [ ] Property-based testing for all data structures
- [ ] Continuous load testing in production
- [ ] Automated chaos engineering (daily)
- [ ] Game days (quarterly simulated disasters)

---

*This testing strategy is a living document. All changes require ADR review.*
