# Validation evidence

Validated 2026-10-05 using Terraform 1.15.7 and cached AWS provider 5.100.0. Initial latest AWS provider download hit local disk limits; existing compatible provider cache was reused without modifying consumer constraints.

- Pre-change native regression failed on missing count definitions and the actual old duration alarm source.
- Post-change native mocked plan suite: 10 passed, 0 failed.
- Rendered-plan verification checked actual AWS filter/metric/alarm resources for all ten cases, including one count filter per query log, default1/0/Count, actual Sum/5/300s/gte, explicit overrides and unchanged duration filters/values/units.
- AWS logs:TestMetricFilter: 31 cases passed (11 PostgreSQL at3000ms, 11 at1500ms, 9 MySQL/MariaDB layouts). No metric/filter/log mutation was performed.
- Root and independent example terraform validate passed after backend-disabled initialization.
- Touched-file terraform fmt and git diff --check passed.
- tflint reports exactly the same three warnings on origin/main and the change: missing root AWS provider constraint, missing Terraform required_version, unused db_subnet_group_use_name_prefix. No new lint finding. Baseline comparison used unchanged tracked module source.
- terraform-docs generation succeeds; no input/output interface change is introduced.
- The local all-files commit hook's terraform_docs step rewrites table separator formatting across unrelated baseline READMEs. Those generated changes were restored; that step alone was skipped for the commit after successful documentation generation, while all remaining commit hooks ran.
- New credential-free CI job runs validate and native/rendered plan checks; AWS parser tests remain an explicit read-only check.

Limits: positive filters use synthetic log fixtures. Retained90-day PostgreSQL scan had no actual duration entries. MySQL/MariaDB count assumes normal one-query CloudWatch event boundaries and server slow-log eligibility; extra logging modes/session overrides must be reviewed. Production apply, consumer state migration, notifications and real metric observations are not performed or claimed.

Rollout evidence required: exact consumer plan with old/new alarm module key moved, no same-name destroy/create, no unrelated DB changes; recorded production approval; post-apply state/count/SNS checks. No release version has been published.

Delivery: [PR #69](https://github.com/dasmeta/terraform-aws-rds/pull/69) targets main from 006-slow-query-count. DS-13434 was linked and transitioned to In Review; validation and remaining rollout boundaries were recorded in Jira comments 76914 (DS-13434) and 76915 (DS-13433).

## Combined PR integration (2026-10-05)
At the operator's request, incorporate PR #70's alarm-planning correction into #69, preserving #69's main base. Do not import the storage-backport base or modify the consumer's immutable source pin.
- Imported pending-Aurora regression failed before the dependency fix on unknown metric query account IDs.
- After removing only cw_alerts' blanket database-module dependency, two pending-Aurora plans pass: all eight existing alarm IDs known with slow queries disabled, and all nine including the new count alarm known with slow queries enabled.
- All ten slow-query rendered-plan cases pass again on the combined source; the existing 31 parser fixtures are retained, with unchanged filter patterns.
- terraform validate, touched-file fmt and git diff --check pass. Database source, inputs, outputs and nested modules are unchanged by the integration. Standalone capacity lookup retains its expression/explicit dependencies.
- Independent combined-change review found no critical, important or minor defects and confirmed the original #70 source patch is preserved.
- Blocking CI now runs both regression checkers. The existing local terraform_docs hook exception remains limited to avoiding unrelated generated README separator changes.
PR #70's original branch/commit must remain available because the separate consumer archive pin references that backport; closing the redundant PR does not change that pin or apply infrastructure.
