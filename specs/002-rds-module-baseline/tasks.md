# Tasks: dasmeta/rds/aws module baseline

**Input**: Design documents from `specs/002-rds-module-baseline/`  
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/module-interface.md, quickstart.md

**Tests**: Validation and hardening tasks include test additions where baseline gaps exist (Phase C1). Behavior change release tracked via `001` / engine-family fix.

**Organization**: Tasks grouped by user story from spec.md; Phase A (release) blocks Aurora PostgreSQL + full monitoring validation.

**Implementation session (2026-05-20)**: 28/49 tasks completed in-repo. Remaining tasks need merge/tag, AWS `terraform plan`, pre-commit on main, and infra YAML updates.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: US1–US6 per spec.md user stories

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Confirm module scope and validation baseline

- [x] T001 Confirm target paths from `specs/002-rds-module-baseline/plan.md` against repo root (`main.tf`, `locals.tf`, `tests/`, `modules/`)
- [x] T002 [P] Verify `specs/002-rds-module-baseline/contracts/module-interface.md` matches `variables.tf` and `output.tf`
- [x] T003 [P] Record upstream module version pins in `main.tf` and `modules/proxy/main.tf` against `plan.md` table
- [x] T004 Map all `tests/*` directories to user stories using `specs/002-rds-module-baseline/spec.md` test coverage table (18 dirs incl. new test)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Release engine-family fix (`001`) — **blocks** US4 Aurora PostgreSQL + `enable_full_monitoring`

**⚠️ CRITICAL**: US4 aurora-postgresql full-monitoring validation requires module **>= 1.11.2**

- [x] T005 Confirm `locals.tf` uses `strcontains(var.engine, "postgres")` for `is_postgres_engine` / `engine_family`
- [x] T006 [P] Confirm `log-based-metrics.tf` uses `strcontains(var.engine, "postgres")` for slow-query patterns
- [x] T007 Confirm `README.md` NOTE documents `aurora-postgresql` + `enable_full_monitoring` requires **>= 1.11.2**
- [ ] T008 Merge branch `fix/aurora-postgresql-engine-family` into `main` (or open/merge PR)
- [ ] T009 Tag and publish registry release **1.11.2** (or next patch) for `dasmeta/rds/aws`
- [ ] T010 Run `pre-commit run --all-files` on `main` after merge

**Checkpoint**: Patch release available; CI green on main

---

## Phase 3: User Story 1 — Standalone RDS (Priority: P1) 🎯 MVP

**Goal**: Validate standalone RDS (MySQL/PostgreSQL) path via `module.db`

**Independent Test**: `terraform plan` in `tests/basic-postgres/` succeeds; instance outputs populated

- [ ] T011 [P] [US1] Run `terraform init` and `terraform plan` in `tests/basic-postgres/`
- [ ] T012 [P] [US1] Run `terraform plan` in `tests/slow-queries-mysql/main.tf` context (or directory)
- [x] T013 [US1] Confirm `tests/basic-postgres/main.tf` uses `engine = postgres` and documents required `alarms.sns_topic`
- [x] T014 [US1] Verify `output.tf` instance outputs (`db_instance_endpoint`, etc.) match `tests/basic-postgres` consumer expectations
- [x] T015 [US1] Document standalone RDS quickstart path in `specs/002-rds-module-baseline/quickstart.md` §1 (verify accuracy)

**Checkpoint**: Standalone RDS path validated independently

---

## Phase 4: User Story 2 — Aurora cluster (Priority: P1)

**Goal**: Validate Aurora MySQL/PostgreSQL cluster path via `module.db_aurora`

**Independent Test**: `terraform plan` in `tests/basic-aurora-mysql/` and `tests/aurora-cluster-read-replica/` succeeds

- [ ] T016 [P] [US2] Run `terraform plan` in `tests/basic-aurora-mysql/`
- [ ] T017 [P] [US2] Run `terraform plan` in `tests/aurora-cluster-read-replica/` (`engine = aurora-postgresql`)
- [x] T018 [US2] Confirm `tests/basic-aurora-mysql/1-example.tf` defines `aurora_configs.instances.master` per module convention
- [x] T019 [US2] Verify Aurora outputs in `output.tf`: `cluster_endpoint`, `cluster_reader_endpoint`, `cluster_instance_endpoint_suffix`
- [x] T020 [US2] Document Aurora quickstart in `specs/002-rds-module-baseline/quickstart.md` §2 (verify `allocated_storage = null`, `instance_class`)

