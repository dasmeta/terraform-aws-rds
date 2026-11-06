# Feature Specification: Writer Read IOPS Alarm

**Feature Branch**: `006-writer-read-iops`
**Created**: 2026-11-06
**Status**: Ready
**Input**: DS-14137

## User Scenarios & Testing

### User Story 1 - Alert on writer read load (Priority: P1)

As an operator, I need the production database read IOPS alert to represent the current writer so reader queries do not page me and writer saturation still does.

**Why this priority**: Reader query noise obscures writer health.

**Independent Test**: Inspect the resulting alarm's metric selector and replay separate writer and reader metric series against its threshold.

**Acceptance Scenarios**:

1. **Given** a reader exceeds 20,000 read IOPS and the writer does not, **When** the alert evaluates, **Then** the writer alarm remains clear.
2. **Given** the writer exceeds 20,000 read IOPS for the configured evaluation period, **When** the alert evaluates, **Then** the writer alarm fires.
3. **Given** a failover, **When** a new instance becomes writer, **Then** the alarm follows that role.

### Edge Cases

- A non-Aurora instance must retain its existing instance-scoped alarm.
- Other Aurora alarms must keep their existing dimensions.

## Requirements

### Functional Requirements

- **FR-001**: Aurora read IOPS alarms MUST select only the writer role.
- **FR-002**: The production alarm MUST retain its 20,000 read IOPS threshold and existing notification destination.
- **FR-003**: The writer selection MUST continue to work across failover.
- **FR-004**: Non-Aurora alarms and other Aurora alarms MUST retain their current behavior.
- **FR-005**: Validation MUST compare the November 5 reader-driven event with writer activity when historical metrics are accessible.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Zero reader-only periods above the threshold trigger the writer alarm.
- **SC-002**: All writer periods above the threshold for the configured evaluation period trigger the writer alarm.
- **SC-003**: The alarm remains attached to the writer after a failover.

## Assumptions

- The ticket permits disabling the reader read IOPS alarm; only the writer alert is required.
- The existing 20,000 IOPS threshold and SNS destination remain appropriate for the writer.
