## This terraform module allows to create aws rds cluster by using various engine types and configurations, it allows also to enable/create rds cluster attached rds proxy.

## NOTE: When creating rds with proxy, first create the rds only and then enable proxy and re-apply

## module upgrade guide
- from <1.4.0 versions to >=1.4.0 version upgrade
    - make sure you moved the state of "db" underlying module by using command like following
        ```sh
        terraform state mv module.<rds-module-name>.module.db module.<rds-module-name>.module.db[0]
        ```
    - if you had no storage_type set explicitly then set it to "gp2"



## How to use (more examples/tests can be found in [./tests](./tests) folder)

### Case 1. Create Security group and create RDS

```terraform
data "aws_vpc" "main" {
  id = "vpc-xxxxxxx"
}

module "rds" {
    source  = "dasmeta/rds/aws"
    version = "1.4.0"

    allocated_storage    = 20
    storage_type         = "gp2"
    engine               = "mysql"
    engine_version       = "5.7.26"
    instance_class       = "db.t2.micro"
    identifier           = "db"
    db_name              = "db"
    db_username          = "root"
    db_password          = "some-password"
    parameter_group_name = "default.mysql5.7"
    vpc_id               = "${data.aws_vpc.main.id}"
    subnet_ids           = ["subnet-xxxxxxxx","subnet-xxxxxx"]
}
```

### Case 2. Create RDS and pass custom/external created security group ids

```terraform
module "rds" {
    source  = "dasmeta/rds/aws"
    version = "1.4.0"

    allocated_storage    = 20
    storage_type         = "gp2"
    engine               = "mysql"
    engine_version       = "5.7.26"
    instance_class       = "db.t2.micro"
    identifier           = "db"
    db_name              = "db"
    db_username          = "root"
    db_password          = "some-password"
    parameter_group_name = "default.mysql5.7"

    vpc_id                 = "vpc-xxxxxxxxxxxx"
    subnet_ids             = ["subnet-xxxxxxx","subnet-xxxxxxxx"]

    create_security_group = false
    vpc_security_group_ids = ["sg-xxxxxxxxx"]
}
```

