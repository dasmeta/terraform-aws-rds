# Research: Opinionated AWS DMS Submodule

## Upstream module selection

**Decision**: Pin `terraform-aws-modules/dms/aws` to `2.6.0`.

**Rationale**: It supplies the provisioned replication instance, subnet group, standard DMS service roles, scoped endpoint-access IAM role, and stable runtime outputs. Its declared minimums are Terraform >= 1.0, AWS provider >= 5.96, and time provider >= 0.9.

**Alternatives considered**:

- Direct AWS resources for the entire implementation: rejected as unnecessary duplication.
- DMS Serverless: rejected because the approved production shape is a provisioned `dms.r6i.large` runtime.

## Existing certificate ARN support

**Decision**: Manage the source and target `aws_dms_endpoint` resources and their single `aws_dms_replication_task` directly while retaining upstream ownership of the runtime, subnet group, and roles.

**Rationale**: In v2.6.0, upstream endpoint `certificate_arn` is resolved only through `aws_dms_certificate.this[certificate_key]`; no input accepts an existing certificate ARN. Its provisioned task accepts an external target endpoint ARN but always resolves its source from an upstream endpoint key, so a direct task is required to connect both compliant endpoints.

**Alternatives considered**:

- Import/recreate certificates through upstream `certificates`: rejected because the consumer contract supplies registered certificate ARNs, not certificate PEM/wallet material.
- Use `require` or `none`: rejected because MySQL/Aurora MySQL supports `verify-full`, and hostname plus CA verification is mandatory.

## Secrets Manager IAM

**Decision**: Use upstream `create_access_iam_role`, `access_secret_arns`, and `access_kms_key_arns`; pass the resulting role ARN to both endpoints.

**Rationale**: Upstream generates a DMS trust policy with source-account/source-ARN protections and an access policy limited to `secretsmanager:GetSecretValue` plus `kms:Decrypt`/`kms:DescribeKey` on supplied ARNs.

**Important constraint**: `access_kms_key_arns` must be nonempty when the policy is enabled; upstream otherwise falls back to the account-wide key wildcard. The wrapper therefore requires explicit KMS key ARNs.

The AWS provider makes `server_name`, `port`, `username`, and `password` conflict with `secrets_manager_arn`. Those values therefore live only inside each referenced DMS-format secret and are not duplicated in the Terraform interface.

## Task lifecycle

**Decision**: Create the task stopped and do not expose auto-start as an input.

**Rationale**: Endpoint tests, premigration assessment, operational approval, and an explicit start are separate actions. Infrastructure apply does not authorize data movement.

## Task settings and mapping

**Decision**: Generate JSON internally rather than accepting arbitrary JSON.

**Rationale**: A fixed settings contract prevents unsafe drift and makes tests deterministic. Defaults are Full LOB, CloudWatch logging, DMS validation, `TRUNCATE_BEFORE_LOAD`, and bounded full-load parallelism. Table mappings include `%` only within one explicit application schema.

## Runtime defaults

**Decision**: Default to engine 3.6.1, `dms.r6i.large`, Single-AZ, 100 GiB, private accessibility, controlled maintenance, and gp3 where supported by the underlying DMS API/provider.

**Rationale**: This matches the approved production migration sizing and near-zero-data-loss CDC requirement. Capacity is boundedly overridable because load testing can justify adjustment.

## Observability

**Decision**: Enable task logging and validation by default and return stable resource identifiers plus calculated DMS task log group/stream names.

**Rationale**: Operators need full-load progress, CDC latency, task errors, and validation failures for cutover gates. Entire endpoint objects remain sensitive upstream and should not be forwarded as the wrapper's public contract.

## Repository compatibility

**Decision**: Add only `modules/dms`, a new test fixture, and documentation.

**Rationale**: Existing consumers do not call the submodule automatically, so the root module plan remains unchanged. No migration guide is needed for existing consumers.
