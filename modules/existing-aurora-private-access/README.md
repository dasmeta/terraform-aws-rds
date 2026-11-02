# Existing Aurora private access

Adopt an existing Aurora cluster, its instances, and existing ingress rules into Terraform without creating a replacement cluster or security group. The module forces `publicly_accessible = false`, permits only listed TCP ingress sources, rejects `0.0.0.0/0` in configuration, checks the live security group for public IPv4 or IPv6 ingress at plan time, and protects the cluster and instances from Terraform destruction. Existing tags remain outside this access-only module.

Import the cluster, every listed instance, and every listed rule into the destination workspace before applying. A plan before import would attempt to create resources that already exist. Keep the map keys stable after import.

```hcl
module "db_access" {
  source = "github.com/dasmeta/terraform-aws-rds//modules/existing-aurora-private-access?ref=<commit>"

  security_group_id = "sg-existing"
  cluster = {
    identifier                           = "aurora-existing"
    engine                               = "aurora-mysql"
    engine_version                       = "8.0.mysql_aurora.3.10.3"
    database_name                        = "example"
    db_subnet_group_name                 = "default"
    db_cluster_parameter_group_name     = "default.aurora-mysql8.0"
    backup_retention_period              = 7
    preferred_backup_window              = "21:00-21:30"
    preferred_maintenance_window         = "tue:00:00-tue:00:30"
    storage_encrypted                    = false
    deletion_protection                  = false
    enable_http_endpoint                 = true
    skip_final_snapshot                  = true
    performance_insights_enabled         = true
    performance_insights_kms_key_id      = "arn:aws:kms:eu-central-1:111122223333:key/example"
    performance_insights_retention_period = 465
    iam_database_authentication_enabled = false
    copy_tags_to_snapshot                = false
    port                                 = 3306
  }
  instances = {
    writer = {
      identifier     = "aurora-existing-0"
      instance_class = "db.r6g.large"
      engine         = "aurora-mysql"
    }
  }
  ingress_rules = {
    proxy = {
      description                  = "Private proxy access"
      referenced_security_group_id = "sg-proxy"
    }
  }
}
```

With a root module named `this`, import addresses use `module.this.aws_rds_cluster.existing`, `module.this.aws_rds_cluster_instance.instances["writer"]`, and `module.this.aws_vpc_security_group_ingress_rule.rules["proxy"]`. Import IDs are the cluster identifier, DB instance identifier, and EC2 security-group rule ID (`sgr-...`) respectively. Run a full plan after imports and require zero additions, changes, and destructions before normal applies. If the hosting workspace injects default provider tags, configure its AWS provider `ignore_tags` for those generated keys during adoption; the module does not manage existing resource tags. The module also ignores two AWS forwarding attributes whose absent live values otherwise produce a provider-only false-value diff.

To retire this module without touching live resources, remove its resource addresses from state first (or use Terraform `removed` blocks with `destroy = false`) and then remove the module call. Do not apply a destroy plan against an adopted database.
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

