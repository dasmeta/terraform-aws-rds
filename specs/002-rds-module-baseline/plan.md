# Implementation Plan: dasmeta/rds/aws module baseline

**Branch**: `002-rds-module-baseline` (planning); active code on `fix/aurora-postgresql-engine-family` | **Date**: 2026-05-20 | **Spec**: [spec.md](./spec.md)  
**Input**: Baseline specification from `specs/002-rds-module-baseline/spec.md` (reverse-engineered from current implementation)

## Summary

This plan does **not** greenfield a new module. It defines how to **validate, document, release, and harden** the existing `dasmeta/rds/aws` wrapper as captured in the baseline spec. Work is organized into: (1) complete the in-flight **engine-family fix** and patch release, (2) close **test/documentation gaps** against the baseline, (3) align **consumer deployments** (Aurora PostgreSQL 17.x, Keycloak), and (4) optional follow-ups (Aurora alarm dimensions, dedicated aurora-postgresql full-monitoring test).

## Technical Context

**Terraform/OpenTofu Version**: Consumer-driven; root module has no `versions.tf` (wrapper pattern). Tests use Terraform with AWS provider via `tests/*/0-setup.tf`.  
**Providers / Upstream Modules**:

| Component | Source | Version |
|-----------|--------|---------|
| Standalone RDS | `terraform-aws-modules/rds/aws` | 6.12.0 |
| Aurora | `terraform-aws-modules/rds-aurora/aws` | 9.15.0 |
| Security group | `terraform-aws-modules/security-group/aws` | 5.2.0 |
| Alarms | `dasmeta/monitoring/aws//modules/alerts` | 1.3.5 |
| Log metrics | `dasmeta/monitoring/aws//modules/cloudwatch-log-based-metrics` | 1.13.2 |
| RDS Proxy | `terraform-aws-modules/rds-proxy/aws` (via `modules/proxy`) | 3.1.0 |

**Target Module Path**: Repository root (`/Users/arsengspeyan/terraform-aws-rds`)  
**Examples / Tests in Scope**: `tests/*` (17 directories), `README.md` Cases 1–2, `modules/proxy`, `modules/scheduled-scale`  
**Automation Gates**: `.github/workflows/pre-commit.yaml`, `terraform-test.yaml`, `tflint.yaml`, `tfsec.yaml`, `checkov.yaml`, `semantic.yaml`  
**Target Platform**: AWS RDS / Aurora in VPC; optional RDS Proxy  
**Constraints**:

- Baseline spec: **no interface change** unless tracked in separate feature (`001`)
- Preserve opinionated wrapper; avoid passthrough of all upstream inputs
- Proxy: two-step apply (DB first, then proxy) per README

**Scale/Scope**: Root module + submodules `proxy`, `scheduled-scale`; `proxysql` out of core path

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] Change stays within one coherent module responsibility (AWS RDS/Aurora wrapper).
- [x] Consumer interface remains opinionated; baseline plan documents behavior only.
- [x] README/tests updates listed where behavior changes (via linked `001` release).
- [x] Upstream module version pins explicit in `main.tf` / submodule sources.
- [x] No breaking changes in baseline track; patch release for `001` documented.

**Post-design re-check**: Pass — design artifacts document existing interface; improvements are additive tests/docs unless `001` merges.

## Project Structure

### Documentation (this feature)

```text
specs/002-rds-module-baseline/
├── plan.md              # This file
├── research.md          # Phase 0
├── data-model.md        # Phase 1
├── quickstart.md        # Phase 1
├── contracts/
│   └── module-interface.md
├── spec.md
├── checklists/
│   └── requirements.md
└── tasks.md             # Created by /speckit.tasks (not this command)
```

### Source Code (repository root)

```text
terraform-aws-rds/
├── main.tf                 # db / db_aurora / scheduled_scale / proxy routing
├── locals.tf               # engine family, prepared_configs, parameters merge
├── variables.tf
├── output.tf
├── data.tf
├── security-group.tf
├── alerts.tf
├── log-based-metrics.tf
├── README.md
├── modules/
│   ├── proxy/
│   ├── scheduled-scale/
│   └── proxysql/           # Helm/K8s; not wired in root main.tf
├── tests/                  # 17 scenario directories
└── .github/workflows/
```

**Structure Decision**: Single root wrapper module; Aurora vs RDS selected by `local.is_aurora` (`startswith(engine, "aurora")`).

## Implementation Phases

### Phase A — Release engine-family fix (links to `001`)

| Step | Action | Owner |
|------|--------|-------|
| A1 | Merge `fix/aurora-postgresql-engine-family` → `main` | Maintainer |
| A2 | Tag registry version **1.11.2** (or next patch) | Maintainer |
| A3 | Confirm README NOTE: aurora-postgresql + `enable_full_monitoring` >= 1.11.2 | Done in branch |
| A4 | Bump infra YAML (`dasmeta/rds/aws` version) for Keycloak / AMS | Consumer teams |

### Phase B — Baseline validation (no code change required)

| Step | Action | Evidence |
|------|--------|----------|
| B1 | Run pre-commit on `main` after merge | CI green |
| B2 | Map each user story in spec → test directory | Test coverage map in spec |
| B3 | `terraform plan` smoke: `aurora-postgresql` + `enable_full_monitoring` | New test (Phase C) or manual |
| B4 | Verify `contracts/module-interface.md` matches `variables.tf` / `output.tf` | Diff review |

### Phase C — Recommended hardening (optional, separate PRs)

| ID | Gap (from baseline edge cases) | Proposed change | Priority |
|----|--------------------------------|-----------------|----------|
| C1 | No test for `aurora-postgresql` + `enable_full_monitoring` | Add `tests/aurora-postgresql-full-monitoring/` | P1 |
| C2 | Aurora alarms use cluster `identifier` as `DBInstanceIdentifier` | Document limitation; optional alarm filter enhancement | P2 |
| C3 | `slow_queries` default `enabled = true` may surprise minimal installs | Document in README; optional default change needs approval | P3 |
| C4 | Legacy defaults `engine = mysql` / `5.7.26` | README “production overrides” callout only | P3 |

### Phase D — Consumer rollout (infra repos)

| Step | Action |
|------|--------|
| D1 | Aurora PostgreSQL 17.7: `engine = aurora-postgresql`, `allocated_storage = null`, `instance_class` set |
| D2 | Use `aurora_configs.instances.master` (+ optional reader or autoscaling) |
| D3 | Outputs: `cluster_endpoint` / `cluster_reader_endpoint` for apps (e.g. Keycloak) |
| D4 | Module version >= 1.11.2 before `enable_full_monitoring = true` |

## Complexity Tracking

No constitution violations. Optional C2 (alarm dimensions) would be interface/behavior widening — requires explicit approval per constitution V.
