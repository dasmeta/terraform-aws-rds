# Tasks: Writer Read IOPS Alarm

## Phase 1: Setup

- [x] T001 Confirm production source revision and current alarm dimensions in `alerts.tf` and `infrastructure/1-environments/prod/aurora-postgres.yaml`.

## Phase 2: Foundational

- [x] T002 Confirm Aurora supports the cluster and role metric dimension in `specs/006-writer-read-iops/research.md`.

## Phase 3: User Story 1 (P1)

**Goal**: Alert on writer read load and ignore reader-only load.

**Independent test**: Check the generated ReadIOPS dimensions for Aurora and non-Aurora and compare historical metric series when credentials are available.

- [x] T003 [US1] Change Aurora ReadIOPS alarm filters in `alerts.tf` to include `Role=WRITER`.
- [x] T004 [US1] Add targeted regression verification in `tests/`.
- [x] T005 [US1] Run Terraform formatting and regression verification.

## Phase 4: Polish

- [x] T006 Update the production source pin in `infrastructure/1-environments/prod/aurora-postgres.yaml` to a published revision containing T003.
- [ ] T007 Compare November 5 reader and writer series and review a production plan when credentials are available.

## Dependencies

T001 and T002 precede T003. T003 precedes T004, T005, and T006. T006 precedes T007.

## Implementation strategy

Deliver the module change first, then publish a fixed revision and pin production to it. Do not apply without historical metric comparison and plan review.
