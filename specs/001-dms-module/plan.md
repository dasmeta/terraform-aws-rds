# Implementation Plan: Opinionated AWS DMS Submodule

**Branch**: `001-dms-module` | **Date**: 2026-07-22 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-dms-module/spec.md`

## Summary

Add an independently consumable `modules/dms` wrapper for private MySQL/Aurora MySQL full-load-and-CDC migrations. Pin `terraform-aws-modules/dms/aws` v2.6.0 for the replication subnet group, provisioned replication instance, standard DMS roles, and scoped Secrets Manager access role. Create the two endpoints and one task directly because upstream v2.6.0 cannot pass an existing DMS certificate ARN to endpoints or an external source endpoint ARN to its task. Generate fixed table mappings and task settings with `jsonencode`, require `verify-full`, use Full LOB mode and `TRUNCATE_BEFORE_LOAD`, and leave the task stopped.

## Technical Context

**Language/Version**: Terraform >= 1.3 (typed optional object attributes and preconditions)
**Primary Dependencies**: `terraform-aws-modules/dms/aws` 2.6.0; `hashicorp/aws` >= 5.96; `hashicorp/time` >= 0.9 (transitive upstream requirement)
**Storage**: AWS DMS provisioned replication storage, default 100 GiB gp3
**Testing**: `terraform fmt -check -recursive`, `terraform init -backend=false`, `terraform validate`, Terraform native tests/plan assertions where repository tooling permits, and pre-commit Terraform docs
**Target Platform**: AWS, initially MySQL and Aurora MySQL endpoints in private VPC networks
**Project Type**: Terraform registry module with an independently consumable submodule
**Performance Goals**: Safe defaults for an approximately 56 GiB initial load followed by CDC; tunable bounded full-load parallelism
**Constraints**: No plaintext connection fields, no public replication instance, at least two subnets, fixed full-load-and-CDC, Full LOB mode, task remains stopped, pre-registered certificate ARN required
**Scale/Scope**: One replication instance, one source endpoint, one target endpoint, one task, one explicitly selected schema per module instance

## Constitution Check

### Pre-research gate

| Gate | Status | Evidence |
|---|---|---|
| Shared constitution source aligned | PASS | Local constitution delegates cross-repository governance to `~/.codex/constitution/.specify/memory/constitution.md`; no conflict found. |
| Terraform module workflow followed | PASS | Repository inspected before edits; Speckit specify and clarify artifacts exist; implementation has not begun. |
| Wrapper-first design | PASS WITH BOUNDED EXCEPTION | Upstream v2.6.0 is the baseline. Direct endpoints and task are required because upstream derives `certificate_arn` only from certificates it creates and its task cannot accept an external source endpoint ARN. |
| Narrow, stable interface | PASS | Grouped typed inputs expose only network, two endpoints, bounded runtime controls, one schema, and tags. No arbitrary upstream maps or raw task settings are accepted. |
| No breaking root-module change | PASS | New code is isolated under `modules/dms`; the existing root interface is unchanged. |
| Neutral naming | PASS | All planned examples/tests use `dasmeta` or neutral identifiers. |
| Evidence-first verification planned | PASS | Formatting, init/validate, tests/assertions, docs generation, and root regression validation are included. |

### Post-design gate

PASS. The design preserves the wrapper baseline, contains the direct-resource exception to endpoints, does not widen the root interface, and defines validation, docs, tests, rollback expectations, and operational boundaries. No breaking-change or interface-widening approval is required.

## Repository and Baseline Assessment

- Current repository state: the root module wraps RDS and Aurora modules; `modules/proxy` establishes the submodule convention; tests use standalone fixtures under `tests/`.
- Standards gaps addressed by this feature: no current DMS abstraction, no DMS-specific test fixture, and no DMS operational documentation.
- Upstream candidates:
  - `terraform-aws-modules/dms/aws` 2.6.0: selected; maintained, supports provisioned instances, subnet groups, tasks, standard DMS roles, Secrets Manager/KMS-scoped access policy, and outputs.
  - Direct `hashicorp/aws` DMS resources only: rejected because it duplicates a maintained upstream module and violates wrapper-first policy.
- Modern capabilities classification:
  - Adopt now: Secrets Manager endpoint authentication, scoped KMS decrypt, private provisioned runtime, CloudWatch task logging, DMS data validation, TLS hostname verification, Full LOB mode.
  - Defer: DMS Serverless, event subscriptions/notifications, automatic start/cutover, multi-engine abstractions, cross-region orchestration.
  - Exclude: plaintext credentials, public runtime, arbitrary task-settings pass-through, Terraform-managed task execution.

## Design Decisions

1. Use one upstream module block with `endpoints = {}` and `replication_tasks = {}`; connect the upstream replication-instance ARN to one direct task using the two direct endpoint ARNs.
2. Use upstream IAM capabilities: `create_iam_roles = true`, `create_access_iam_role = true`, `access_secret_arns`, and `access_kms_key_arns`. The endpoint resources consume `module.this.access_iam_role_arn`.
3. Use `aws_dms_endpoint` only for source and target, with `ssl_mode = "verify-full"`, the consumer's registered `certificate_arn`, and secret-backed authentication.
4. Build table mappings with one include rule for the explicit application schema and `%` tables. System schemas cannot be selected because schema input validation rejects them.
5. Build task settings internally with `jsonencode`: logging and validation enabled, Full LOB mode, `TRUNCATE_BEFORE_LOAD`, and bounded parallel-load controls.
6. Omit `start_replication_task` (or set it false if required by provider behavior), ensuring apply creates a stopped task.
7. Surface stable, nonsensitive identifiers rather than exposing entire sensitive upstream objects.

## Project Structure

### Documentation (this feature)

```text
specs/001-dms-module/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── module-interface.md
└── tasks.md                 # created by /speckit.tasks
```

### Source Code (repository root)

```text
modules/dms/
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
└── README.md

