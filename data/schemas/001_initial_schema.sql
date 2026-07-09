-- Colossus Initial Database Schema
-- Database: CockroachDB (PostgreSQL-compatible)
-- Version: 1.0.0
-- Date: 2026-07-09

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
-- CORE TABLES
-- ============================================================

-- APIs: Master records for all discovered APIs
CREATE TABLE apis (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    external_id VARCHAR(255) UNIQUE NOT NULL,  -- Human-readable unique ID
    name VARCHAR(500) NOT NULL,
    description TEXT,
    provider_name VARCHAR(255),
    provider_url TEXT,
    base_url TEXT,
    protocol VARCHAR(50) NOT NULL,  -- openapi, graphql, grpc, soap, etc.
    auth_type VARCHAR(50),  -- oauth2, api_key, basic, none, etc.
    status VARCHAR(50) NOT NULL DEFAULT 'discovered',  -- discovered, validated, active, deprecated, retired
    visibility VARCHAR(20) NOT NULL DEFAULT 'public',  -- public, private, internal
    tags TEXT[],
    categories TEXT[],
    metadata JSONB DEFAULT '{}',
    version INTEGER NOT NULL DEFAULT 1,  -- Optimistic locking
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ,

    CONSTRAINT valid_status CHECK (status IN ('discovered', 'validated', 'active', 'deprecated', 'retired')),
    CONSTRAINT valid_visibility CHECK (visibility IN ('public', 'private', 'internal')),
    CONSTRAINT valid_protocol CHECK (protocol IN ('openapi', 'graphql', 'grpc', 'soap', 'rest', 'websocket', 'webhook', 'other'))
);

CREATE INDEX idx_apis_status ON apis(status);
CREATE INDEX idx_apis_protocol ON apis(protocol);
CREATE INDEX idx_apis_provider ON apis(provider_name);
CREATE INDEX idx_apis_tags ON apis USING GIN(tags);
CREATE INDEX idx_apis_categories ON apis USING GIN(categories);
CREATE INDEX idx_apis_created_at ON apis(created_at);
CREATE INDEX idx_apis_deleted_at ON apis(deleted_at) WHERE deleted_at IS NULL;

-- API Versions: Version-specific metadata
CREATE TABLE api_versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    api_id UUID NOT NULL REFERENCES apis(id) ON DELETE CASCADE,
    version VARCHAR(50) NOT NULL,
    version_semver VARCHAR(50),
    spec_hash VARCHAR(64) NOT NULL,  -- SHA-256 of normalized spec
    spec_url TEXT,  -- S3 URL to raw spec
    normalized_spec_url TEXT,  -- S3 URL to normalized spec
    changelog TEXT,
    is_latest BOOLEAN NOT NULL DEFAULT FALSE,
    breaking_changes JSONB DEFAULT '[]',
    metadata JSONB DEFAULT '{}',
    version INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ,

    CONSTRAINT unique_api_version UNIQUE (api_id, version),
    CONSTRAINT one_latest_per_api UNIQUE (api_id, is_latest) DEFERRABLE INITIALLY DEFERRED
);

CREATE INDEX idx_api_versions_api_id ON api_versions(api_id);
CREATE INDEX idx_api_versions_latest ON api_versions(api_id, is_latest) WHERE is_latest = TRUE;
CREATE INDEX idx_api_versions_created_at ON api_versions(created_at);

-- API Specs: Raw and normalized API specifications
CREATE TABLE api_specs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    api_version_id UUID NOT NULL REFERENCES api_versions(id) ON DELETE CASCADE,
    format VARCHAR(50) NOT NULL,  -- openapi_json, openapi_yaml, graphql_sdl, protobuf, wsdl, etc.
    content_hash VARCHAR(64) NOT NULL,  -- SHA-256
    storage_path TEXT NOT NULL,  -- S3 path
    size_bytes BIGINT NOT NULL,
    parsed_at TIMESTAMPTZ,
    parse_errors JSONB DEFAULT '[]',
    metadata JSONB DEFAULT '{}',
    version INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT valid_format CHECK (format IN ('openapi_json', 'openapi_yaml', 'graphql_sdl', 'protobuf', 'wsdl', 'asyncapi', 'raml', 'other'))
);

