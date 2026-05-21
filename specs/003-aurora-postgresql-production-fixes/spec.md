# Feature Specification: Aurora PostgreSQL production fixes (monitoring & alarms)

**Feature Branch**: `003-aurora-postgresql-production-fixes`  
**Created**: 2026-05-20  
**Last updated**: 2026-05-20  
**Status**: Implemented and validated (Payconomy Keycloak local apply); release **>= 1.12.1**  
**Input**: `/speckit.specify` — Fix production failures for `aurora-postgresql` (Payconomy `prod-keycloak-aurora`) with `enable_full_monitoring` and `alarms.enabled = true`.

## Problem Statement

Consumers deploying **Aurora PostgreSQL** hit four defects on module versions **<= 1.12.0**:

| ID | Symptom | Root cause |
|----|---------|------------|
| **BUG-1** | `Error: Invalid index` — `local.engine_family is ""` | `endswith(engine, "postgres")` does not match `aurora-postgresql` |
| **BUG-2** | `InvalidParameterCombination: log types 'upgrade' ... aurora-postgresql 17.7` | Full-monitoring preset exports `upgrade`; Aurora PG does not support it |
| **BUG-3** | `couldn't find resource` — `data.aws_db_instance.database[0]` | Cluster `identifier` used as DB instance id for disk alarm / data source |
| **BUG-4** | `Provider produced inconsistent final plan` on `aws_cloudwatch_metric_alarm` (TFC) | Alarms used `DBInstanceIdentifier = cluster id` + `EBSIOBalance%` on Aurora; `metric_query` / `account_id` drift at apply |

Pre-fix workaround: `enable_full_monitoring: false`, manual log exports, `alarms.enabled: false`.

## Solution Summary *(as-built)*

| Area | Aurora behavior | Standalone RDS behavior |
|------|-----------------|-------------------------|
| Engine family | `strcontains(engine, "postgres")` → `POSTGRESQL` | Unchanged |
| Full monitoring logs | `postgresql`, `iam-db-auth-error` (no `upgrade`) | Includes `upgrade` where supported |
| `data.aws_db_instance` | `count = 0` | `count = 1` when `alarms.enabled` |
| CloudWatch alarm dimensions | `DBClusterIdentifier = var.identifier` | `DBInstanceIdentifier = var.identifier` |
| EBS IO balance alarm | **Omitted** | **Included** |
| Alarm name prefix | `Cluster` | `Instance` |

## Module Context *(mandatory)*

- **Target Module Path**: Repository root (`dasmeta/rds/aws`)
- **Files changed**:
  - `locals.tf` — engine family; `enable_full_monitoring_log_exports`; `disk_alarm_default_threshold_bytes`; `alarms_metric_filters`; `alarms_resource_label`
  - `data.tf` — `aws_db_instance` guarded for Aurora
  - `alerts.tf` — Aurora-aware alarm list; conditional EBS alarm
  - `log-based-metrics.tf` — postgres detection (prior)
  - `README.md` — consumer NOTES
- **Tests**:
  - `tests/aurora-postgresql-full-monitoring/`
  - `tests/aurora-postgresql-alarms-disabled/`
  - `tests/aurora-postgresql-alarms-enabled/`
- **Minimum release**: **>= 1.12.1** (document **1.12.2** if tagging next patch)

## Production Validation *(Payconomy Keycloak)*

**Workspace**: `1-environments_prod_rds-aurora-keycloack`  
**Cluster**: `prod-keycloak-aurora` (Aurora PostgreSQL 17.7)  
**Module**: `1.12.1` with `alarms.enabled: true`

**Observed apply (local, remote state):**

- Plan: **9 to add**, **10 to destroy**, **1 to change** (alarm migration + minor PG)
- Destroyed: 10 × `... on Instance ...` alarms (`DBInstanceIdentifier`, incl. EBS)
- Created: 9 × `... on Cluster ...` alarms (`DBClusterIdentifier`, no EBS)
- Apply: **all cluster alarms `Creation complete`** — no `inconsistent final plan`

**Implication for Terraform Cloud:** After this state migration, TFC should plan **zero** alarm replacements if it uses the same state and **>= 1.12.1**. TFC failures on **1.12.0** with `alarms.enabled: true` are expected until upgraded.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Aurora PostgreSQL full monitoring (Priority: P1)

**Test**: `tests/aurora-postgresql-full-monitoring`

1. **Given** `enable_full_monitoring = true` and `engine = aurora-postgresql`, **When** planned, **Then** no `Invalid index` on `engine_family`.
2. **Given** Aurora PostgreSQL 17.x, **When** applied, **Then** log exports exclude `upgrade`.

---

### User Story 2 - Aurora alarms enabled (Priority: P1)

