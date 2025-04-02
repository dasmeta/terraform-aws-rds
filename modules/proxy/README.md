## This terraform module allows to create rds cluster attached rds proxy

### basic example

```terraform
module "rds_proxy" {
    source  = "dasmeta/rds/aws//modules/proxy"
    version = "1.4.0"

    name                   = "my-test-proxy" # in this case this will be also identifier of rds cluster
    subnet_ids             = ["subnet-xxxxxxxx","subnet-xxxxxx"]
    vpc_security_group_ids = ["sg-xxxxxxxxx"]
    credentials_secret_arn = "arn-of-secret-containing-db-username-and-password"
}
```
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

No requirements.

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_db_password"></a> [db\_password](#module\_db\_password) | dasmeta/modules/aws//modules/secret | 2.18.2 |
| <a name="module_this"></a> [this](#module\_this) | terraform-aws-modules/rds-proxy/aws | 3.1.0 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_client_auth_type"></a> [client\_auth\_type](#input\_client\_auth\_type) | The type of authentication the proxy uses for connections from clients | `string` | `"MYSQL_NATIVE_PASSWORD"` | no |
| <a name="input_credentials_secret_arn"></a> [credentials\_secret\_arn](#input\_credentials\_secret\_arn) | The aws secret manager secret arn which contains rds cluster username/password accesses, NOTE: if you do not set this you have to set db\_username/db\_password params | `string` | `null` | no |
| <a name="input_credentials_secret_recovery_window"></a> [credentials\_secret\_recovery\_window](#input\_credentials\_secret\_recovery\_window) | The aws secret manager secret recovery window in days. If value is 0 this means the secret will be removed immediately | `number` | `0` | no |
| <a name="input_db_cluster_identifier"></a> [db\_cluster\_identifier](#input\_db\_cluster\_identifier) | The rds db cluster name/identifier to use. If this value not passed then it will use proxy name as identifier | `string` | `""` | no |
| <a name="input_db_instance_identifier"></a> [db\_instance\_identifier](#input\_db\_instance\_identifier) | The rds db instance name/identifier to use | `string` | `""` | no |
| <a name="input_db_password"></a> [db\_password](#input\_db\_password) | Password for the master DB user. NOTE: this variable should be set only in case if you do not set cluster\_master\_user\_secret variable | `string` | `null` | no |
| <a name="input_db_username"></a> [db\_username](#input\_db\_username) | Username for the master DB user. NOTE: this variable should be set only in case if you do not set cluster\_master\_user\_secret variable | `string` | `null` | no |
| <a name="input_debug_logging"></a> [debug\_logging](#input\_debug\_logging) | Whether the enhanced logging is enabled | `bool` | `false` | no |
| <a name="input_endpoints"></a> [endpoints](#input\_endpoints) | map of {<name>: <configs>} additional proxy endpoints(by default we have already one read/write endpoint), only name can be passed all other attributes are optional. | `any` | `{}` | no |
| <a name="input_engine_family"></a> [engine\_family](#input\_engine\_family) | The cluster engine family, valid values are `MYSQL` or `POSTGRESQL` | `string` | `"MYSQL"` | no |
| <a name="input_iam_auth"></a> [iam\_auth](#input\_iam\_auth) | Whether IAM auth enabled for proxy | `string` | `"DISABLED"` | no |
| <a name="input_idle_client_timeout"></a> [idle\_client\_timeout](#input\_idle\_client\_timeout) | The timeout of idle connections, default is 30 minutes | `number` | `1800` | no |
| <a name="input_name"></a> [name](#input\_name) | The name/identifier of rds proxy | `string` | n/a | yes |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | A list of VPC subnet IDs | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | The tags to attach resources | `any` | `{}` | no |
| <a name="input_target_db_cluster"></a> [target\_db\_cluster](#input\_target\_db\_cluster) | Whether target is cluster | `bool` | `true` | no |
| <a name="input_vpc_security_group_ids"></a> [vpc\_security\_group\_ids](#input\_vpc\_security\_group\_ids) | List of VPC security groups to associate | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arn"></a> [arn](#output\_arn) | The arn of proxy |
| <a name="output_endpoint"></a> [endpoint](#output\_endpoint) | Proxy endpoint to connect |
| <a name="output_endpoints"></a> [endpoints](#output\_endpoints) | All created proxy endpoints |
| <a name="output_id"></a> [id](#output\_id) | The id of proxy |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