CREATE INDEX idx_api_specs_api_version ON api_specs(api_version_id);
CREATE INDEX idx_api_specs_content_hash ON api_specs(content_hash);

-- ============================================================
-- GENERATION TABLES
-- ============================================================

-- Generation Jobs: Track all generation jobs
CREATE TABLE generation_jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    job_type VARCHAR(50) NOT NULL,  -- sdk, doc, test, example, mock
    api_id UUID NOT NULL REFERENCES apis(id) ON DELETE CASCADE,
    api_version_id UUID REFERENCES api_versions(id) ON DELETE CASCADE,
    target_language VARCHAR(50),  -- typescript, python, go, etc. (NULL for non-language jobs)
    generator_version VARCHAR(50) NOT NULL,
    template_version VARCHAR(50) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'pending',  -- pending, running, completed, failed, cancelled
    priority INTEGER NOT NULL DEFAULT 5,  -- 1 (highest) to 10 (lowest)
    worker_id UUID,
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    duration_ms INTEGER,
    error_message TEXT,
    error_details JSONB DEFAULT '{}',
    input_hash VARCHAR(64) NOT NULL,  -- Hash of inputs for deduplication
    output_hash VARCHAR(64),  -- Hash of generated output
    metadata JSONB DEFAULT '{}',
    version INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT valid_job_type CHECK (job_type IN ('sdk', 'doc', 'test', 'example', 'mock', 'cli', 'tutorial')),
    CONSTRAINT valid_job_status CHECK (status IN ('pending', 'running', 'completed', 'failed', 'cancelled'))
);

CREATE INDEX idx_generation_jobs_status ON generation_jobs(status);
CREATE INDEX idx_generation_jobs_api ON generation_jobs(api_id);
CREATE INDEX idx_generation_jobs_worker ON generation_jobs(worker_id);
CREATE INDEX idx_generation_jobs_created_at ON generation_jobs(created_at);
CREATE INDEX idx_generation_jobs_input_hash ON generation_jobs(input_hash);

-- Artifacts: Generated artifact metadata
CREATE TABLE artifacts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    generation_job_id UUID NOT NULL REFERENCES generation_jobs(id) ON DELETE CASCADE,
    api_id UUID NOT NULL REFERENCES apis(id) ON DELETE CASCADE,
    api_version_id UUID REFERENCES api_versions(id) ON DELETE CASCADE,
    artifact_type VARCHAR(50) NOT NULL,  -- sdk, doc, test, example, mock, cli
    language VARCHAR(50),  -- typescript, python, go, etc.
    content_hash VARCHAR(64) NOT NULL,  -- SHA-256 (content-addressable)
    storage_path TEXT NOT NULL,  -- S3 path
    size_bytes BIGINT NOT NULL,
    file_count INTEGER NOT NULL DEFAULT 0,
    line_count INTEGER,
    is_deterministic BOOLEAN NOT NULL DEFAULT TRUE,
    validation_status VARCHAR(50) DEFAULT 'pending',  -- pending, passed, failed
    validation_results JSONB DEFAULT '{}',
    metadata JSONB DEFAULT '{}',
    version INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT valid_artifact_type CHECK (artifact_type IN ('sdk', 'doc', 'test', 'example', 'mock', 'cli', 'tutorial')),
    CONSTRAINT valid_validation_status CHECK (validation_status IN ('pending', 'passed', 'failed'))
);

CREATE INDEX idx_artifacts_api ON artifacts(api_id);
CREATE INDEX idx_artifacts_content_hash ON artifacts(content_hash);
CREATE INDEX idx_artifacts_type_lang ON artifacts(artifact_type, language);
CREATE INDEX idx_artifacts_validation ON artifacts(validation_status);

-- ============================================================
-- RELEASE TABLES
-- ============================================================

