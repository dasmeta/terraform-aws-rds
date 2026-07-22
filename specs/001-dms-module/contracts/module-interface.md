# Contract: `modules/dms`

## Required inputs

| Input | Shape | Contract |
|---|---|---|
| `name` | `string` | Stable neutral resource identifier. |
| `network` | `object` | Contains at least two distinct `subnet_ids` and one or more `security_group_ids`. |
| `source_endpoint` | `object` | MySQL/Aurora engine, database, secret ARN, KMS key ARN, and registered certificate ARN; hostname/port/credentials live in the secret. |
| `target_endpoint` | `object` | Same bounded secret-backed shape as source. |
| `schema_name` | `string` | One explicit non-system application schema. |

## Optional inputs with defaults

| Input | Default | Bounds |
|---|---|---|
| `instance_class` | `dms.r6i.large` | Nonempty DMS instance class. |
| `engine_version` | `3.6.1` | Nonempty supported provisioned DMS version. |
| `allocated_storage` | `100` | DMS-supported GiB range. |
| `multi_az` | `false` | Boolean. |
| `maintenance_window` | `null` | AWS DMS maintenance-window syntax when supplied. |
| `max_full_load_subtasks` | `8` | 1 through provider/DMS-supported maximum. |
| `transaction_consistency_timeout` | `600` | Positive seconds. |
| `commit_rate` | `10000` | Positive row count. |
| `tags` | `{}` | String map. |

## Fixed behavior

- Runtime is provisioned and non-public.
- Endpoint TLS mode is `verify-full`.
- Authentication uses Secrets Manager only.
- Migration type is `full-load-and-cdc`.
- Table selection includes `%` in `schema_name` only.
- Full LOB mode, task logging, and DMS data validation are enabled.
- Target table preparation mode is `TRUNCATE_BEFORE_LOAD`.
- Terraform creates but never starts the task.

## Outputs

| Output | Sensitivity | Purpose |
|---|---|---|
| `replication_subnet_group_id` | normal | Network placement evidence. |
| `replication_instance_arn` | normal | Runtime operations and monitoring. |
| `replication_instance_private_ips` | normal | Network diagnostics. |
| `source_endpoint_id`, `source_endpoint_arn` | normal | Endpoint tests and diagnostics. |
| `target_endpoint_id`, `target_endpoint_arn` | normal | Endpoint tests and diagnostics. |
| `replication_task_id`, `replication_task_arn` | normal | Task operation and monitoring. |
| `access_iam_role_arn` | normal | IAM audit evidence. |
| `task_log_group_name`, `task_log_stream_name` | normal | CloudWatch navigation and alert wiring. |

## Consumer-owned responsibilities

VPC connectivity, DNS, database/schema conversion and creation, database users, secret contents and resource policies, CA registration, source binary logging, target trigger/event control, endpoint tests, premigration assessment, task start/stop, monitoring thresholds, cutover, rollback, and cleanup remain outside this module.