## contribution
### please enable git hooks by running the following command
```sh
git config --global core.hooksPath ./githooks # enables git hooks globally
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cloudwatch_metric_filters"></a> [cloudwatch\_metric\_filters](#module\_cloudwatch\_metric\_filters) | dasmeta/monitoring/aws//modules/cloudwatch-log-based-metrics | 1.13.2 |
| <a name="module_cw_alerts"></a> [cw\_alerts](#module\_cw\_alerts) | dasmeta/monitoring/aws//modules/alerts | 1.3.5 |
| <a name="module_db"></a> [db](#module\_db) | terraform-aws-modules/rds/aws | 6.10.0 |
| <a name="module_db_aurora"></a> [db\_aurora](#module\_db\_aurora) | terraform-aws-modules/rds-aurora/aws | 9.11.0 |
| <a name="module_proxy"></a> [proxy](#module\_proxy) | ./modules/proxy | n/a |
| <a name="module_security_group"></a> [security\_group](#module\_security\_group) | terraform-aws-modules/security-group/aws | 5.2.0 |

## Resources

| Name | Type |
|------|------|
| [aws_db_instance.database](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/db_instance) | data source |
| [aws_ec2_instance_type.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ec2_instance_type) | data source |
| [aws_vpc.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alarms"></a> [alarms](#input\_alarms) | n/a | <pre>object({<br/>    enabled       = optional(bool, true)<br/>    sns_topic     = string<br/>    custom_values = optional(any, {})<br/>  })</pre> | n/a | yes |
| <a name="input_allocated_storage"></a> [allocated\_storage](#input\_allocated\_storage) | The allocated storage in gigabytes | `number` | `20` | no |
| <a name="input_apply_immediately"></a> [apply\_immediately](#input\_apply\_immediately) | Specifies whether any database modifications are applied immediately, or during the next maintenance window | `bool` | `false` | no |
| <a name="input_aurora_configs"></a> [aurora\_configs](#input\_aurora\_configs) | The aws rd aurora specific configurations | <pre>object({<br/>    engine_mode                        = optional(string, "provisioned") # The database engine mode. Valid values: `global`, `multimaster`, `parallelquery`, `provisioned`, `serverless`(serverless is deprecated)<br/>    autoscaling_enabled                = optional(bool, false)           # Whether autoscaling enabled<br/>    autoscaling_min_capacity           = optional(number, 0)             # Min number of read replicas<br/>    autoscaling_max_capacity           = optional(number, 2)             # Max number of read replicas permitted<br/>    instances                          = optional(any, {})               # Cluster instances configs<br/>    serverlessv2_scaling_configuration = optional(any, {})               # for enabling serverless-2(the serverless-1(engine_mode=serverless, scaling_configuration is set) is deprecated), valid when `engine_mode` is set to `provisioned`<br/>  })</pre> | `{}` | no |
| <a name="input_backup_retention_period"></a> [backup\_retention\_period](#input\_backup\_retention\_period) | The days to retain backups for | `number` | `35` | no |
| <a name="input_backup_window"></a> [backup\_window](#input\_backup\_window) | The daily time range (in UTC) during which automated backups are created if they are enabled. Example: '09:46-10:16'. Must not overlap with maintenance\_window | `string` | `"03:00-06:00"` | no |
| <a name="input_cloudwatch_log_group_retention_in_days"></a> [cloudwatch\_log\_group\_retention\_in\_days](#input\_cloudwatch\_log\_group\_retention\_in\_days) | The number of days to retain CloudWatch logs for the DB instance | `number` | `30` | no |
| <a name="input_create_cloudwatch_log_group"></a> [create\_cloudwatch\_log\_group](#input\_create\_cloudwatch\_log\_group) | Determines whether a CloudWatch log group is created for each enabled\_cloudwatch\_logs\_exports | `bool` | `true` | no |
| <a name="input_create_db_option_group"></a> [create\_db\_option\_group](#input\_create\_db\_option\_group) | Create a database option group | `bool` | `false` | no |
| <a name="input_create_db_parameter_group"></a> [create\_db\_parameter\_group](#input\_create\_db\_parameter\_group) | Whether to create a database parameter group | `bool` | `false` | no |
| <a name="input_create_db_subnet_group"></a> [create\_db\_subnet\_group](#input\_create\_db\_subnet\_group) | Whether to create a database subnet group | `bool` | `true` | no |
| <a name="input_create_monitoring_role"></a> [create\_monitoring\_role](#input\_create\_monitoring\_role) | Create IAM role with a defined name that permits RDS to send enhanced monitoring metrics to CloudWatch Logs | `bool` | `false` | no |
| <a name="input_create_security_group"></a> [create\_security\_group](#input\_create\_security\_group) | Whether to create security group and attach ingress/egress rules which will be used for rds instances(and rds proxy if we enabled it), if you already have one and do not want to create new security group you can explicitly set this variable to false and pass group id by using var.vpc\_security\_group\_ids | `bool` | `true` | no |
| <a name="input_db_instance_tags"></a> [db\_instance\_tags](#input\_db\_instance\_tags) | Additional tags for the DB instance | `map(any)` | `{}` | no |
| <a name="input_db_name"></a> [db\_name](#input\_db\_name) | The DB name to create. If omitted, no database is created initially | `string` | n/a | yes |
| <a name="input_db_option_group_tags"></a> [db\_option\_group\_tags](#input\_db\_option\_group\_tags) | Additional tags for the DB option group | `map(any)` | `{}` | no |
| <a name="input_db_parameter_group_tags"></a> [db\_parameter\_group\_tags](#input\_db\_parameter\_group\_tags) | n/a | `map(any)` | `{}` | no |
| <a name="input_db_password"></a> [db\_password](#input\_db\_password) | Password for the master DB user. Note that this may show up in logs, and it will be stored in the state file | `string` | n/a | yes |
| <a name="input_db_subnet_group_name"></a> [db\_subnet\_group\_name](#input\_db\_subnet\_group\_name) | Name of DB subnet group. DB instance will be created in the VPC associated with the DB subnet group. If unspecified, will be created in the default VPC | `string` | `null` | no |
| <a name="input_db_subnet_group_tags"></a> [db\_subnet\_group\_tags](#input\_db\_subnet\_group\_tags) | Additional tags for the  DB parameter group | `map(any)` | `{}` | no |
| <a name="input_db_subnet_group_use_name_prefix"></a> [db\_subnet\_group\_use\_name\_prefix](#input\_db\_subnet\_group\_use\_name\_prefix) | Determines whether to use `subnet_group_name` as is or create a unique name beginning with the `subnet_group_name` as the prefix | `bool` | `false` | no |
| <a name="input_db_username"></a> [db\_username](#input\_db\_username) | Username for the master DB user | `string` | n/a | yes |
| <a name="input_deletion_protection"></a> [deletion\_protection](#input\_deletion\_protection) | The database can't be deleted when this value is set to true | `bool` | `false` | no |
| <a name="input_egress_with_cidr_blocks"></a> [egress\_with\_cidr\_blocks](#input\_egress\_with\_cidr\_blocks) | n/a | `list(map(string))` | `[]` | no |
| <a name="input_enabled_cloudwatch_logs_exports"></a> [enabled\_cloudwatch\_logs\_exports](#input\_enabled\_cloudwatch\_logs\_exports) | List of log types to enable for exporting to CloudWatch logs. If omitted, no logs will be exported. Valid values (depending on engine): alert, audit, error, general, listener, slowquery, trace, postgresql (PostgreSQL), upgrade (PostgreSQL) | `list(string)` | `[]` | no |
| <a name="input_enforce_client_tls"></a> [enforce\_client\_tls](#input\_enforce\_client\_tls) | parameter to enforce tls connections from clients | `bool` | `true` | no |
| <a name="input_engine"></a> [engine](#input\_engine) | The database engine to use | `string` | `"mysql"` | no |
| <a name="input_engine_version"></a> [engine\_version](#input\_engine\_version) | The engine version to use | `string` | `"5.7.26"` | no |
| <a name="input_iam_database_authentication_enabled"></a> [iam\_database\_authentication\_enabled](#input\_iam\_database\_authentication\_enabled) | Specifies whether or not the mappings of AWS Identity and Access Management (IAM) accounts to database accounts are enabled | `bool` | `true` | no |
| <a name="input_identifier"></a> [identifier](#input\_identifier) | Specifies the identifier of the CA certificate for the DB instance | `string` | n/a | yes |
| <a name="input_ingress_with_cidr_blocks"></a> [ingress\_with\_cidr\_blocks](#input\_ingress\_with\_cidr\_blocks) | n/a | `list(map(string))` | `[]` | no |
| <a name="input_instance_class"></a> [instance\_class](#input\_instance\_class) | The instance type of the RDS instance | `string` | `"db.t3.micro"` | no |
| <a name="input_maintenance_window"></a> [maintenance\_window](#input\_maintenance\_window) | The window to perform maintenance in. Syntax: 'ddd:hh24:mi-ddd:hh24:mi'. Eg: 'Mon:00:00-Mon:03:00' | `string` | `"Mon:00:00-Mon:03:00"` | no |
| <a name="input_major_engine_version"></a> [major\_engine\_version](#input\_major\_engine\_version) | Specifies the major version of the engine that this option group should be associated with | `string` | `"5.7"` | no |
| <a name="input_manage_master_user_password"></a> [manage\_master\_user\_password](#input\_manage\_master\_user\_password) | Set to true to allow RDS to manage the master user password in Secrets Manager | `bool` | `false` | no |
| <a name="input_max_allocated_storage"></a> [max\_allocated\_storage](#input\_max\_allocated\_storage) | Specifies the value for Storage Autoscaling | `number` | `100` | no |
| <a name="input_monitoring_interval"></a> [monitoring\_interval](#input\_monitoring\_interval) | The interval, in seconds, between points when Enhanced Monitoring metrics are collected for the DB instance. To disable collecting Enhanced Monitoring metrics, specify 0. The default is 0. Valid Values: 0, 1, 5, 10, 15, 30, 60 | `number` | `0` | no |
| <a name="input_monitoring_role_name"></a> [monitoring\_role\_name](#input\_monitoring\_role\_name) | Name of the IAM role which will be created when create\_monitoring\_role is enabled | `string` | `null` | no |
| <a name="input_multi_az"></a> [multi\_az](#input\_multi\_az) | Specifies if the RDS instance is multi-AZ | `bool` | `true` | no |
| <a name="input_options"></a> [options](#input\_options) | A list of Options to apply | `list(any)` | <pre>[<br/>  {<br/>    "option_name": "MARIADB_AUDIT_PLUGIN",<br/>    "option_settings": [<br/>      {<br/>        "name": "SERVER_AUDIT_EVENTS",<br/>        "value": "CONNECT"<br/>      },<br/>      {<br/>        "name": "SERVER_AUDIT_FILE_ROTATIONS",<br/>        "value": "37"<br/>      }<br/>    ]<br/>  }<br/>]</pre> | no |
| <a name="input_parameter_group_name"></a> [parameter\_group\_name](#input\_parameter\_group\_name) | Name of the DB parameter group to associate or create | `string` | `"default.mysql5.7"` | no |
| <a name="input_parameter_group_type"></a> [parameter\_group\_type](#input\_parameter\_group\_type) | type of the parameter group. Valid values are instance and cluster | `string` | `"instance"` | no |
| <a name="input_parameters"></a> [parameters](#input\_parameters) | A list of DB parameters (map) to apply | <pre>list(object({<br/>    name  = string<br/>    value = string<br/>    # context      = optional(string, "instance")  # The context where parameter will be used, supported values are "instance" and "cluster"<br/>    # apply_method = optional(string, "immediate") # The apply method for parameter, supported values are "immediate" and "pending-reboot"<br/>  }))</pre> | `[]` | no |
| <a name="input_port"></a> [port](#input\_port) | The port on which the DB accepts connections | `number` | `null` | no |
| <a name="input_proxy"></a> [proxy](#input\_proxy) | The aws rds proxy specific configurations | <pre>object({<br/>    enabled             = optional(bool, false)                     # whether rds proxy is enabled<br/>    endpoints           = optional(any, {})                         # map of {<name>: <configs>} additional proxy endpoints(by default we have already one read/write endpoint), for more info check resource doc https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_proxy_endpoint<br/>    client_auth_type    = optional(string, "MYSQL_NATIVE_PASSWORD") # The type of authentication the proxy uses for connections from clients<br/>    iam_auth            = optional(string, "DISABLED")              # Whether IAM auth enabled<br/>    target_db_cluster   = optional(bool, true)                      # Whether the target db is cluster<br/>    debug_logging       = optional(bool, false)                     # Whether enhanced logging is enabled<br/>    idle_client_timeout = optional(number, 1800)                    # The timeout of idle connections, default is 30 minutes<br/>  })</pre> | `{}` | no |
| <a name="input_publicly_accessible"></a> [publicly\_accessible](#input\_publicly\_accessible) | Whether the database is accessible publicly. Note that if you need to enable this you have to place db on public subnets | `bool` | `false` | no |
| <a name="input_security_group_description"></a> [security\_group\_description](#input\_security\_group\_description) | n/a | `string` | `"MySQL security group"` | no |
| <a name="input_security_group_name"></a> [security\_group\_name](#input\_security\_group\_name) | n/a | `string` | `"db_security_group"` | no |
| <a name="input_set_vpc_security_group_rules"></a> [set\_vpc\_security\_group\_rules](#input\_set\_vpc\_security\_group\_rules) | Whether to automatically add security group rules allowing access to db from vpc network | `bool` | `true` | no |
| <a name="input_skip_final_snapshot"></a> [skip\_final\_snapshot](#input\_skip\_final\_snapshot) | Determines whether a final DB snapshot is created before the DB instance is deleted. If true is specified, no DBSnapshot is created. If false is specified, a DB snapshot is created before the DB instance is deleted | `bool` | `false` | no |
| <a name="input_slow_queries"></a> [slow\_queries](#input\_slow\_queries) | n/a | <pre>object({<br/>    enabled        = optional(bool, true)<br/>    query_duration = optional(number, 3)<br/>  })</pre> | <pre>{<br/>  "enabled": true,<br/>  "query_duration": 3<br/>}</pre> | no |
| <a name="input_storage_encrypted"></a> [storage\_encrypted](#input\_storage\_encrypted) | Specifies whether the DB instance is encrypted | `bool` | `true` | no |
| <a name="input_storage_type"></a> [storage\_type](#input\_storage\_type) | One of 'standard' (magnetic), 'gp2' (general purpose SSD), gp3, or 'io1' (provisioned IOPS SSD). The default is 'io1' if iops is specified, 'gp2' if not | `string` | `null` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | A list of VPC subnet IDs | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A mapping of tags to assign to all resources | `map(any)` | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | n/a | `string` | `""` | no |
| <a name="input_vpc_security_group_ids"></a> [vpc\_security\_group\_ids](#input\_vpc\_security\_group\_ids) | List of VPC security groups to associate | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_db_instance_address"></a> [db\_instance\_address](#output\_db\_instance\_address) | The address of the RDS instance |
| <a name="output_db_instance_arn"></a> [db\_instance\_arn](#output\_db\_instance\_arn) | The ARN of the RDS instance |
| <a name="output_db_instance_cloudwatch_log_groups"></a> [db\_instance\_cloudwatch\_log\_groups](#output\_db\_instance\_cloudwatch\_log\_groups) | Map of CloudWatch log groups created and their attributes |
| <a name="output_db_instance_endpoint"></a> [db\_instance\_endpoint](#output\_db\_instance\_endpoint) | The connection endpoint |
| <a name="output_db_instance_port"></a> [db\_instance\_port](#output\_db\_instance\_port) | The database port |
| <a name="output_db_password"></a> [db\_password](#output\_db\_password) | DB password |
| <a name="output_db_username"></a> [db\_username](#output\_db\_username) | DB username |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