**Test**: `tests/aurora-postgresql-alarms-enabled`

1. **Given** Aurora + `alarms.enabled = true`, **When** planned, **Then** no `aws_db_instance` data source; filters use `DBClusterIdentifier`.
2. **Given** Aurora + `alarms.enabled = true`, **When** applied, **Then** no `EBSIOBalance%` alarm; no `inconsistent final plan` on standard AWS provider (validated Keycloak).
3. **Given** upgrade from 1.12.0 alarms, **When** applied, **Then** old `Instance` alarms destroyed and `Cluster` alarms created (one-time migration).

---

### User Story 3 - Aurora alarms disabled (Priority: P2)

**Test**: `tests/aurora-postgresql-alarms-disabled`

1. **Given** Aurora + `alarms.enabled = false`, **When** planned, **Then** `module.cw_alerts` count is 0 and no `aws_db_instance` lookup.

---

### User Story 4 - Standalone RDS regression (Priority: P1)

**Test**: `tests/alarms-disabled-postgres`, existing `alarms-*` tests

1. **Given** `engine = postgres` (non-Aurora), **When** `alarms.enabled = true`, **Then** `DBInstanceIdentifier` and EBS alarm unchanged.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-101**: `engine_family = POSTGRESQL` when `strcontains(engine, "postgres")`.
- **FR-102**: Omit `upgrade` from full-monitoring log exports when `local.is_aurora`.
- **FR-103**: `data.aws_db_instance.database` has `count = 0` when `local.is_aurora` OR `!var.alarms.enabled`.
- **FR-104**: Disk alarm threshold MUST short-circuit away from `data.aws_db_instance.database[0]` when FR-103 applies.
- **FR-105**: Standalone RDS disk alarm MUST use `aws_db_instance.allocated_storage` when alarms enabled.
- **FR-106**: README MUST document Aurora vs RDS alarm dimensions and minimum version.
- **FR-107**: Aurora alarms MUST use `local.alarms_metric_filters = { DBClusterIdentifier = var.identifier }`.
- **FR-108**: Aurora alarms MUST NOT include `EBSIOBalance%` preset.
- **FR-109**: Alarm display names MUST use `Cluster` vs `Instance` per `local.alarms_resource_label`.

### Non-Functional Requirements

- **NFR-101**: No breaking changes to variable schema.
- **NFR-102**: `terraform validate` passes on Aurora alarm test fixtures.

## Success Criteria *(mandatory)*

- **SC-101**: Aurora + `enable_full_monitoring: true` plans/applies without `Invalid index` or `upgrade` errors.
- **SC-102**: Aurora + `alarms.enabled: true` plans/applies without `aws_db_instance` not found.
- **SC-103**: Aurora + `alarms.enabled: true` applies without TFC-style `inconsistent final plan` on cluster alarms (Keycloak validated).
- **SC-104**: One-time migration: 10 old Instance alarms → 9 Cluster alarms documented for consumers upgrading from 1.12.0.
- **SC-105**: Registry release **>= 1.12.1** published; Payconomy uses `version: 1.12.1` (not local path) in prod YAML.

## Consumer YAML *(reference)*

```yaml
source: dasmeta/rds/aws
version: 1.12.1   # or >= 1.12.2 when tagged

variables:
  engine: aurora-postgresql
  engine_version: "17.7"
  identifier: prod-keycloak-aurora
  alarms:
    enabled: true
    sns_topic: "account-alarms-handling"   # or full SNS ARN
  # enable_full_monitoring: true   # optional; safe on >= 1.12.1
```

**Local dev only** (omit `version`):

```yaml
source: /Users/arsengspeyan/terraform-aws-rds
```

## Edge Cases

- **Alarm migration**: Resource addresses in state change (module key includes alarm name); expect destroy/create on first apply after upgrade, not in-place rename.
- **Slow-query alarm**: Name changes `Instance` → `Cluster`; metric `RDSLogBasedMetrics/...` unchanged.
- **TFC after local migration**: Shared remote state → TFC plan should be quiet for alarms.
- **Provider version**: Pin same `hashicorp/aws` in TFC and local if drift appears.
- **Per-instance Aurora metrics**: Cluster-level alarms only; use `alarms.custom_values` or external monitoring for per-instance IDs.

## Out of Scope

- Per-instance Aurora alarm fan-out
- DasMeta DSL `sns_topic` alias resolution
- Bumping `dasmeta/monitoring/aws` alerts module version (stays 1.3.5 unless separate ticket)

## References

- Baseline: [specs/002-rds-module-baseline/spec.md](../002-rds-module-baseline/spec.md)
- Payconomy: `1-environments/prod/rds-aurora-keycloack.yaml`
