# Feature Specification: AWS-safe parameter group names

**Feature Branch**: `fix/mariadb-parameter-group-naming`
**Created**: 2026-10-20
**Status**: Implemented
**Input**: Fix the upstream RDS module so the latest release can create valid MariaDB parameter groups without changing the existing TeamPlus parameter group name.

## Problem Statement

The module derives custom DB and DB cluster parameter group names from the engine family. Families can contain periods, such as `mariadb11.4` or `mysql8.0.35`. Amazon RDS does not allow periods in custom parameter group names. The latest RDS module release therefore attempts to create an invalid name such as `rds-teamplus-main-mariadb11.4` and the apply fails.

The previous naming rule used the engine name for non-PostgreSQL engines. That rule produced the valid and already attached TeamPlus name `rds-teamplus-main-mariadb`. PostgreSQL family-qualified names are needed to avoid collisions during major version upgrades.

## Solution

Use the version-qualified parameter group family only for PostgreSQL engines. Keep the engine-name suffix for all other engines. Keep family selection for the AWS parameter group family separate from the resource name.

Examples for identifier `app`:

| Engine | Engine version | Parameter group family | Custom parameter group name |
|---|---|---|---|
| `postgres` | `17` | `postgres17` | `app-postgres17` |
| `aurora-postgresql` | `17.7` | `aurora-postgresql17` | `app-aurora-postgresql17` |
| `mariadb` | `11.4.10` | `mariadb11.4` | `app-mariadb` |
| `mysql` | `8.0.35` | `mysql8.0.35` | `app-mysql` |

## User Scenarios

### User Story 1 - MariaDB consumer upgrade (Priority: P1)

**Given** a MariaDB consumer with a module-created parameter group named `${identifier}-mariadb`, **When** it upgrades to the latest module, **Then** the generated DB parameter group name remains unchanged and contains only characters accepted by Amazon RDS.

**Acceptance**:

1. The TeamPlus 11.4 example name is `rds-teamplus-main-mariadb`.
2. The parameter group family remains `mariadb11.4`.
3. The upgrade does not rename the DB parameter group solely because the module version changed.

### User Story 2 - PostgreSQL major upgrade (Priority: P1)

**Given** PostgreSQL 15 with a module-created parameter group, **When** the engine version changes to 17, **Then** the parameter group name uses `postgres17` and remains distinct from the previous family name.

## Requirements

- **FR-601**: DB and DB cluster parameter group names MUST contain only letters, numbers, and hyphens, and MUST NOT end in a hyphen or contain consecutive hyphens.
- **FR-602**: Non-PostgreSQL parameter group names MUST retain the engine-name suffix for compatibility with existing consumers.
- **FR-603**: PostgreSQL and Aurora PostgreSQL parameter group names MUST retain the computed version-family suffix.
- **FR-604**: Parameter group family values MUST continue to use the engine/version family expected by AWS, including periods where the family requires them.
- **FR-605**: DB and cluster parameter group resources MUST continue to share the single computed name local, with the existing `-cluster` suffix for cluster groups.

## Success Criteria

- **SC-601**: MariaDB 11.4 uses family `mariadb11.4` and custom name `app-mariadb`.
- **SC-602**: MySQL 8.0.35 uses family `mysql8.0.35` and custom name `app-mysql`.
- **SC-603**: PostgreSQL 17 and Aurora PostgreSQL 17.x keep their existing family-qualified names.
- **SC-604**: No engine-family period is copied into a custom DB or DB cluster parameter group name.

## Migration / Compatibility

This change preserves existing non-PostgreSQL parameter group names, including TeamPlus MariaDB. PostgreSQL naming behavior is unchanged. No consumer input or resource address changes are introduced.

## Out of Scope

- Changing AWS parameter group family values.
- Changing parameter values, engine versions, or database instances.
- Renaming PostgreSQL parameter groups or altering PostgreSQL major-upgrade behavior.
- Deploying the module or applying any consumer infrastructure.

## References

- [Amazon RDS DB parameter group name constraints](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_WorkingWithParamGroups.Creating.html)
- [Existing PostgreSQL family naming specification](../004-postgresql-parameter-group-family-naming/spec.md)
