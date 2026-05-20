# Feature Specification: dasmeta/rds/aws module baseline (as-built)

**Feature Branch**: `002-rds-module-baseline`  
**Created**: 2026-05-20  
**Status**: Baseline — partially validated (see `tasks.md` completion notes)  
**Input**: `/specify.spec` — Analyze existing Terraform module; use current `*.tf`, README, examples, and tests as source of truth, not greenfield.

## Module Context *(mandatory)*

- **Target Module Path**: Repository root (`dasmeta/rds/aws`)
- **Related Files In Scope**:
  - Core: `main.tf`, `locals.tf`, `variables.tf`, `output.tf`, `data.tf`
  - Networking: `security-group.tf`
  - Observability: `alerts.tf`, `log-based-metrics.tf`
  - Submodules: `modules/proxy`, `modules/scheduled-scale`, `modules/proxysql` (optional consumer-facing add-on)
  - Docs/tests: `README.md`, `tests/*`
- **Upstream Baseline**:
  - Standalone RDS: `terraform-aws-modules/rds/aws` **6.12.0** (`module.db`)
  - Aurora: `terraform-aws-modules/rds-aurora/aws` **9.15.0** (`module.db_aurora`)
  - Security group: `terraform-aws-modules/security-group/aws` **5.2.0**
  - Alerts: `dasmeta/monitoring/aws//modules/alerts` **1.3.5**
  - Log metrics: `dasmeta/monitoring/aws//modules/cloudwatch-log-based-metrics` **1.13.2**
- **Requested Interface Change**: None — this spec documents **current** behavior
- **Breaking Change / Interface Widening**: N/A (baseline capture)

## Architecture Summary *(as-built)*

The module is a **wrapper** that selects one database topology based on `engine`:

| Condition | Active submodule | AWS product |
|-----------|----------------|-------------|
| `startswith(engine, "aurora")` | `module.db_aurora` (count=1) | Aurora cluster |
| Otherwise | `module.db` (count=1) | RDS instance |

**Engine family** (`MYSQL` / `POSTGRESQL`) drives ports, prepared parameter sets, CloudWatch log exports, and RDS Proxy `engine_family`. Detection uses `strcontains(engine, "postgres")` for PostgreSQL family and mysql/mariadb rules for MySQL family.

**Optional add-ons** (independent `count`):

- `module.security_group` — when `create_security_group = true`
- `module.cw_alerts` — when `alarms.enabled = true`
- `module.cloudwatch_metric_filters` — when slow queries enabled (per log export type)
- `module.scheduled_scale` — Aurora autoscaling schedules
- `module.proxy` — RDS Proxy when `proxy.enabled = true`

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Provision standalone RDS (Priority: P1)

An infra engineer deploys a single RDS instance (MySQL, MariaDB, or PostgreSQL) with subnet group, optional created security group, backups, and encryption using required `identifier`, `subnet_ids`, and `alarms.sns_topic`.

**Independent Test**: `tests/basic-postgres`, `tests/slow-queries-mysql`, `tests/parameters-mysql`

**Acceptance Scenarios**:

1. **Given** `engine` not starting with `aurora`, **When** applied, **Then** only `module.db` is created and instance outputs are populated.
2. **Given** `create_security_group = true` and `vpc_id`, **When** applied, **Then** DB port is reachable from VPC CIDR (when `set_vpc_security_group_rules = true`).

---

### User Story 2 - Provision Aurora cluster (Priority: P1)

An infra engineer deploys Aurora (MySQL or PostgreSQL) with cluster + instance parameter groups, optional reader autoscaling, and Aurora-specific outputs (`cluster_endpoint`, `cluster_reader_endpoint`).

**Independent Test**: `tests/basic-aurora-mysql`, `tests/aurora-cluster-read-replica`, `tests/enforce-client-tls` (aurora-postgresql)

**Acceptance Scenarios**:

1. **Given** `engine = aurora-*`, **When** applied, **Then** `module.db_aurora` is created and cluster endpoints are output.
2. **Given** `aurora_configs.instances` includes at least one member (e.g. `master = {}`), **When** applied, **Then** cluster has defined instances per map keys.
3. **Given** `aurora_configs.autoscaling.enabled = true`, **When** applied, **Then** Application Auto Scaling targets reader capacity.