tests/dms-private-mysql/
├── 0-setup.tf
├── 1-example.tf
├── dms.tftest.hcl
└── README.md
```

**Structure Decision**: Follow the existing independently consumable `modules/proxy` pattern and repository-level test-fixture convention. Do not connect the new submodule to the root module.

## Implementation Sequence

1. Add failing validation and plan assertions for subnet count, supported engines, TLS certificate requirements, private defaults, fixed migration mode, task settings, and outputs.
2. Define typed variables and validations in `modules/dms/variables.tf` plus provider/version constraints.
3. Implement locals for names, schema mappings, and fixed task settings.
4. Add the pinned upstream DMS wrapper and the two bounded direct endpoint resources.
5. Add stable outputs for subnet group, replication instance, endpoint ARNs/IDs, task ARN/ID, access role ARN, and deterministic CloudWatch log identifiers.
6. Add the neutral example and generate the module README using repository pre-commit tooling.
7. Run targeted verification, then root regression formatting/validation checks.

## Verification and Rollback

- Verify invalid inputs fail before resource creation.
- Verify planned runtime is private, Single-AZ by default, engine 3.6.1, class `dms.r6i.large`, and 100 GiB.
- Decode planned table mappings/task settings and assert one explicit schema, Full LOB, validation/logging, `TRUNCATE_BEFORE_LOAD`, and no task auto-start.
- Validate no secret values are accepted or output.
- Run repository-wide formatting and existing validation/test workflow.
- Rollback is removal of the consuming module block while the task is stopped. Consumers must stop a running task and preserve migration evidence before destroying resources; production database rollback remains outside this module.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| Two direct `aws_dms_endpoint` resources and one direct `aws_dms_replication_task` alongside the upstream wrapper | A registered certificate ARN is mandatory for `verify-full`; upstream v2.6.0 only maps `certificate_arn` from certificates it creates and does not accept an external source endpoint ARN for its task. | Letting upstream create certificates would require certificate material instead of the approved registered ARN contract; dropping hostname verification violates the specification. A direct task is the smallest way to connect both compliant endpoints to the upstream-managed runtime. |