**Checkpoint**: Aurora cluster path validated independently

---

## Phase 5: User Story 3 — TLS and slow-query observability (Priority: P2)

**Goal**: Validate `enforce_client_tls` and `slow_queries` presets without manual parameter lists

**Independent Test**: Plan succeeds in `tests/enforce-client-tls/` and `tests/slow-queries-postgres/`

- [ ] T021 [P] [US3] Run `terraform plan` in `tests/enforce-client-tls/` (aurora-postgresql)
- [ ] T022 [P] [US3] Run `terraform plan` in `tests/slow-queries-postgres/`
- [x] T023 [US3] Confirm `locals.tf` merges `enforce_client_tls_params_map` into `cluster_parameters` for Aurora
- [x] T024 [US3] Confirm `log-based-metrics.tf` creates filters when `slow_queries.enabled` and log exports exist
- [ ] T025 [US3] Run `terraform plan` in `tests/slow-queries-disabled-postgres/` and confirm reduced log/metric resources

**Checkpoint**: TLS and slow-query behavior validated per engine family

---

## Phase 6: User Story 4 — Full monitoring bundle (Priority: P2)

**Goal**: Validate `enable_full_monitoring` for MySQL and **Aurora PostgreSQL** (post-1.11.2)

**Independent Test**: No `Invalid index` on `local.prepared_configs[local.engine_family]` at plan time

- [ ] T026 [P] [US4] Run `terraform plan` in `tests/aurora-mysql-with-full-monitoring-enabled/`
- [ ] T027 [P] [US4] Run `terraform plan` in `tests/instance-performance-insights-enabled/`
- [ ] T028 [P] [US4] Run `terraform plan` in `tests/aurora-cluster-database-insights-enabled/`
- [x] T029 [US4] Create `tests/aurora-postgresql-full-monitoring/0-setup.tf` mirroring `tests/enforce-client-tls/0-setup.tf`
- [x] T030 [US4] Create `tests/aurora-postgresql-full-monitoring/1-example.tf` with `engine = aurora-postgresql`, `enable_full_monitoring = true`, `aurora_configs.instances.master = {}`
- [x] T031 [US4] Create `tests/aurora-postgresql-full-monitoring/README.md` describing plan-only or apply validation steps
- [x] T032 [US4] Run `terraform validate` in `tests/aurora-postgresql-full-monitoring/` (config valid; `terraform plan` needs AWS creds)
- [x] T033 [US4] CI uses `path: /` only in `.github/workflows/terraform-test.yaml` — no matrix change required

**Checkpoint**: Full monitoring validated for Aurora PostgreSQL and existing MySQL tests

---

## Phase 7: User Story 5 — RDS Proxy (Priority: P3)

**Goal**: Validate optional `module.proxy` and two-step apply documented in README

**Independent Test**: Plan succeeds in `tests/postgres-instance-proxy/` and `tests/basic-aurora-mysql-and-proxy/`

- [ ] T034 [P] [US5] Run `terraform plan` in `tests/postgres-instance-proxy/`
- [ ] T035 [P] [US5] Run `terraform plan` in `tests/basic-aurora-mysql-and-proxy/`
- [x] T036 [US5] Verify `modules/proxy/main.tf` passes `engine_family` from root `locals.tf`
- [x] T037 [US5] Confirm README NOTEs two-step proxy rollout in `README.md` lines 3–5
- [x] T038 [US5] Document proxy two-step flow in `specs/002-rds-module-baseline/quickstart.md` §3

**Checkpoint**: Proxy path validated; docs aligned

---

## Phase 8: User Story 6 — CloudWatch alarms (Priority: P3)

**Goal**: Validate `module.cw_alerts` and optional `alarms.custom_values`

**Independent Test**: Plan succeeds in `tests/alarms-disabled-postgres/` (disabled) and alarm test dirs (enabled)