---

### User Story 3 - Enforce TLS and slow-query observability (Priority: P2)

An infra engineer enables client TLS (`enforce_client_tls`, default `true`) and slow-query logging/alarms (`slow_queries`, default enabled) without hand-writing engine-specific parameter and log export lists.

**Independent Test**: `tests/enforce-client-tls`, `tests/slow-queries-postgres`, `tests/slow-queries-mysql`

**Acceptance Scenarios**:

1. **Given** PostgreSQL family engine, **When** `enforce_client_tls = true`, **Then** `rds.force_ssl` is merged into cluster/instance parameter groups.
2. **Given** slow queries enabled, **When** applied, **Then** engine-appropriate CloudWatch log exports and log-based metric filters are created.

---

### User Story 4 - One-shot full monitoring (Priority: P2)

An infra engineer sets `enable_full_monitoring = true` to enable Performance Insights, Database Insights (advanced), enhanced monitoring, extended log exports, and related parameters in one flag.

**Independent Test**: `tests/aurora-mysql-with-full-monitoring-enabled`, `tests/instance-performance-insights-enabled`, `tests/aurora-cluster-database-insights-enabled`

**Acceptance Scenarios**:

1. **Given** `enable_full_monitoring = true` and a recognized engine family, **When** planned, **Then** monitoring-related locals resolve without invalid map index errors.
2. **Given** Aurora PostgreSQL + full monitoring, **When** using module **>= 1.11.2**, **Then** `engine_family` resolves to `POSTGRESQL` (see README NOTE).

---

### User Story 5 - RDS Proxy attachment (Priority: P3)

An infra engineer adds connection pooling via RDS Proxy after the database exists, using Secrets Manager for credentials when RDS manages the master password.

**Independent Test**: `tests/basic-aurora-mysql-and-proxy`, `tests/postgres-instance-proxy`

**Acceptance Scenarios**:

1. **Given** `proxy.enabled = true`, **When** applied after DB exists, **Then** proxy targets cluster or instance per `target_db_cluster` and `is_aurora`.
2. **Given** README two-step note, **When** first apply has proxy disabled, **Then** initial DB creation succeeds before proxy enablement.

---

### User Story 6 - CloudWatch operational alarms (Priority: P3)

An infra engineer receives SNS notifications for CPU, memory, storage, IOPS, latency, connections, and optional slow-query log metrics.

**Independent Test**: `tests/alarms-disabled-postgres`, `tests/alarms-full-modified-postgres`, `tests/alarms-some-modified-postrges`

**Acceptance Scenarios**:

1. **Given** `alarms.enabled = true` and `alarms.sns_topic`, **When** applied, **Then** `module.cw_alerts` provisions default RDS alarms filtered by `identifier`.
2. **Given** `alarms.custom_values`, **When** applied, **Then** thresholds/periods override defaults.

---

### Edge Cases

- **Engine family unknown**: Empty `engine_family` breaks `prepared_configs[...]` lookups when slow queries or full monitoring need engine-specific presets.
- **Aurora destroy with autoscaling**: Auto-scaled readers may block destroy unless scaled down manually (README upgrade guide).
- **Static parameters**: `apply_method = pending-reboot` params require instance restart outside Terraform.
- **Alarms on Aurora**: Filters use `DBInstanceIdentifier = var.identifier` (cluster id); per-instance alarm naming may differ from instance-level IDs.
- **Public access**: `publicly_accessible = true` adds broad ingress; instances must use public subnets.
- **Proxy + managed password**: `credentials_secret_arn` from RDS master user secret when `manage_master_user_password = true`.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Module MUST expose exactly one active database backend: RDS instance **or** Aurora cluster, never both.
- **FR-002**: Module MUST require `identifier`, `subnet_ids`, and `alarms.sns_topic` (alarms object).
- **FR-003**: Module MUST support engines: standalone (`mysql`, `postgres`, `mariadb`, …) and Aurora (`aurora-mysql`, `aurora-postgresql`, …) via `engine` / `engine_version`.
- **FR-004**: Module MUST optionally create a VPC security group with merged ingress/egress (user rules + VPC CIDR on DB port + optional `0.0.0.0/0` if `publicly_accessible`).
- **FR-005**: Module MUST merge prepared and user `parameters` separately for `context = instance` vs `context = cluster` (Aurora cluster PG gets TLS on cluster map).
- **FR-006**: Module MUST support `enable_full_monitoring` shortcut that sets insights, monitoring interval, log exports, and engine-specific parameters.
- **FR-007**: Module MUST support `slow_queries` (default on) with log exports and optional slow-query CloudWatch alarm via log-based metrics.
- **FR-008**: Module MUST support `enforce_client_tls` (default on) with engine-specific SSL parameters.
- **FR-009**: Module MUST support Aurora `aurora_configs` (engine_mode, instances map, autoscaling, scheduled autoscaling via `modules/scheduled-scale`).
- **FR-010**: Module MUST optionally deploy RDS Proxy via `modules/proxy` with `engine_family` MYSQL/POSTGRESQL.
- **FR-011**: Module MUST output instance endpoints for RDS and cluster endpoints (writer, reader, instance suffix) for Aurora.
- **FR-012**: Module MUST output sensitive `db_password` when supplied by consumer.