-- Releases: Track all releases
CREATE TABLE releases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    api_id UUID NOT NULL REFERENCES apis(id) ON DELETE CASCADE,
    api_version_id UUID REFERENCES api_versions(id) ON DELETE CASCADE,
    release_version VARCHAR(50) NOT NULL,
    release_type VARCHAR(20) NOT NULL,  -- major, minor, patch, pre-release
    status VARCHAR(50) NOT NULL DEFAULT 'draft',  -- draft, building, testing, publishing, published, failed
    changelog TEXT,
    migration_guide TEXT,
    breaking_changes JSONB DEFAULT '[]',
    artifacts UUID[] DEFAULT '{}',
    published_at TIMESTAMPTZ,
    metadata JSONB DEFAULT '{}',
    version INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT valid_release_type CHECK (release_type IN ('major', 'minor', 'patch', 'pre-release')),
    CONSTRAINT valid_release_status CHECK (status IN ('draft', 'building', 'testing', 'publishing', 'published', 'failed'))
);

CREATE INDEX idx_releases_api ON releases(api_id);
CREATE INDEX idx_releases_status ON releases(status);
CREATE INDEX idx_releases_published ON releases(published_at);

-- Packages: Published package metadata
CREATE TABLE packages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    release_id UUID NOT NULL REFERENCES releases(id) ON DELETE CASCADE,
    api_id UUID NOT NULL REFERENCES apis(id) ON DELETE CASCADE,
    package_name VARCHAR(255) NOT NULL,
    package_version VARCHAR(50) NOT NULL,
    registry VARCHAR(100) NOT NULL,  -- npm, pypi, maven, nuget, crates.io, etc.
    registry_url TEXT,
    artifact_id UUID REFERENCES artifacts(id),
    publish_status VARCHAR(50) NOT NULL DEFAULT 'pending',  -- pending, published, failed
    published_at TIMESTAMPTZ,
    download_count BIGINT DEFAULT 0,
    metadata JSONB DEFAULT '{}',
    version INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT valid_registry CHECK (registry IN ('npm', 'pypi', 'maven', 'nuget', 'crates.io', 'rubygems', 'packagist', 'swiftpm', 'github_packages', 'other')),
    CONSTRAINT valid_publish_status CHECK (publish_status IN ('pending', 'published', 'failed'))
);

CREATE INDEX idx_packages_api ON packages(api_id);
CREATE INDEX idx_packages_registry ON packages(registry);
CREATE INDEX idx_packages_publish_status ON packages(publish_status);

-- ============================================================
-- WORKER TABLES
-- ============================================================

-- Workers: Worker registration and heartbeat
CREATE TABLE workers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    worker_type VARCHAR(50) NOT NULL,  -- discovery, generation, validation, test, doc, publish
    hostname VARCHAR(255) NOT NULL,
    ip_address INET,
    kubernetes_pod VARCHAR(255),
    kubernetes_node VARCHAR(255),
    status VARCHAR(50) NOT NULL DEFAULT 'idle',  -- idle, busy, draining, offline
    current_job_id UUID REFERENCES generation_jobs(id),
    capabilities TEXT[],  -- languages, protocols supported
    resources JSONB DEFAULT '{}',  -- cpu, memory, disk
    last_heartbeat TIMESTAMPTZ NOT NULL DEFAULT now(),
    started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    metadata JSONB DEFAULT '{}',
    version INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT valid_worker_type CHECK (worker_type IN ('discovery', 'generation', 'validation', 'test', 'doc', 'publish')),
    CONSTRAINT valid_worker_status CHECK (status IN ('idle', 'busy', 'draining', 'offline'))
);

CREATE INDEX idx_workers_status ON workers(status);
CREATE INDEX idx_workers_type ON workers(worker_type);
CREATE INDEX idx_workers_heartbeat ON workers(last_heartbeat);

-- ============================================================
-- EVENT TABLES
-- ============================================================

-- Events: Event sourcing log (append-only)
CREATE TABLE events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_type VARCHAR(100) NOT NULL,
    aggregate_type VARCHAR(100) NOT NULL,  -- api, job, release, worker, etc.
    aggregate_id UUID NOT NULL,
    version INTEGER NOT NULL,  -- Event version within aggregate
    payload JSONB NOT NULL,
    metadata JSONB DEFAULT '{}',
    correlation_id UUID,
    causation_id UUID,
    emitted_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    emitted_by VARCHAR(255) NOT NULL,

    CONSTRAINT unique_aggregate_version UNIQUE (aggregate_type, aggregate_id, version)
);

CREATE INDEX idx_events_aggregate ON events(aggregate_type, aggregate_id);
CREATE INDEX idx_events_type ON events(event_type);
CREATE INDEX idx_events_correlation ON events(correlation_id);
CREATE INDEX idx_events_emitted_at ON events(emitted_at);

