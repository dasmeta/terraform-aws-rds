# Research: dasmeta/rds/aws module baseline

**Date**: 2026-05-20  
**Spec**: [spec.md](./spec.md)

## R1 — Engine routing (RDS vs Aurora)

**Decision**: Use `local.is_aurora = startswith(var.engine, "aurora")` to enable exactly one of `module.db` or `module.db_aurora` via `count`.  
**Rationale**: Matches AWS product split; single variable surface for consumers.  
**Alternatives considered**: Separate modules per product (rejected — duplicates variables and docs).

## R2 — Engine family detection

**Decision**: `strcontains(var.engine, "postgres")` → `POSTGRESQL`; mysql/mariadb/contains mysql → `MYSQL`.  
**Rationale**: `endswith(engine, "postgres")` fails for `aurora-postgresql` (suffix is `postgresql`), breaking `prepared_configs[engine_family]` when `enable_full_monitoring` is true.  
**Alternatives considered**: Explicit allowlist map (rejected — more maintenance than substring rule).

## R3 — Parameter group merging

**Decision**: Separate merge paths for `context = instance` vs `context = cluster`; TLS on cluster map for Aurora.  
**Rationale**: Aurora has cluster-level and instance-level parameter groups; `enforce_client_tls` applies `rds.force_ssl` on cluster parameters for PostgreSQL.  
**Alternatives considered**: Single parameter list (rejected — wrong apply target for Aurora TLS).

## R4 — Full monitoring bundle

**Decision**: `enable_full_monitoring` toggles PI, Database Insights advanced, enhanced monitoring (60s), log exports, and engine-specific parameters via `prepared_configs`.  
**Rationale**: Reduces YAML duplication for production databases.  
**Alternatives considered**: Separate boolean per feature (rejected for common case — already overridable via individual variables).

## R5 — RDS Proxy deployment

**Decision**: Optional `module.proxy`; credentials from Secrets Manager or inline; two-step apply documented.  
**Rationale**: Proxy requires existing DB target; AWS/Terraform ordering constraint.  
**Alternatives considered**: Single apply with proxy enabled (rejected — known failure mode in README).

## R6 — CloudWatch alarms

**Decision**: `module.cw_alerts` with `DBInstanceIdentifier = var.identifier` for all metrics.  
**Rationale**: Simple filter for standalone RDS; for Aurora, `identifier` is often cluster name.  
**Alternatives considered**: Per-instance alarm dimensions (not implemented — documented as edge case in spec).

## R7 — Test layout

**Decision**: `tests/<scenario>/` with `main.tf` or `1-example.tf` + optional `0-setup.tf`; not all use `2-assert.tf`.  
**Rationale**: Historical repo layout; terraform-test workflow drives applies.  
**Alternatives considered**: Full 0-setup/1-example/2-assert everywhere (partial adoption — optional hardening).

## R8 — Registry versioning

**Decision**: Ship engine-family fix as patch **>= 1.11.2** with README NOTE.  
**Rationale**: Bugfix, no input/output change; consumers must bump version to pick up fix.  
**Alternatives considered**: Minor 1.12.0 (acceptable if team prefers larger bump).
