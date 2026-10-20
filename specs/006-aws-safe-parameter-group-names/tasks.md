# Tasks: AWS-safe parameter group names

**Input**: [spec.md](./spec.md) and [plan.md](./plan.md)
**Prerequisites**: Specification and implementation plan

## Phase 1: Module behavior and documentation

- [x] T001 Update `locals.tf` so PostgreSQL keeps the family-qualified name and other engines use the engine suffix.
- [x] T002 Update the root README naming guidance and examples for PostgreSQL versus other engines.
- [x] T003 Review `main.tf` references to confirm instance and cluster groups still use the shared name local and `-cluster` suffix.

## Phase 2: Review

- [x] T004 Compare the final expression with the four engine examples in `spec.md` and confirm non-PostgreSQL names preserve compatibility.
- [x] T005 Run `git diff --check` and review the final change set for unrelated edits.
