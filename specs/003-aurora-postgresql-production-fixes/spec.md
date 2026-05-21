# Feature Specification: Aurora PostgreSQL production fixes (monitoring & alarms)

**Feature Branch**: `003-aurora-postgresql-production-fixes` (or `002-rds-module-baseline` while bundled)  
**Created**: 2026-05-20  
**Status**: Implemented in working tree — pending commit, tag, and consumer rollout  
**Input**: `/speckit.specify` — Fix production failures deploying `aurora-postgresql` (e.g. Keycloak `prod-keycloak-aurora` on Payconomy) with `enable_full_monitoring` and/or CloudWatch alarms.

## Problem Statement

Consumers deploying **Aurora PostgreSQL** (`engine = aurora-postgresql`) hit three independent module defects that blocked plan/apply for production workloads (Payconomy Keycloak, AMS-style configs):

| ID | Symptom | Root cause |
|----|---------|------------|
| **BUG-1** | `Error: Invalid index` — `local.engine_family is ""` | `endswith(engine, "postgres")` does not match `aurora-postgresql` |
| **BUG-2** | `InvalidParameterCombination: log types 'upgrade' ... aurora-postgresql 17.7` | Full-monitoring preset exports `upgrade`; Aurora PG does not support it |
| **BUG-3** | `couldn't find resource` — `data.aws_db_instance.database[0]` | Cluster `identifier` used as DB instance id; disk alarm expression evaluated even when `module.cw_alerts` count is 0 |

Workaround before fix: `enable_full_monitoring: false`, manual `enabled_cloudwatch_logs_exports: [postgresql]`, `alarms.enabled: false`. That is not acceptable for production observability long term.

## Module Context *(mandatory)*

- **Target Module Path**: Repository root (`dasmeta/rds/aws`)
- **Files changed**:
  - `locals.tf` — `strcontains` engine family; `enable_full_monitoring_log_exports` filters `upgrade` on Aurora; `disk_alarm_default_threshold_bytes`
  - `data.tf` — `aws_db_instance` only when `alarms.enabled && !local.is_aurora`
  - `alerts.tf` — disk threshold via `local.disk_alarm_default_threshold_bytes`; `depends_on` includes `module.db_aurora`
  - `log-based-metrics.tf` — postgres detection aligned with `locals.tf` (prior fix)
  - `README.md` — consumer NOTES
- **Tests added**:
  - `tests/aurora-postgresql-full-monitoring/`
  - `tests/aurora-postgresql-alarms-disabled/`
  - `tests/aurora-postgresql-alarms-enabled/`
- **Minimum release**: Patch after **1.12.0** (e.g. **1.12.1**) — do not use registry **1.11.1** for `aurora-postgresql` + full monitoring

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Plan Aurora PostgreSQL with full monitoring (Priority: P1)

An infra engineer sets `engine = aurora-postgresql`, `enable_full_monitoring = true`, and applies without engine-family or unsupported log export errors.

**Independent Test**: `tests/aurora-postgresql-full-monitoring`

**Acceptance Scenarios**:

1. **Given** `engine = aurora-postgresql` and `enable_full_monitoring = true`, **When** `terraform plan` runs, **Then** no `Invalid index` on `prepared_configs[local.engine_family]`.
2. **Given** Aurora PostgreSQL 17.x, **When** applied, **Then** enabled log exports are `postgresql` and `iam-db-auth-error` only (no `upgrade`).
3. **Given** `enforce_client_tls = true`, **When** planned, **Then** `engine_family` is `POSTGRESQL` and TLS parameters merge.

---

### User Story 2 - Aurora alarms without DB instance lookup (Priority: P1)

An infra engineer enables `alarms.enabled = true` on an Aurora cluster using cluster `identifier` (e.g. `prod-keycloak-aurora`) without `data.aws_db_instance` failure.

**Independent Test**: `tests/aurora-postgresql-alarms-disabled`, `tests/aurora-postgresql-alarms-enabled`

**Acceptance Scenarios**:

1. **Given** Aurora + `alarms.enabled = false`, **When** planned, **Then** `data.aws_db_instance.database` has `count = 0` and plan does not read a DB instance by cluster id.
2. **Given** Aurora + `alarms.enabled = true`, **When** planned, **Then** no `aws_db_instance` data source is created; disk alarm default uses `coalesce(var.allocated_storage, 20)` GiB × 8%.
3. **Given** standalone RDS + `alarms.enabled = true`, **When** planned after instance exists, **Then** `data.aws_db_instance.database[0].allocated_storage` drives disk alarm default (unchanged behavior).

