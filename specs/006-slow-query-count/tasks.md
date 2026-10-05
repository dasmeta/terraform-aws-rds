# Tasks: Count actual RDS slow queries

Input: [spec.md](spec.md), [plan.md](plan.md), research, contract and quickstart. Execute through speckit-implement.

## Phase 1: Setup
- [x] T001 Confirm current upstream and read module requirements in specs/006-slow-query-count/spec.md.
- [x] T002 Produce approved design and compatibility boundaries in specs/006-slow-query-count/plan.md.

## Phase 2: Foundation
- [x] T003 Initialize root module dependencies and write plan regression tests in tests/slow-query-count.tftest.hcl; demonstrate failure before source edits.

## Phase 3: US1 - Trust slow-query alerts
- [x] T004 [US1] Add effective count filter and alarm definitions in locals.tf.
- [x] T005 [US1] Append count metric only to the query-log group in log-based-metrics.tf and consume alarm in alerts.tf.
- [x] T006 [US1] Add generic PostgreSQL/MySQL/MariaDB fixtures in tests/fixtures/slow-query-logs.json and read-only AWS runner tests/verify-slow-query-filters.py.
- [x] T007 [US1] Run native plans and filter fixtures to verify count/threshold/log formats and negatives.

## Phase 4: US2 - Upgrade without losing monitoring intent
- [x] T008 [US2] Verify duration telemetry, overrides, disabled settings and extra log exports in tests/slow-query-count.tftest.hcl.
- [x] T009 [US2] Document new metric, limitations and state migration/rollback in README.md; add independent example in examples/slow-query-count/.

## Phase 5: Closeout
- [x] T010 Run validate, touched-file fmt, native tests, fixture API tests and diff review; record evidence in specs/006-slow-query-count/validation.md.
- [x] T011 Commit, publish branch, open PR and link DS-13434; update Jira with real validation and remaining rollout boundaries.

## Dependencies and execution
T001 -> T002 -> T003 -> T004/T005 -> T006/T007 -> T008/T009 -> T010 -> T011. US2 depends on the count implementation but independently checks compatibility. Fixture/documentation work can be independent once definitions settle; no additional delegated code work is needed.

## Strategy
Deliver a focused shared-module correction and reviewable PR. Release/adoption/apply and runtime observation are outside this task. Never apply the mocked plans or deliberately generate production slow queries.