### Compatibility & Delivery Requirements

- **CDR-001**: Validation coverage documented under `tests/` (17 scenarios): postgres/mysql/aurora, TLS, slow queries, alarms, proxy, PI, database insights, scheduled autoscale, parameters.
- **CDR-002**: CI: `.github/workflows/terraform-test.yaml`, `pre-commit`, `tflint`, `tfsec`, `checkov`.
- **CDR-003**: Consumer examples live in `tests/*/1-example.tf` and README Cases 1–2.
- **CDR-004**: Upgrade notes in README for module version migrations (1.4.0, 1.7.0 aurora autoscaling, 1.11.2 aurora-postgresql monitoring).

### Key Entities

| Entity | Purpose |
|--------|---------|
| `engine` / `engine_version` | Selects RDS vs Aurora and parameter group family |
| `aurora_configs` | Cluster topology, autoscaling, serverless v2 config |
| `proxy` | RDS Proxy enablement and auth |
| `alarms` | SNS topic + optional custom metric thresholds |
| `slow_queries` | Duration threshold + enable flag |
| `parameters[]` | User overrides with `context` and `apply_method` |
| `enable_full_monitoring` | Bundled observability preset |

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A new consumer can deploy each documented topology using README + `tests/` examples without undeclared manual steps.
- **SC-002**: All repository CI checks defined in `.github/workflows/` pass on `main`.
- **SC-003**: Engine family detection supports `postgres`, `aurora-postgresql`, and mysql-family engines for monitoring/TLS/slow-query presets.
- **SC-004**: Aurora and standalone outputs are documented and match applied infrastructure endpoints.

## Assumptions

- Baseline captured on branch containing `strcontains` postgres engine-family fix and README **>= 1.11.2** note.
- `modules/proxysql` is a separate Helm/K8s-oriented submodule, not part of the core RDS/Aurora wrapper path unless explicitly invoked by consumers.
- Default `engine = mysql` and `engine_version = 5.7.26` reflect legacy defaults; production consumers override.

## Test Coverage Map *(baseline reference)*

| Test directory | Validates |
|----------------|-----------|
| `basic-postgres` | Standalone PostgreSQL |
| `basic-aurora-mysql` | Aurora MySQL + autoscaling |
| `aurora-cluster-read-replica` | Aurora PostgreSQL replica |
| `enforce-client-tls` | Aurora PostgreSQL TLS |
| `aurora-mysql-with-full-monitoring-enabled` | Full monitoring bundle |
| `aurora-cluster-database-insights-enabled` | Database Insights |
| `instance-performance-insights-enabled` | Performance Insights |
| `basic-aurora-mysql-and-proxy` / `postgres-instance-proxy` | RDS Proxy |
| `basic-aurora-mysql-with-scheduled-auto-slace` | Scheduled autoscale |
| `slow-queries-*` | Slow query logs/alarms |
| `alarms-*` | CloudWatch alarms |
| `parameters-mysql` | Custom parameters |
| `aurora-postgresql-full-monitoring` | Aurora PostgreSQL + `enable_full_monitoring` (>= 1.11.2) |
