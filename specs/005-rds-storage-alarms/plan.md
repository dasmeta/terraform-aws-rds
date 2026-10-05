# Implementation Plan: Correct RDS storage alarm defaults
**Branch**: `005-rds-storage-alarms` | **Date**: 2026-10-02 | **Spec**: [spec.md](spec.md)
**Input**: DS-13398; user requested "fix it" after DS-13363 diagnosis.

## Summary
Preserve the opinionated dasmeta/rds/aws wrapper and existing grouped alarms input. Extract the effective disk-alarm definition into a local used by the existing shared alarm module. Provisioned Aurora uses FreeLocalStorage, DBClusterIdentifier, Minimum, 5 GiB. Standalone retains FreeStorageSpace, DBInstanceIdentifier, Average and 8% allocated storage. Serverless-only clusters omit unsupported FreeLocalStorage. Mixed clusters cover provisioned members only. Existing disk overrides keep priority.

## Technical Context
Terraform HCL; tests require Terraform >=1.7 for mocked providers (local CLI 1.15.7), without changing consumer Terraform constraints. Existing dependencies: Aurora 9.15.0, RDS 6.12.0, monitoring alerts 1.3.5; no version/provider upgrades. Use cached AWS provider 5.100.0 after provider download hit disk-space limits. Plan-only mocked tests; no cloud writes. Source scope: alerts.tf, locals.tf, README.md, tests/storage-alarms.tftest.hcl. Consumer repository: Sela infrastructure, separate worktree; publish/merge module before adopting immutable source/release. Do not assume release versions exist.

## Constitution Check
- Corresponding downstream Speckit spec/plan/tasks exist before module edits. Stage skills invoked; use canonical constitution scripts from the downstream worktree because this repo stores only feature metadata, not scripts/templates.
- Shared module standards sourced from constitution/skills/terraform-module-developer/references/internal-module-standards.md; no copied governance.
- Existing wrapper and required/optional input contract preserved; no new provider capability or interface widening.
- Not a new module: provider collection/template sourcing is inapplicable; preserve existing upstream wrappers.
- No database resource, other alarm, autoscaling, provider or logging changes.
- The operator's explicit fix instruction authorizes code preparation. Exact production alarm replacement still requires a reviewed live plan and approval.

## Project Structure
- `locals.tf`: effective storage alarm, engine support, threshold selection.
- `alerts.tf`: forward effective alarm through existing shared renderer.
- `tests/storage-alarms.tftest.hcl`: regression plans with mock AWS data and overridden DB child modules.
- `README.md`: local versus allocated storage, overrides, serverless limits and replacement.
- `specs/005-rds-storage-alarms/`: feature evidence, tests, rollout/rollback.
- `1-environments/prod/aurora-postgres.yaml` and generated Terraform in Sela: immutable adoption after module commit or released version.

## Validation
First add regression cases against current effective rendered alarm keys/source (expected failure), then implement locals/rendering and extend assertions for threshold/statistics/dimensions. Test PostgreSQL and MySQL Aurora, standalone PostgreSQL, disk overrides, disabled alarms, serverless-only and mixed memberships. Run init, validate, fmt on touched files and terraform test. Inspect diff and independent review before PR.

## Rollout and rollback
Source change changes the monitoring module for_each key while preserving the AWS alarm name. Add an explicit consumer moved block for the old-to-new nested module instance address before applying, avoiding concurrent create/delete against the same name. The live plan must show an in-place storage alarm update plus only explicitly reviewed source/version provenance tag updates. Reject database settings changes and resource replacement. Rollback requires reverting consumer source and reversing the address migration; this reinstates known incorrect Aurora monitoring, so prefer retaining the corrected alarm if rollout has unrelated trouble. After apply verify real FreeLocalStorage cluster Minimum datapoints against members, SNS actions and Oneleet Result. Standalone warning resolution is pending live evidence; do not add duplicate alarms based only on scanner speculation.

## Complexity Tracking
No standards/interface conflicts. Modern-capabilities rule inactive: existing alarm capability correction. 5 GiB is module baseline, not AWS universal sizing guidance. Runtime assertions and Oneleet verification remain blocked by SSO.

## Consumer isolation decision (2026-10-04)
The consumer currently pins v1.12.2. Latest upstream main also changes parameter group names to include engine family, which can replace DB parameter groups. Prepare a backport of only this storage fix on v1.12.2 and pin that published commit in a draft consumer MR. The existing renderer accepts `version: local` as its sentinel to omit Terraform registry version when using a Git source. Validate this render before publishing. The upstream main PR remains the general module fix; no release tag is invented. Reject unrelated DB changes in the live deployment plan.

## Apply-plan regression repair (2026-10-05)
Reuse this approved feature package. Root cause: the entire cw_alerts module depends_on both DB modules, deferring its caller-identity data lookup whenever either module changes. Remove this blanket dependency; metric identifiers already derive from stable inputs. CloudWatch accepts alarms before metrics exist. Keep any actual expression dependencies (including standalone storage-capacity data), all interfaces, provider bounds and alarm definitions. No shared monitoring serialization change.
Verification: native mocked plan without DB module overrides plus a JSON plan checker for known account_id on all eight alarms and pending Aurora creation. Run it before and after the fix, then the existing 11 storage scenarios, validate and touched-file fmt. Reuse installed modules/providers to avoid disk-space-heavy downloads. No AWS writes.
Source only alerts.tf; update README and independent test surface. No standards or interface conflicts; improve mode, modern-capabilities rule inactive. Existing baseline has docs, examples, native tests and CI; unrelated layout/automation gaps remain out of scope.
Publish a narrowly scoped commit based on the already-approved v1.12.2 storage backport, then update the consumer immutable archive pin through the real renderer. Preserve storage migration. Rollback: revert only this dependency correction/source pin; recovery plan requires review.
