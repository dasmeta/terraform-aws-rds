# Feature Specification: Opinionated AWS DMS Submodule

**Feature Branch**: `001-dms-module`
**Created**: 2026-07-22
**Status**: Draft
**Input**: Create an AWS DMS submodule under `modules/dms` in the DasMeta `terraform-aws-rds` repository. Wrap the provider-maintained AWS DMS module with a narrow, secure interface for private full-load and CDC database migrations.

## User Scenarios & Testing

### User Story 1 - Configure a private live database migration (Priority: P1)

An infrastructure engineer can describe a source database, a target database, private network placement, and migration credentials, then create the DMS infrastructure needed for a full-load-and-CDC migration without assembling individual DMS resources.

**Why this priority**: A secure live database migration is the core reason for the module. Without this path, the module does not deliver useful value.

**Independent Test**: Instantiate the module with two private subnets, existing security groups, two Secrets Manager credential references, one provisioned replication instance, and one full-load-and-CDC task. Verify that planning succeeds and creates a subnet group, replication instance, two endpoints, and one task without exposing secret values.

**Acceptance Scenarios**:

1. **Given** two private subnets in different Availability Zones and approved security groups, **when** a consumer configures source and target endpoints plus a full-load-and-CDC task, **then** the plan contains a private DMS replication path with no public replication instance.
2. **Given** source and target credentials stored in Secrets Manager, **when** endpoints are configured, **then** credentials are referenced by secret ARN and are not accepted as plaintext module inputs.
3. **Given** fewer than two private subnets, **when** the configuration is validated, **then** planning fails with a clear validation error.

---

### User Story 2 - Operate and validate migration progress (Priority: P2)

An operator can observe full-load progress, CDC latency, task failures, and data-validation failures through standard AWS logs, metrics, and stable module outputs.

**Why this priority**: Live migrations require objective go/no-go evidence and cannot safely rely on task status alone.

**Independent Test**: Plan an example with task logging and validation enabled, then verify that task settings contain logging and validation controls and that outputs expose task, endpoint, replication instance, and log identifiers needed by monitoring automation.

**Acceptance Scenarios**:

1. **Given** a migration task, **when** logging is not explicitly disabled, **then** CloudWatch task logging is enabled by default.
2. **Given** a full-load-and-CDC task, **when** validation is not explicitly disabled, **then** row-level data validation is enabled by default.
3. **Given** a successful module plan, **when** an operator consumes module outputs, **then** the operator can identify every managed endpoint, task, replication instance, and subnet group without inspecting state internals.

---

### User Story 3 - Reuse safe defaults across MySQL-compatible migrations (Priority: P3)

A platform engineer can use the same module for MySQL or Aurora MySQL migrations while changing only database-specific endpoints, network references, and schema-selection mappings.

**Why this priority**: The module must be reusable without becoming a broad pass-through of every upstream option.

**Independent Test**: Plan a MySQL-to-Aurora MySQL example and verify that it uses the documented capacity, security, logging, tagging, LOB, and secret-handling defaults.

**Acceptance Scenarios**:

1. **Given** MySQL-compatible source and target databases, **when** engine-specific ports and TLS settings are supplied, **then** the module produces compatible endpoints and a migration task.
2. **Given** Aurora MySQL source and target databases, **when** endpoints use the same grouped interface, **then** the module remains usable without exposing unrelated upstream controls.
3. **Given** capacity settings are omitted, **when** the module is planned, **then** the documented `dms.r6i.large`, DMS 3.6.1, Single-AZ, and 100 GiB `gp3` defaults are used.

### Edge Cases

- Source and target can be in different VPCs only when the consumer supplies network routing and security groups that already permit the path; the module does not create peering or transit routing.
- Source and target may use MySQL or Aurora MySQL endpoint engine identifiers; other engine types must fail validation.
- Table mapping JSON and task settings JSON can be malformed; the module must validate that supplied strings decode as JSON.
- Secrets might exist in another account; the consumer must supply the required access role and secret policy, while the module must avoid reading or returning secret contents.
- A migration can require large-object handling; the task interface must support a bounded LOB mode without exposing the entire upstream task-settings surface.
- Replication instance maintenance, engine upgrades, or task restarts can interrupt CDC; defaults must favor controlled maintenance and observable recovery.
- A task may intentionally be created but not started; the module must not assume that infrastructure creation authorizes data movement.

## Requirements

### Functional Requirements