-- ============================================================
-- USER & AUTH TABLES
-- ============================================================

-- Users: Platform users
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    external_id VARCHAR(255) UNIQUE,  -- OAuth subject
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(100) UNIQUE NOT NULL,
    display_name VARCHAR(255),
    avatar_url TEXT,
    role VARCHAR(50) NOT NULL DEFAULT 'contributor',  -- admin, maintainer, contributor, viewer
    preferences JSONB DEFAULT '{}',
    last_login_at TIMESTAMPTZ,
    metadata JSONB DEFAULT '{}',
    version INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ,

    CONSTRAINT valid_role CHECK (role IN ('admin', 'maintainer', 'contributor', 'viewer'))
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_role ON users(role);

-- API Subscriptions: Users subscribed to API change notifications
CREATE TABLE api_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    api_id UUID NOT NULL REFERENCES apis(id) ON DELETE CASCADE,
    notify_on_breaking BOOLEAN NOT NULL DEFAULT TRUE,
    notify_on_minor BOOLEAN NOT NULL DEFAULT FALSE,
    notify_on_patch BOOLEAN NOT NULL DEFAULT FALSE,
    channels TEXT[] DEFAULT '{"email"}',  -- email, webhook, slack
    webhook_url TEXT,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT unique_user_api_subscription UNIQUE (user_id, api_id)
);

CREATE INDEX idx_api_subscriptions_user ON api_subscriptions(user_id);
CREATE INDEX idx_api_subscriptions_api ON api_subscriptions(api_id);

-- ============================================================
-- AUDIT TABLES
-- ============================================================

-- Audit Log: All user actions
CREATE TABLE audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    action VARCHAR(100) NOT NULL,
    actor_type VARCHAR(50) NOT NULL,  -- user, system, worker
    actor_id UUID,
    target_type VARCHAR(100) NOT NULL,
    target_id UUID,
    details JSONB DEFAULT '{}',
    ip_address INET,
    user_agent TEXT,
    success BOOLEAN NOT NULL,
    error_message TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_audit_action ON audit_log(action);
CREATE INDEX idx_audit_actor ON audit_log(actor_type, actor_id);
CREATE INDEX idx_audit_target ON audit_log(target_type, target_id);
CREATE INDEX idx_audit_created_at ON audit_log(created_at);

-- ============================================================
-- TRIGGERS
-- ============================================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_apis_updated_at BEFORE UPDATE ON apis
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_api_versions_updated_at BEFORE UPDATE ON api_versions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_api_specs_updated_at BEFORE UPDATE ON api_specs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_generation_jobs_updated_at BEFORE UPDATE ON generation_jobs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_artifacts_updated_at BEFORE UPDATE ON artifacts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_releases_updated_at BEFORE UPDATE ON releases
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_packages_updated_at BEFORE UPDATE ON packages
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_workers_updated_at BEFORE UPDATE ON workers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_api_subscriptions_updated_at BEFORE UPDATE ON api_subscriptions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- PARTITIONING (for high-volume tables)
-- ============================================================

-- Partition events table by month
CREATE TABLE events_partitioned (
    LIKE events INCLUDING ALL
) PARTITION BY RANGE (emitted_at);

-- Create partitions for current and next 12 months
-- (Run migration script to create future partitions)

-- Partition audit_log by month
CREATE TABLE audit_log_partitioned (
    LIKE audit_log INCLUDING ALL
) PARTITION BY RANGE (created_at);

-- ============================================================
-- ROW-LEVEL SECURITY
-- ============================================================

ALTER TABLE apis ENABLE ROW LEVEL SECURITY;
ALTER TABLE api_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE artifacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE releases ENABLE ROW LEVEL SECURITY;

-- Policies will be created by auth framework
-- Example: CREATE POLICY api_tenant_isolation ON apis USING (tenant_id = current_setting('app.current_tenant')::UUID);

-- ============================================================
-- INITIAL DATA
-- ============================================================

-- System user
INSERT INTO users (id, email, username, display_name, role)
VALUES (
    '00000000-0000-0000-0000-000000000000',
    'system@colossus.internal',
    'system',
    'System',
    'admin'
);
