# AWS DMS private live-migration submodule

This opinionated submodule creates a private provisioned AWS DMS runtime for one MySQL/Aurora MySQL full-load-and-CDC migration. Terraform creates the task in a stopped state; operators test endpoints, run the premigration assessment, and start the task separately.

## Example

```hcl
module "database_migration" {
  source = "dasmeta/rds/aws//modules/dms"

  name = "dasmeta-live-migration"

  network = {
    subnet_ids         = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]
    security_group_ids = ["sg-0123456789abcdef0"]
  }

  source_endpoint = {
    engine_name     = "aurora"
    database_name   = "application"
    secret_arn      = "arn:aws:secretsmanager:eu-central-1:111122223333:secret:dms-source-example"
    kms_key_arn     = "arn:aws:kms:eu-central-1:111122223333:key/00000000-0000-0000-0000-000000000001"
    certificate_arn = "arn:aws:dms:eu-central-1:111122223333:cert:SOURCECERTEXAMPLE"
  }

  target_endpoint = {
    engine_name     = "aurora"
    database_name   = "application"
    secret_arn      = "arn:aws:secretsmanager:eu-central-1:111122223333:secret:dms-target-example"
    kms_key_arn     = "arn:aws:kms:eu-central-1:111122223333:key/00000000-0000-0000-0000-000000000002"
    certificate_arn = "arn:aws:dms:eu-central-1:111122223333:cert:TARGETCERTEXAMPLE"
  }

  schema_name = "application"

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

## Required preparation

- Put `username`, `password`, `serverName`, and `port` in each Secrets Manager secret. The AWS provider forbids duplicating those fields when `secrets_manager_arn` is used.
- Register the trusted source and target CA certificates with AWS DMS and supply their certificate ARNs.
- Enable MySQL/Aurora MySQL binary logging and retain logs for the initial load plus CDC catch-up.
- Create least-privilege source replication and target DDL/DML users.
- Pre-create a compatible target schema; schema conversion is outside this module.
- Disable target triggers and scheduled events during replication.
- Provide private DNS, routes, NACLs, and security-group rules from DMS to both databases, Secrets Manager, KMS, and CloudWatch.

## Safe operating sequence

1. Apply the module and confirm the task remains stopped.
2. Test both DMS endpoint connections.
3. Run and review the DMS premigration assessment.
4. Confirm task logging, validation, source log retention, monitoring, and rollback readiness.
5. Start the task through the approved operational process, outside Terraform.

This module does not create database objects or users, secret contents, VPC routing, certificate registrations, monitoring alarms, cutover automation, rollback automation, or cleanup workflows.

## Compatibility note

The module pins `terraform-aws-modules/dms/aws` 2.6.0. That upstream release emits deprecation warnings with AWS provider v6 for `aws_region.name` and IAM `managed_policy_arns`; these are upstream warnings and do not prevent validation or planning.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.96 |
| <a name="requirement_time"></a> [time](#requirement\_time) | >= 0.9 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.55.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_this"></a> [this](#module\_this) | terraform-aws-modules/dms/aws | 2.6.0 |

## Resources

| Name | Type |
|------|------|
| [aws_dms_endpoint.source](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dms_endpoint) | resource |
| [aws_dms_endpoint.target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dms_endpoint) | resource |
| [aws_dms_replication_task.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dms_replication_task) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allocated_storage"></a> [allocated\_storage](#input\_allocated\_storage) | DMS replication instance storage in GiB. | `number` | `100` | no |
| <a name="input_commit_rate"></a> [commit\_rate](#input\_commit\_rate) | Maximum records transferred together during full load. | `number` | `10000` | no |
| <a name="input_engine_version"></a> [engine\_version](#input\_engine\_version) | DMS replication engine version. | `string` | `"3.6.1"` | no |
| <a name="input_instance_class"></a> [instance\_class](#input\_instance\_class) | DMS replication instance class. | `string` | `"dms.r6i.large"` | no |
| <a name="input_maintenance_window"></a> [maintenance\_window](#input\_maintenance\_window) | Optional weekly DMS maintenance window in UTC. | `string` | `null` | no |
| <a name="input_max_full_load_subtasks"></a> [max\_full\_load\_subtasks](#input\_max\_full\_load\_subtasks) | Maximum number of tables loaded concurrently. | `number` | `8` | no |
| <a name="input_multi_az"></a> [multi\_az](#input\_multi\_az) | Whether the provisioned DMS replication instance is Multi-AZ. | `bool` | `false` | no |
| <a name="input_name"></a> [name](#input\_name) | Stable identifier used for the DMS migration resources. | `string` | n/a | yes |
| <a name="input_network"></a> [network](#input\_network) | Private subnet and existing security group placement for the DMS replication instance. | <pre>object({<br/>    subnet_ids         = list(string)<br/>    security_group_ids = list(string)<br/>  })</pre> | n/a | yes |
| <a name="input_schema_name"></a> [schema\_name](#input\_schema\_name) | Explicit application schema whose tables are included in the migration. | `string` | n/a | yes |
| <a name="input_source_endpoint"></a> [source\_endpoint](#input\_source\_endpoint) | Secret-backed MySQL-compatible source endpoint using a registered DMS certificate. | <pre>object({<br/>    engine_name                 = string<br/>    database_name               = string<br/>    secret_arn                  = string<br/>    kms_key_arn                 = string<br/>    certificate_arn             = string<br/>    extra_connection_attributes = optional(string)<br/>  })</pre> | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to all supported resources. | `map(string)` | `{}` | no |
| <a name="input_target_endpoint"></a> [target\_endpoint](#input\_target\_endpoint) | Secret-backed MySQL-compatible target endpoint using a registered DMS certificate. | <pre>object({<br/>    engine_name                 = string<br/>    database_name               = string<br/>    secret_arn                  = string<br/>    kms_key_arn                 = string<br/>    certificate_arn             = string<br/>    extra_connection_attributes = optional(string)<br/>  })</pre> | n/a | yes |
| <a name="input_transaction_consistency_timeout"></a> [transaction\_consistency\_timeout](#input\_transaction\_consistency\_timeout) | Seconds DMS waits for open transactions before beginning full load. | `number` | `600` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_access_iam_role_arn"></a> [access\_iam\_role\_arn](#output\_access\_iam\_role\_arn) | ARN of the scoped DMS Secrets Manager access role. |
| <a name="output_migration_type"></a> [migration\_type](#output\_migration\_type) | Effective DMS migration type. |
| <a name="output_replication_instance_allocated_storage"></a> [replication\_instance\_allocated\_storage](#output\_replication\_instance\_allocated\_storage) | Effective DMS allocated storage in GiB. |
| <a name="output_replication_instance_arn"></a> [replication\_instance\_arn](#output\_replication\_instance\_arn) | ARN of the DMS replication instance. |
| <a name="output_replication_instance_class"></a> [replication\_instance\_class](#output\_replication\_instance\_class) | Effective DMS replication instance class. |
| <a name="output_replication_instance_engine_version"></a> [replication\_instance\_engine\_version](#output\_replication\_instance\_engine\_version) | Effective DMS engine version. |
| <a name="output_replication_instance_multi_az"></a> [replication\_instance\_multi\_az](#output\_replication\_instance\_multi\_az) | Effective DMS Multi-AZ setting. |
| <a name="output_replication_instance_private_ips"></a> [replication\_instance\_private\_ips](#output\_replication\_instance\_private\_ips) | Private IP addresses of the DMS replication instance. |
| <a name="output_replication_instance_publicly_accessible"></a> [replication\_instance\_publicly\_accessible](#output\_replication\_instance\_publicly\_accessible) | Effective public accessibility setting for contract verification. |
| <a name="output_replication_subnet_group_id"></a> [replication\_subnet\_group\_id](#output\_replication\_subnet\_group\_id) | ID of the managed DMS replication subnet group. |
| <a name="output_replication_task_arn"></a> [replication\_task\_arn](#output\_replication\_task\_arn) | ARN of the stopped DMS replication task. |
| <a name="output_replication_task_id"></a> [replication\_task\_id](#output\_replication\_task\_id) | ID of the stopped DMS replication task. |
| <a name="output_source_endpoint_arn"></a> [source\_endpoint\_arn](#output\_source\_endpoint\_arn) | ARN of the source DMS endpoint. |
| <a name="output_source_endpoint_id"></a> [source\_endpoint\_id](#output\_source\_endpoint\_id) | ID of the source DMS endpoint. |
| <a name="output_source_endpoint_ssl_mode"></a> [source\_endpoint\_ssl\_mode](#output\_source\_endpoint\_ssl\_mode) | Effective source endpoint TLS verification mode. |
| <a name="output_table_mappings"></a> [table\_mappings](#output\_table\_mappings) | Generated explicit-schema DMS table mappings JSON. |
| <a name="output_target_endpoint_arn"></a> [target\_endpoint\_arn](#output\_target\_endpoint\_arn) | ARN of the target DMS endpoint. |
| <a name="output_target_endpoint_id"></a> [target\_endpoint\_id](#output\_target\_endpoint\_id) | ID of the target DMS endpoint. |
| <a name="output_target_endpoint_ssl_mode"></a> [target\_endpoint\_ssl\_mode](#output\_target\_endpoint\_ssl\_mode) | Effective target endpoint TLS verification mode. |
| <a name="output_task_log_group_name"></a> [task\_log\_group\_name](#output\_task\_log\_group\_name) | CloudWatch log group used by the DMS replication task. |
| <a name="output_task_log_stream_name"></a> [task\_log\_stream\_name](#output\_task\_log\_stream\_name) | CloudWatch log stream used by the DMS replication task. |
| <a name="output_task_settings"></a> [task\_settings](#output\_task\_settings) | Generated opinionated DMS task settings JSON. |
| <a name="output_task_start_replication"></a> [task\_start\_replication](#output\_task\_start\_replication) | Whether Terraform starts the DMS task. Always false. |
<!-- END_TF_DOCS -->