- [ ] T039 [P] [US6] Run `terraform plan` in `tests/alarms-disabled-postgres/`
- [ ] T040 [P] [US6] Run `terraform plan` in `tests/alarms-full-modified-postgres/`
- [x] T041 [US6] Review `alerts.tf` filter `DBInstanceIdentifier = var.identifier` and document Aurora caveat in `README.md` (plan item C2)
- [x] T042 [US6] Confirm `data.tf` `aws_db_instance` and `aws_ec2_instance_type` used only when `alarms.enabled`

**Checkpoint**: Alarms path validated; Aurora limitation documented

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Consumer rollout, doc gaps, final validation

- [x] T043 [P] Add README callout for production engine/version overrides (plan C4) in `README.md`
- [x] T044 [P] Add README note on `slow_queries.enabled` default true (plan C3) in `README.md`
- [ ] T045 Run full CI locally or via PR: `pre-commit`, `tflint`, `tfsec`, `checkov` per `.github/workflows/`
- [ ] T046 Update infra consumer YAML (Keycloak/AMS): `version >= 1.11.2`, `engine = aurora-postgresql`, `cluster_endpoint` outputs
- [x] T047 [P] Reconcile `specs/002-rds-module-baseline/contracts/module-interface.md` after any doc-only README changes
- [ ] T048 Mark `specs/002-rds-module-baseline/spec.md` status **Validated** after all P1/P2 checkpoints pass
- [x] T049 [P] Sync `specs/001-aurora-postgresql-engine-family/spec.md` status to **Implemented (pending merge and registry tag 1.11.2)**

---

## Dependencies & Execution Order

### Phase Dependencies

```text
Phase 1 (Setup)
    ↓
Phase 2 (Foundational / 1.11.2 release)  ← BLOCKS US4 aurora-postgresql full monitoring
    ↓
Phase 3–8 (US1–US6) — US1/US2 can parallelize after Phase 2; US4 needs Phase 2
    ↓
Phase 9 (Polish / consumer rollout)
```

### User Story Dependencies

| Story | Depends on | Notes |
|-------|------------|-------|
| US1 | Phase 2 | Can run in parallel with US2 after T010 |
| US2 | Phase 2 | Independent of US1 |
| US3 | Phase 2 | Uses engine family locals |
| US4 | **Phase 2 complete (1.11.2)** | T029–T032 require patch release |
| US5 | Phase 2 | Proxy submodule |
| US6 | Phase 2 | Alarms + data sources |

### Parallel Opportunities

- **T002, T003, T004** (Setup) in parallel
- **T005, T006, T007** (Foundational code review) in parallel before merge
- **T011–T012, T016–T017, T021–T022** (plan runs) in parallel across test dirs
- **T029–T031** (new test scaffolding) sequential; **T032** after T009

---

## Parallel Example: After Phase 2

```bash
# Validation plans in parallel (different directories):
tests/basic-postgres/
tests/basic-aurora-mysql/
tests/enforce-client-tls/
tests/aurora-mysql-with-full-monitoring-enabled/
tests/postgres-instance-proxy/
tests/alarms-disabled-postgres/
```

---

## Implementation Strategy

### MVP (minimum viable validation)

1. Phase 1: Setup (T001–T004)
2. Phase 2: Release **1.11.2** (T005–T010)
3. Phase 3: US1 standalone RDS (T011–T015)
4. **STOP** — consumer can use standalone Postgres with released module

### Full baseline validation

1. MVP + Phase 4 US2 (Aurora)
2. Phase 6 US4 including T029–T032 (aurora-postgresql full monitoring test)
3. Phase 5, 7, 8 (US3, US5, US6)
4. Phase 9 consumer rollout (T046)

### Suggested PR split

| PR | Tasks | Scope |
|----|-------|-------|
| PR1 | T005–T010 | Engine-family fix + 1.11.2 release (`001`) |
| PR2 | T029–T033 | `tests/aurora-postgresql-full-monitoring/` |
| PR3 | T041, T043–T044 | README hardening only |
| Infra | T046 | Consumer YAML (separate repo) |

---

## Notes

- Total tasks: **49**
- US1: 5 | US2: 5 | US3: 5 | US4: 8 | US5: 5 | US6: 4 | Setup: 4 | Foundational: 6 | Polish: 7
- `[P]` = 22 parallelizable tasks
- No greenfield module code in baseline track except optional test dir T029–T031
