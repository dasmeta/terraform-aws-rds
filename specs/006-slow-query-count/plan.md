# Implementation Plan: Count actual RDS slow queries

**Branch**: `006-slow-query-count` | **Date**: 2026-10-05 | **Spec**: [spec.md](spec.md)
**Scope**: dasmeta/terraform-aws-rds root module; DS-13434. Operator authorized implementation and PR creation.

## Summary
Preserve existing duration filters unchanged. Append a dedicated RDSSlowQueryCount metric only to the engine query-log group: value 1, default 0, Count units. PostgreSQL matches statement/execute entries with duration >= slow_queries.query_duration*1000. MySQL/MariaDB count Query_time headers using one anchored regex, relying on the server's configured long_query_time. Alarm uses Sum and five actual logged slow statements per five minutes; existing explicit overrides retain priority.

## Technical Context
Terraform HCL, existing AWS wrappers and monitoring modules 1.13.2/1.3.5. No dependency or provider constraint upgrades. Plan-only native tests require Terraform >=1.7 for mocks; local CLI 1.15.7. Filter tests use AWS test-metric-filter only, with synthetic fixtures. Retained PostgreSQL logs contain no positive duration examples.

## Constitution Check
- Speckit stages invoked: specify -> plan -> tasks -> implement. Corresponding downstream artifacts precede source edits.
- This repository stores feature metadata but not Speckit scripts/templates. Invoke canonical constitution scripts from the downstream repository with SPECIFY_FEATURE; use shared templates directly. No copied cross-repository governance.
- Shared governance: constitution/workflows/speckit-module-change-gate.md and skills/terraform-module-developer/references/internal-module-standards.md. Minimum spec/plan/tasks gate evidence will be included.
- Existing opinionated wrapper and grouped input required/optional contracts preserved. No new input/output, no interface widening, no provider version change.
- New module sourcing is inapplicable; retain the existing upstream wrappers. Modern-capabilities rule is inactive for this correction to established monitoring.
- Existing baseline gaps: runnable cases but no native tests on main, no examples directory, no explicit root provider constraints, existing CI test continue-on-error. Add focused native tests and a matching example; defer unrelated baseline work.
- Bootstrap scope limited to local use of missing template/script support; .specify already exists. Existing upstream spec 005 on the open storage PR is considered when choosing 006.
- Source preparation is authorized by user. No production apply or release publishing. No conflicting user/core module requirement remains.

## Research and design
See [research.md](research.md), [data-model.md](data-model.md) and [module contract](contracts/module-interface.md). Preserve duration telemetry and alarm human name. Count source changes the nested monitoring for_each state key; require explicit consumer moved block before upgrade. Generic monitoring module behavior remains unchanged.

## Project Structure
- locals.tf: effective count metric, engine log type and slow-query alarm definition.
- log-based-metrics.tf: append count definition to the appropriate existing filter module instance.
- alerts.tf: consume the effective slow-query alarm.
- tests/slow-query-count.tftest.hcl: root module mocked plan cases.
- tests/fixtures/slow-query-logs.json and tests/verify-slow-query-filters.py: AWS filter contract checks.
- examples/slow-query-count/{0-setup.tf,1-example.tf}: consumer usage independent of tests.
- README.md: semantics, verification commands, limitations, rollout/state migration and rollback.
- specs/006-slow-query-count/: corresponding Spec Kit evidence.

## Validation
Write native plan regressions before source edits and confirm failure. Mock AWS and override database child modules; inspect effective metric/alert definitions and rendered alarm keys. Cases cover PostgreSQL/Aurora, MySQL/MariaDB, fractional thresholds, explicit overrides, disabled monitoring/alarms and additional log exports. Execute AWS filter fixture tests against rendered patterns, including exact boundary, prepared statements, checkpoint/reload, separate/full MySQL/MariaDB headers and multiline SQL. Initialize with backend disabled, run validate, touched-file fmt, native tests and diff checks. No live apply.

## Rollout and rollback
Preserve old duration metric names/values/units and filters. A count metric is added; alarm source changes while its AWS name stays the same. Consumer moved block must migrate the complete nested module instance from the old name/source key to the new one; reject destroy/create against the same alarm name. Inspect real production plan and obtain exact-plan approval before apply. Default PostgreSQL threshold changes 7 -> 5 to remove the old +2 compensation; explicit overrides retain priority. Roll back with reviewed reverse state migration and module version pin. Observe count samples, SNS actions and state after apply. No historical count metric backfill occurs.

## Complexity Tracking
No broad refactor. MySQL/MariaDB header regex counts one qualifying log event, not an arbitrary number of headers packed in one event; it relies on server slow-log threshold and assumes normal RDS event boundaries. Numeric PostgreSQL predicate is tied to the configured module threshold and excludes Parse/Bind phases. Runtime logging overrides can change eligibility and must be reviewed by consumers.
