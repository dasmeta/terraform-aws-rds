# Feature Specification: Correct RDS storage alarm defaults
**Feature Branch**: `005-rds-storage-alarms`
**Created**: 2026-10-02
**Status**: Approved for code preparation by the operator's "fix it" instruction
**Input**: Fix DS-13363; implementation tracked by DS-13398.

## User Scenarios & Testing
### User Story 1 — Detect exhausted Aurora local storage (P1)
An operator receives a storage alert when a provisioned Aurora member runs low, even when other members remain healthy.
**Independent test**: Plan the Aurora configuration and verify the effective storage-alarm metric, dimension, statistic and threshold.
**Acceptance scenarios**:
1. Given provisioned Aurora with alarms enabled, the storage alarm measures local free space with cluster coverage and detects the least-free member.
2. Given a custom disk threshold/statistic/period/comparison, the existing overrides take precedence.
3. Given Aurora Serverless-only instances, no unsupported provisioned local-storage alarm is created.
### User Story 2 — Preserve standalone monitoring (P1)
Standalone RDS users retain their existing allocated-storage-based alarm.
**Independent test**: Plan standalone PostgreSQL and compare its effective storage alarm.
**Acceptance scenarios**:
1. Given standalone RDS, storage monitoring retains its metric, average, five-minute period and 8% allocated-storage threshold.
2. Given alarms disabled, no alarms are created and no absent storage data source is indexed.

### Edge Cases
- Null allocated storage on Aurora must not produce an arbitrary capacity-derived local-disk threshold.
- Cluster reader autoscaling must not require manual alarm enumeration.
- A mixed cluster monitors provisioned local storage; Serverless temp-storage monitoring is outside this repair.
- Authentication expiry blocks deployment evidence, not local implementation/tests.

## Requirements
- **FR-001**: Use engine-appropriate storage measurements for provisioned Aurora and standalone RDS.
- **FR-002**: Do not average healthy Aurora members over a low-storage member.
- **FR-003**: Preserve the disk override contract and all non-storage alarm settings.
- **FR-004**: Use a documented absolute Aurora baseline threshold, tunable by the existing override.
- **FR-005**: Preserve disabled-alarm behavior and avoid unsupported local-storage alarms for Serverless-only clusters.
- **FR-006**: Deliver a linked, tested module PR and a reviewable Sela consumer rollout without applying production changes before exact-plan approval.
- **FR-007**: Do not claim Oneleet passes or modify shared alarm serialization without live evidence.

## Success Criteria
- All storage-alarm regression scenarios pass with no AWS writes.
- Other alarm keys, names, actions and thresholds remain unchanged.
- A reviewed rollout identifies only expected monitoring changes; database changes are excluded.
- Runtime coverage and Oneleet pass are reported only after successful live checks.

## Assumptions
5 GiB is a conservative module baseline for provisioned Aurora, not a percentage or universal AWS recommendation. Operators tune it to workload/local capacity via the existing override. Scope is the shared root module and Sela adoption.