---

### User Story 3 - Consumer rollout (Priority: P2)

An infra engineer upgrades module version in YAML DSL (Payconomy `rds-aurora-keycloack.yaml`) from local path or registry tag and re-applies with full monitoring and alarms.

**Acceptance Scenarios**:

1. **Given** fixed module ref, **When** consumer sets `enable_full_monitoring: true` and `alarms.enabled: true`, **Then** `terraform plan` succeeds for existing TFC state.
2. **Given** DSL `sns_topic` name alias, **When** apply fails validation, **Then** consumer may substitute full SNS ARN (operational, not module scope).

---

### Edge Cases

- **Aurora alarm dimensions**: Default alarms still filter `DBInstanceIdentifier = var.identifier` (cluster id). Some RDS metrics may be instance-scoped; consumers may tune `alarms.custom_values` or accept cluster-level filtering.
- **Aurora disk threshold**: Without `allocated_storage`, default 20 GiB × 8% is used; set `allocated_storage` or `alarms.custom_values.disk.threshold` for accuracy.
- **Registry lag**: Published `1.12.0` may predate fixes; use git ref or **>= 1.12.1** after release.
- **Local `source` path**: YAML must omit `version` when using filesystem `source` for dev validation.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-101**: Module MUST set `engine_family = POSTGRESQL` for any engine where `strcontains(engine, "postgres")` is true, including `aurora-postgresql`.
- **FR-102**: When `enable_full_monitoring = true` and `local.is_aurora`, module MUST NOT include `upgrade` in `enabled_cloudwatch_logs_exports`.
- **FR-103**: `data.aws_db_instance.database` MUST have `count = 0` when `local.is_aurora` OR `!var.alarms.enabled`.
- **FR-104**: Disk alarm default threshold MUST NOT reference `data.aws_db_instance.database[0]` when FR-103 implies the data source does not exist (use short-circuit local).
- **FR-105**: Standalone RDS with `alarms.enabled = true` MUST continue to use instance `allocated_storage` from `aws_db_instance` for disk alarm default when custom threshold is omitted.
- **FR-106**: Module MUST document Aurora PostgreSQL requirements in README (engine family, logs, alarms).

### Non-Functional Requirements

- **NFR-101**: Change set MUST be minimal — no breaking changes to variable schema.
- **NFR-102**: `terraform validate` MUST pass for new Aurora PostgreSQL test fixtures.

## Success Criteria *(mandatory)*

- **SC-101**: `terraform plan` for Aurora PostgreSQL + `enable_full_monitoring: true` completes without `Invalid index` or `upgrade` log errors.
- **SC-102**: `terraform plan` for Aurora + `alarms.enabled` true/false completes without `couldn't find resource` for cluster identifier.
- **SC-103**: `tests/aurora-postgresql-alarms-disabled`, `tests/aurora-postgresql-alarms-enabled`, `tests/aurora-postgresql-full-monitoring` pass `terraform validate`.
- **SC-104**: `tests/alarms-disabled-postgres` (standalone) still validates — regression guard for FR-105.
- **SC-105**: Tagged release published and Payconomy Keycloak YAML can use `dasmeta/rds/aws` with `version >= 1.12.1` (or documented git ref).

## Assumptions

- Production target: `aurora-postgresql` **17.7**, provisioned mode, multi-instance (`master` + `reader` keys).
- Payconomy validates fixes via local `source: /path/to/terraform-aws-rds` before registry bump.
- Speckit baseline `002-rds-module-baseline` remains the as-built module catalog; this spec is the **targeted fix track** referenced by checklist note for `001`.

## Out of Scope

- Rewriting all CloudWatch alarms for per-Aurora-instance dimensions.
- Changing DasMeta YAML DSL generator behavior for `sns_topic` aliases.
- Greenfield module redesign (see `002`).

## References

- Baseline: [specs/002-rds-module-baseline/spec.md](../002-rds-module-baseline/spec.md)
- Consumer example: Payconomy `1-environments/prod/rds-aurora-keycloack.yaml`