No requirements.

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_rds_cluster_instance.instances](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_cluster_instance) | resource |
| [aws_vpc_security_group_ingress_rule.rules](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_ingress_rules"></a> [ingress\_rules](#input\_ingress\_rules) | Existing ingress rules to adopt. Each rule must use exactly one private security-group or IPv4 CIDR source. Map keys are stable Terraform import addresses. | <pre>map(object({<br/>    description                  = string           # Current rule description to preserve on import.<br/>    referenced_security_group_id = optional(string) # Existing source security group, when access comes from a VPC peer or service.<br/>    cidr_ipv4                    = optional(string) # Existing private IPv4 CIDR source, when group reference is not used.<br/>  }))</pre> | n/a | yes |
| <a name="input_instances"></a> [instances](#input\_instances) | Existing Aurora cluster instances to adopt and keep private. Map keys are stable Terraform import addresses. | <pre>map(object({<br/>    identifier         = string                    # Existing DB instance identifier to import.<br/>    cluster_identifier = string                    # Existing Aurora cluster identifier; this module does not create it.<br/>    instance_class     = string                    # Current DB instance class, retained during adoption.<br/>    engine             = string                    # Existing Aurora engine, such as aurora-mysql.<br/>    tags               = optional(map(string), {}) # Existing instance tags to preserve on import.<br/>  }))</pre> | n/a | yes |
| <a name="input_port"></a> [port](#input\_port) | Database TCP port allowed by each rule. | `number` | `3306` | no |
| <a name="input_security_group_id"></a> [security\_group\_id](#input\_security\_group\_id) | Existing Aurora security group that receives the listed ingress rules. | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_ingress_rule_ids"></a> [ingress\_rule\_ids](#output\_ingress\_rule\_ids) | Identifiers of adopted ingress rules. |
| <a name="output_instance_ids"></a> [instance\_ids](#output\_instance\_ids) | Identifiers of adopted Aurora instances. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.100.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_rds_cluster.existing](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_cluster) | resource |
| [aws_rds_cluster_instance.instances](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_cluster_instance) | resource |
| [aws_vpc_security_group_ingress_rule.rules](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_rule.existing](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc_security_group_rule) | data source |
| [aws_vpc_security_group_rules.existing](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc_security_group_rules) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_cluster"></a> [cluster](#input\_cluster) | Existing Aurora cluster to adopt without changing its current production settings. | <pre>object({<br/>    identifier                            = string                    # Existing cluster identifier used as the Terraform import ID.<br/>    engine                                = string                    # Current Aurora engine, such as aurora-mysql.<br/>    engine_version                        = string                    # Current engine version retained during adoption.<br/>    database_name                         = string                    # Existing default database name.<br/>    db_subnet_group_name                  = string                    # Existing DB subnet group name.<br/>    db_cluster_parameter_group_name       = string                    # Existing DB cluster parameter group name.<br/>    backup_retention_period               = number                    # Current number of retained backup days.<br/>    preferred_backup_window               = string                    # Current daily UTC backup window.<br/>    preferred_maintenance_window          = string                    # Current weekly UTC maintenance window.<br/>    storage_encrypted                     = bool                      # Current at-rest encryption setting; never change during adoption.<br/>    deletion_protection                   = bool                      # Current AWS deletion-protection setting; Terraform prevent_destroy remains enabled.<br/>    enable_http_endpoint                  = bool                      # Current RDS Data API endpoint setting.<br/>    skip_final_snapshot                   = bool                      # Current Terraform final-snapshot behavior, protected by prevent_destroy.<br/>    performance_insights_enabled          = bool                      # Current cluster Performance Insights setting.<br/>    performance_insights_kms_key_id       = string                    # Current Performance Insights KMS key ARN.<br/>    performance_insights_retention_period = number                    # Current Performance Insights retention period in days.<br/>    iam_database_authentication_enabled   = bool                      # Current IAM database authentication setting.<br/>    copy_tags_to_snapshot                 = bool                      # Current snapshot-tag copy setting.<br/>    port                                  = number                    # Existing database listener port.<br/>    tags                                  = optional(map(string), {}) # Existing cluster tags, retained without changing them.<br/>  })</pre> | n/a | yes |
| <a name="input_ingress_rules"></a> [ingress\_rules](#input\_ingress\_rules) | Existing ingress rules to adopt. Each rule must use exactly one private security-group or IPv4 CIDR source. Map keys are stable Terraform import addresses. | <pre>map(object({<br/>    description                  = string           # Current rule description to preserve on import.<br/>    referenced_security_group_id = optional(string) # Existing source security group, when access comes from a VPC peer or service.<br/>    cidr_ipv4                    = optional(string) # Existing private IPv4 CIDR source, when group reference is not used.<br/>  }))</pre> | n/a | yes |
| <a name="input_instances"></a> [instances](#input\_instances) | Existing Aurora cluster instances to adopt and keep private. Map keys are stable Terraform import addresses. | <pre>map(object({<br/>    identifier     = string                    # Existing DB instance identifier to import.<br/>    instance_class = string                    # Current DB instance class, retained during adoption.<br/>    engine         = string                    # Existing Aurora engine, such as aurora-mysql.<br/>    tags           = optional(map(string), {}) # Existing instance tags to preserve on import.<br/>  }))</pre> | n/a | yes |
| <a name="input_port"></a> [port](#input\_port) | Database TCP port allowed by each rule. | `number` | `3306` | no |
| <a name="input_security_group_id"></a> [security\_group\_id](#input\_security\_group\_id) | Existing Aurora security group that receives the listed ingress rules. | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | Identifier of the adopted Aurora cluster. |
| <a name="output_ingress_rule_ids"></a> [ingress\_rule\_ids](#output\_ingress\_rule\_ids) | Identifiers of adopted ingress rules. |
| <a name="output_instance_ids"></a> [instance\_ids](#output\_instance\_ids) | Identifiers of adopted Aurora instances. |
<!-- END_TF_DOCS -->
