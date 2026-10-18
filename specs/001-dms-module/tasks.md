# Tasks: Opinionated AWS DMS Submodule

**Input**: Design documents from `/specs/001-dms-module/`
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/module-interface.md`

## Phase 1: Setup

- [ ] T001 Create the `modules/dms` and `tests/dms-private-mysql` directory skeletons described in `specs/001-dms-module/plan.md`.
- [ ] T002 Add test-fixture provider constraints and neutral fixture inputs in `tests/dms-private-mysql/0-setup.tf`.

---

## Phase 2: Foundational contract

- [ ] T003 Write failing Terraform tests in `tests/dms-private-mysql/dms.tftest.hcl` for required grouped inputs, stable outputs, and fixed private/stopped behavior.
- [ ] T004 Run the targeted test and capture the expected RED result caused by the missing `modules/dms` contract.
- [ ] T005 Define provider constraints in `modules/dms/versions.tf` and typed, validated inputs in `modules/dms/variables.tf`.
- [ ] T006 Add minimal placeholder-safe outputs in `modules/dms/outputs.tf` only as each corresponding test requires them.

**Checkpoint**: The submodule contract initializes and invalid-input tests fail for the intended validation reasons.

---

## Phase 3: User Story 1 - Configure a private live migration (Priority: P1)

**Goal**: Create private provisioned DMS infrastructure for one MySQL-compatible full-load-and-CDC migration while leaving the task stopped.

**Independent Test**: A neutral fixture plans one subnet group, one private replication instance, two secret-backed verify-full endpoints, and one stopped full-load-and-CDC task; invalid subnet, engine, schema, or certificate inputs fail.

### Tests

- [ ] T007 [US1] Extend `tests/dms-private-mysql/dms.tftest.hcl` with failing assertions for two-subnet minimum, supported endpoint engines, required certificate/secret/KMS ARNs, private runtime, and fixed task lifecycle.
- [ ] T008 [US1] Run the targeted tests and verify each new assertion fails for the intended missing behavior.

### Implementation

- [ ] T009 [US1] Implement deterministic naming, schema mappings, and fixed task settings locals in `modules/dms/main.tf`.
- [ ] T010 [US1] Add the pinned `terraform-aws-modules/dms/aws` v2.6.0 wrapper for IAM roles, subnet group, provisioned runtime, and stopped task in `modules/dms/main.tf`.
- [ ] T011 [US1] Add the bounded source and target `aws_dms_endpoint` resources with Secrets Manager authentication and registered-certificate `verify-full` TLS in `modules/dms/main.tf`.
- [ ] T012 [US1] Expose stable runtime, endpoint, task, subnet-group, and IAM outputs in `modules/dms/outputs.tf`.
- [ ] T013 [US1] Run targeted tests until User Story 1 is GREEN, then refactor without widening the interface.

**Checkpoint**: User Story 1 independently plans a secure, stopped migration stack.

---

## Phase 4: User Story 2 - Operate and validate migration progress (Priority: P2)

**Goal**: Provide logging, validation, and stable monitoring identifiers for migration go/no-go evidence.

**Independent Test**: Planned task JSON enables logging and row validation, and outputs identify task log resources and managed components.

### Tests

- [ ] T014 [US2] Add failing assertions in `tests/dms-private-mysql/dms.tftest.hcl` for logging, validation, and deterministic CloudWatch log identifiers.
- [ ] T015 [US2] Run the targeted tests and verify RED failures are caused by missing observability behavior.

### Implementation

- [ ] T016 [US2] Implement fixed CloudWatch logging and DMS validation task settings in `modules/dms/main.tf`.
- [ ] T017 [US2] Add task log group/stream outputs and descriptions in `modules/dms/outputs.tf`.
- [ ] T018 [US2] Run targeted tests until User Story 2 is GREEN.

**Checkpoint**: Operators can locate logs and validate migration correctness from stable outputs.

---

## Phase 5: User Story 3 - Reuse safe MySQL-compatible defaults (Priority: P3)

**Goal**: Reuse one narrow interface for MySQL/Aurora MySQL with approved runtime, Full LOB, mapping, and target-preparation defaults.

**Independent Test**: Omitting bounded overrides plans engine 3.6.1, `dms.r6i.large`, Single-AZ, 100 GiB, Full LOB, explicit-schema `%` mapping, and `TRUNCATE_BEFORE_LOAD`.

### Tests

- [ ] T019 [US3] Add failing assertions in `tests/dms-private-mysql/dms.tftest.hcl` for runtime defaults, Full LOB, explicit-schema mappings, truncate-before-load, and bounded parallel-load controls.
- [ ] T020 [US3] Run the targeted tests and verify RED failures are caused by missing default behavior.

### Implementation

- [ ] T021 [US3] Complete runtime and bounded parallel-load defaults in `modules/dms/variables.tf` and `modules/dms/main.tf`.
- [ ] T022 [US3] Complete Full LOB, target preparation, and explicit-schema mapping generation in `modules/dms/main.tf`.
- [ ] T023 [US3] Run targeted tests until User Story 3 is GREEN.

**Checkpoint**: All three user stories pass independently with no arbitrary upstream pass-through.

---

## Phase 6: Documentation and verification

- [ ] T024 Add a copy-pasteable neutral example and operational prerequisites to `modules/dms/README.md`.
- [ ] T025 Add test purpose and safe execution notes to `tests/dms-private-mysql/README.md`.
- [ ] T026 Run Terraform docs/pre-commit generation and inspect the resulting `modules/dms/README.md` contract.
- [ ] T027 Run `terraform fmt -check -recursive`, targeted init/validate/tests, and repository regression checks.
- [ ] T028 Run naming/secret scans and `git diff --check`; confirm no customer identifiers, secret values, root interface changes, or task auto-start behavior exist.
- [ ] T029 Review completed implementation against every requirement and success criterion in `specs/001-dms-module/spec.md` and record any environment-dependent verification limitation.

---

## Dependencies and execution order

- Setup precedes the foundational contract.
- T003-T004 establish RED before any production Terraform is written.
- User Story 1 is the MVP and blocks the resource-dependent portions of User Stories 2 and 3.
- Within every story, tests and an observed RED result precede implementation; implementation is followed by GREEN verification.
- Documentation and full verification follow all desired stories.

## Implementation strategy

Complete the secure stopped migration stack first, then add observability and reusable defaults without broadening the public interface. Keep the existing root module untouched. Do not commit or publish automatically; repository delivery remains a separate approved action.
