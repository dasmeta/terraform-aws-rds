# Data Model: Opinionated AWS DMS Submodule

## Module input model

### Identity

- `name`: stable prefix/identifier for the subnet group, replication instance, endpoints, task, and access role.
- `tags`: common tags merged onto supported resources.

### Migration network

- `subnet_ids`: at least two distinct private subnet IDs; caller owns route tables and cross-VPC reachability.
- `security_group_ids`: one or more existing security groups for the replication instance.

Validation states: invalid when fewer than two distinct subnets or no security group is supplied.

### Replication runtime

- `instance_class`: defaults to `dms.r6i.large`.
- `allocated_storage`: defaults to 100 GiB.
- `engine_version`: defaults to `3.6.1`.
- `multi_az`: defaults to false.
- `maintenance_window`: optional bounded override.
- `kms_key_arn`: optional DMS replication-instance encryption key.

Invariant: `publicly_accessible` is not consumer configurable and remains false.

### Migration endpoint

Exactly two instances exist: `source` and `target`.

- `engine_name`: `mysql` or `aurora`.
- `database_name`: database/catalog name expected by DMS.
- `secret_arn`: Secrets Manager credential reference.
- `kms_key_arn`: KMS key used to encrypt that secret.
- `certificate_arn`: already registered AWS DMS certificate ARN.
- optional bounded extra connection attributes if needed for Secrets Manager VPC endpoint override.

Invariants: `ssl_mode` is always `verify-full`; hostname, port, username, and password exist only in the secret; all three ARNs are nonempty.

### Migration selection

- `schema_name`: one explicit non-system application schema.
- `table_name`: internally fixed to `%`.

Rejected schema names include `mysql`, `information_schema`, `performance_schema`, and `sys`.

### Migration task controls

- `max_full_load_subtasks`: bounded parallel table loaders.
- `parallel_load_threads`: bounded parallel load threads when applicable.
- `transaction_consistency_timeout`: bounded consistency wait.
- `commit_rate`: bounded full-load commit rate.

Invariants: migration type is `full-load-and-cdc`; Full LOB mode, logging, validation, and `TRUNCATE_BEFORE_LOAD` are enabled; auto-start is unavailable.

## Resource relationships

```text
private subnets ──> replication subnet group ──> replication instance
security groups ────────────────────────────────┘

source secret + KMS key + certificate ──> source endpoint ──┐
target secret + KMS key + certificate ──> target endpoint ──┼─> stopped full-load-and-CDC task
explicit schema ─────────────────────────────────────────────┘

secret/KMS ARNs ──> scoped DMS access role ──> both endpoints
```

## Lifecycle states

1. Terraform creates IAM roles, subnet group, runtime, endpoints, and task.
2. Task remains `stopped` after apply.
3. Operator tests both endpoint connections.
4. Operator runs and reviews premigration assessment.
5. Operator explicitly starts the task outside Terraform.
6. Task progresses through full load into CDC.
7. Cutover and rollback decisions remain external operational procedures.

Terraform must not encode transitions 3 through 7.

## Stable outputs

- Replication subnet group ID.
- Replication instance ARN and private IPs.
- Source and target endpoint IDs and ARNs.
- Replication task ID and ARN.
- Secrets access IAM role ARN.
- CloudWatch task log group and stream identifiers.

No output contains secret values or complete sensitive endpoint objects.
