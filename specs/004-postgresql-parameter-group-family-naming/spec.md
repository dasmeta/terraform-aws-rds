# Feature Specification: Parameter group naming includes engine family

**Feature Branch**: `004-postgresql-parameter-group-family-naming`  
**Created**: 2026-05-20  
**Status**: Implemented  
**Input**: `/speckit.specify` — Safe PostgreSQL major version upgrades without `DBParameterGroupAlreadyExists`.

## Problem Statement

Parameter groups are named:

```hcl
"${var.identifier}-${var.engine}"
```

Example: `spielerplus-wagtail-cms-test-postgres` for `engine = postgres` and versions 15 or 17.

The **family** changes on major upgrade (`postgres15` → `postgres17`), but the **name** stays the same. Terraform must replace the parameter group; AWS rejects create with **`DBParameterGroupAlreadyExists`** because the old group still exists under the same name.

## Solution

Name parameter groups with the computed family suffix:

```hcl
parameter_group_name = "${var.identifier}-${local.parameter_group_family}"
```

Examples:

| engine | engine_version | `parameter_group_family` | `parameter_group_name` (identifier `app`) |
|--------|----------------|--------------------------|-------------------------------------------|
| `postgres` | `15` | `postgres15` | `app-postgres15` |
| `postgres` | `17` | `postgres17` | `app-postgres17` |
| `aurora-postgresql` | `17.7` | `aurora-postgresql17` | `app-aurora-postgresql17` |
| `mysql` | `8.0.35` | `mysql8.0.35` | `app-mysql8.0.35` |

Aurora cluster parameter group remains `${local.parameter_group_name}-cluster` in `main.tf`.

## Module Context

- **File**: `locals.tf` — `parameter_group_name` local
- **Consumers**: `main.tf` → `module.db` / `module.db_aurora` (`db_parameter_group_*`, `db_cluster_parameter_group_*`)

## User Scenarios

### User Story 1 - PostgreSQL major upgrade (Priority: P1)

**Given** standalone RDS PostgreSQL 15 with module-created parameter group, **When** `engine_version` changes to `17`, **Then** plan creates `*-postgres17` parameter group, updates instance parameter group reference, and does **not** replace the RDS instance.

**Acceptance**:

1. PG name ends with `postgres15` / `postgres17` respectively.
2. Plan: parameter group replace/create + in-place instance update only.
3. No `DBParameterGroupAlreadyExists` on apply.

### User Story 2 - Aurora PostgreSQL (Priority: P2)

**Given** `aurora-postgresql` and `engine_version = "17.7"`, **Then** instance PG name includes `aurora-postgresql17` and cluster PG `...-cluster`.

## Requirements

- **FR-201**: `local.parameter_group_name` MUST use `local.parameter_group_family`, not `var.engine` alone.
- **FR-202**: `main.tf` references MUST remain `local.parameter_group_name` (no duplicate naming logic).
- **FR-203**: README MUST note upgrade behavior and naming pattern.

## Success Criteria

- **SC-201**: `postgres` + `17` → name suffix `postgres17`.
- **SC-202**: Major version bump changes parameter group name in plan.
- **SC-203**: `terraform validate` passes for `tests/postgres-parameter-group-naming/`.

## Migration / Breaking Change

Consumers upgrading module version will see **new parameter group resources** on first apply (name change). Plan may:

- Create new parameter group(s)
- Update RDS/Aurora to new group
- Destroy old parameter group (after detach)

Document one-time state move or apply order for production upgrades.

## Out of Scope

- Automatic parameter copying between major versions
- Blue/green RDS upgrade orchestration

## References

- [specs/002-rds-module-baseline/spec.md](../002-rds-module-baseline/spec.md)
