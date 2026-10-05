# Feature Specification: Count actual RDS slow queries

**Feature Branch**: `006-slow-query-count`  
**Created**: 2026-10-05  
**Status**: Approved for implementation and PR preparation  
**Input**: DS-13434 and operator request to make a PR for the shared dasmeta/rds/aws module.

## User Scenarios & Testing

### User Story 1 - Trust slow-query alerts (Priority: P1)
As an operator, I need slow-query alerts to count genuine slow statements so routine configuration logs do not trigger incidents.

**Independent Test**: Replay engine-specific fixtures and verify that matching statements each contribute one count and unrelated logs contribute zero.

**Acceptance Scenarios**:
1. Given only configuration/checkpoint logs, when evaluated over five minutes, then the slow-query count is zero.
2. Given five qualifying slow statements, when evaluated with defaults, then the threshold is met; four are below it.
3. Given PostgreSQL simple statements or prepared executions at the configured duration boundary, then both are counted once; faster statements and Parse/Bind phases are excluded.
4. Given MySQL/MariaDB slow-query headers and multiline SQL, then each qualifying query is counted once and other logs are excluded.

### User Story 2 - Upgrade without losing monitoring intent (Priority: P2)
As a module consumer, I need existing duration telemetry and explicit alarm overrides preserved while adopting the corrected default.

**Independent Test**: Compare defaults, custom overrides, disabled monitoring and extra log exports in mocked plans.

**Acceptance Scenarios**:
1. Existing duration metrics retain their name, units, filter and values.
2. Explicit period, threshold, comparison and statistic overrides retain precedence.
3. Disabled slow-query monitoring creates no count filter or slow-query alarm.
4. Count metrics only consume the engine's query log; auxiliary exports do not duplicate counts.

### Edge Cases
Fractional duration thresholds; exact boundary durations; named/unnamed prepared execution; multiline query records; separate MySQL header events; log silence; user overrides of DB logging parameters; disabled alarms; Aurora and standalone engines.

## Requirements

### Functional Requirements
- **FR-001**: Count qualifying slow-query records once with no contribution from unrelated records or default zero samples.
- **FR-002**: Preserve existing duration telemetry and required/optional consumer inputs.
- **FR-003**: Use five actual slow-query records per five minutes as the default alarm threshold, preserving explicit overrides.
- **FR-004**: Respect the configured slow-query duration and supported engine log formats.
- **FR-005**: Preserve disabled monitoring behavior and avoid duplicate counts from other exported logs.
- **FR-006**: Document upgrade state migration, verification, rollback and limits of fixture-only positive evidence.
- **FR-007**: Provide automated plan regressions and executable filter fixture validation.
- **FR-008**: Produce a PR linked to DS-13434; do not apply production changes or publish a release.

## Success Criteria
- **SC-001**: Every negative fixture contributes zero and every qualifying fixture contributes one.
- **SC-002**: Existing telemetry and explicitly configured alarm behavior survive the upgrade.
- **SC-003**: Default alerts distinguish four qualifying statements from five within a five-minute interval.
- **SC-004**: Reviewers can reproduce checks and identify all migration requirements before deployment.

## Assumptions
The module's old PostgreSQL threshold comment establishes intended default of five actual queries. Server logging defines slow-query eligibility for engine formats whose CloudWatch filter cannot compare extracted durations. Runtime logging overrides must be reconciled by consumers. Source preparation and PR creation are authorized; production applies require separate exact-plan approval.

## Combined PR scope (2026-10-05)
The operator requested combining PRs #69 and #70 into one review PR. Retain #69 targeting main and incorporate the approved DS-13398 alarm-planning correction from #70. Its original storage-backport base is not part of this integration.
- FR-009: Alarm metric query account IDs remain known during planning while database resources have pending creation or changes; remove the blanket database-module dependency and retain actual expression dependencies.
- FR-010: Preserve all existing database configuration and alarm definitions, except the already-approved slow-query count behavior.
- Acceptance: a mocked Aurora plan with pending database creation resolves all eight existing metric alarms' account IDs; the same test fails before removing the blanket dependency.
- Delivery: one combined PR links DS-13434 and DS-13398; close #70 as superseded only after its fix is present and validated on #69. No merge to main or production apply is requested.