- **FR-001**: The repository MUST provide the feature as an independently consumable submodule at `modules/dms` and MUST NOT alter the existing root RDS module interface.
- **FR-002**: The submodule MUST use a provider-maintained AWS DMS module as its implementation baseline rather than recreating equivalent resources directly.
- **FR-003**: The submodule MUST expose a grouped network input containing at least two subnet IDs and existing security group IDs.
- **FR-004**: The submodule MUST create or manage a DMS replication subnet group for the supplied private subnets.
- **FR-005**: The submodule MUST provision a non-public replication instance by default.
- **FR-006**: The submodule MUST default to `dms.r6i.large`, DMS engine `3.6.1`, Single-AZ, and 100 GiB `gp3`, while exposing bounded overrides for replication instance class, allocated storage, engine version, maintenance window, and high-availability choice.
- **FR-007**: The submodule MUST accept source and target endpoint definitions as grouped objects with engine name, database name, Secrets Manager authentication reference, KMS key ARN, and the required DMS certificate ARN; hostname, port, username, and password MUST remain inside the referenced secret because the AWS provider forbids combining them with `secrets_manager_arn`.
- **FR-008**: The submodule MUST reject plaintext database passwords as consumer inputs.
- **FR-009**: The submodule MUST support only MySQL and Aurora MySQL endpoint engines in the first release.
- **FR-010**: The submodule MUST create only `full-load-and-cdc` migration tasks in the first release.
- **FR-011**: The submodule MUST require an explicit source schema selection and generate mappings for all tables in that schema while excluding system schemas.
- **FR-012**: The submodule MUST provide opinionated task settings that enable CloudWatch logging and data validation by default.
- **FR-013**: The submodule MUST use Full LOB mode by default and expose bounded parallel full-load controls without forwarding arbitrary upstream task settings.
- **FR-014**: The submodule MUST not start, resume, reload, or stop a migration task as part of ordinary Terraform apply behavior.
- **FR-015**: The submodule MUST apply consistent tags to all resources that support tagging.
- **FR-016**: The submodule MUST expose stable outputs for the replication instance, subnet group, endpoints, tasks, and log identifiers or ARNs.
- **FR-017**: The submodule MUST include a copy-pasteable neutral example for a private MySQL-to-Aurora MySQL full-load-and-CDC migration.
- **FR-018**: The submodule MUST include executable Terraform tests or plan-based assertions covering secure defaults, required input validation, endpoint creation, task settings, and outputs.
- **FR-019**: The submodule MUST document source-engine prerequisites such as binary logging, log retention, replication permissions, target object preparation, and TLS trust.
- **FR-020**: The submodule MUST document that routing, database creation, schema conversion, database users, secret values, migration execution, cutover, and rollback are consumer responsibilities.
- **FR-021**: All examples, tests, documentation, Terraform identifiers, and human-facing names MUST use neutral or DasMeta naming and MUST contain no customer-specific values.
- **FR-022**: Existing root-module and submodule consumers MUST see no planned changes when they do not call `modules/dms`.
- **FR-023**: The submodule MUST create a least-privilege IAM role that allows DMS to read only the supplied source and target secret ARNs and use only the supplied KMS key ARNs.
- **FR-024**: Source and target endpoints MUST use `verify-full` TLS and MUST require a registered DMS certificate ARN.
- **FR-025**: The migration task MUST use `TRUNCATE_BEFORE_LOAD` against a separately pre-created target schema.
- **FR-026**: Terraform apply MUST leave the migration task stopped; endpoint tests, premigration assessment, and task start remain explicit operator actions.

### Key Entities

- **Migration network**: Private subnet IDs, security group IDs, and subnet-group naming needed by the replication runtime.
- **Replication runtime**: Capacity, storage, availability, maintenance, and upgrade behavior of the provisioned DMS replication instance.
- **Migration endpoint**: A source or target database address, engine, port, database, TLS mode, and secret-backed authentication configuration.
- **Migration task**: Fixed full-load-and-CDC behavior, source and target endpoint references, table-selection mappings, task settings, validation, and logging behavior.
- **Migration observability**: Stable resource identifiers and log/metric integration points used by operators and monitoring automation.

## Success Criteria

### Measurable Outcomes

- **SC-001**: A consumer can configure a private full-load-and-CDC migration using one module block and no direct DMS resource blocks.
- **SC-002**: The primary example plans with zero public replication instances, zero plaintext password inputs, task logging enabled, and data validation enabled.
- **SC-003**: Invalid subnet counts, unsupported engines, and malformed configuration fail during Terraform validation with actionable messages.
- **SC-004**: Existing root RDS module tests and examples continue to validate without changes caused by the new submodule.
- **SC-005**: New tests cover every required input group, both endpoint roles, secure defaults, full-load-and-CDC behavior, Full LOB mode, truncate-before-load behavior, and all documented outputs.
- **SC-006**: README documentation identifies every prerequisite and explicitly separates infrastructure creation from task execution and production cutover.

## Assumptions

- The first release wraps `terraform-aws-modules/dms/aws` rather than direct AWS provider resources.
- The downstream repository retains its existing Terraform and AWS provider constraint conventions unless the technical plan proves a minimum-version increase is required.
- Consumers already manage VPC routing, database clusters, security-group rules, KMS keys, Secrets Manager secrets, and IAM policies outside this submodule.
- The module creates DMS infrastructure but does not authorize or initiate production data movement.
- Provisioned DMS replication instances are the first-release runtime; DMS Serverless is outside scope.
- EventBridge scheduling, automatic cutover, bidirectional replication, schema conversion, PostgreSQL, and cross-region orchestration are outside the first release.
- The shared constitution and `terraform-module-developer` skill remain the authoritative cross-repository governance sources.

## Clarifications

### Session 2026-07-22

- The first release is intentionally limited to the immediate MySQL/Aurora MySQL live-migration pattern rather than a general multi-engine DMS abstraction.
- The runtime is a provisioned `dms.r6i.large` replication instance using DMS 3.6.1, 100 GiB `gp3`, and Single-AZ placement.
- Terraform creates the migration task but does not start it; the operator starts it only after endpoint tests and the premigration assessment pass.
- The module creates the least-privilege Secrets Manager access role scoped to supplied secret and KMS ARNs.
- The task selects all tables in one explicitly supplied application schema and excludes system schemas.
- Full LOB mode is required because the target workload includes JSON and `LONGTEXT` columns whose maximum sizes have not been bounded safely.
- The target schema is created separately; DMS uses `TRUNCATE_BEFORE_LOAD`, with target triggers and scheduled events disabled during replication.
- Both DMS endpoints require `verify-full` TLS and a registered DMS certificate ARN.
- Endpoint hostname, port, username, and password are stored in Secrets Manager and are not duplicated as Terraform inputs because `aws_dms_endpoint` treats them as conflicting with `secrets_manager_arn`.
