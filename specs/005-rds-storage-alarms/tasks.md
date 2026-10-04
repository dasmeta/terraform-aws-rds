# Tasks: Correct storage alarms
## Setup
- [x] T001 Query CloudBrowser and read DS-13363; create DS-13398 implementation record.
- [x] T002 Create isolated upstream-based worktrees and specs/005-rds-storage-alarms/spec.md.
- [x] T003 Complete plan.md, research.md and contracts/storage-alarm.md.
## US1 — Aurora storage
- [x] T004 [US1] Add failing Aurora regression plan in tests/storage-alarms.tftest.hcl.
- [x] T005 [US1] Implement effective storage alarm in locals.tf and forward it from alerts.tf.
- [x] T006 [US1] Test Aurora overrides and Serverless/mixed support in tests/storage-alarms.tftest.hcl.
## US2 — Preserve standalone
- [x] T007 [US2] Verify standalone 8% defaults and alarms-disabled paths in tests/storage-alarms.tftest.hcl.
## Delivery
- [x] T008 Document behavior/rollout in README.md and verify fmt, validate, tests and diff.
- [ ] T009 Obtain independent review, commit fix and open linked module PR.
- [ ] T010 Prepare immutable Sela adoption and deployment/readback checks; publish linked consumer MR when validation permits.
- [ ] T011 Update CloudBrowser Documentation 240 and Jira with delivery evidence and remaining rollout requirements.
Dependencies: T004 -> T005 -> T006/T007 -> T008 -> T009 -> T010 -> T011.
Execution: sequential; research/review can run independently. Module PR is the first deliverable, followed by consumer rollout.
