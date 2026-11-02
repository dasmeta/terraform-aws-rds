# Existing Aurora private access

Adopt existing Aurora cluster instances and existing ingress rules into Terraform without creating the cluster or security group. The module forces `publicly_accessible = false`, permits only listed TCP ingress sources, rejects `0.0.0.0/0` in configuration, checks the live security group for public IPv4 or IPv6 ingress at plan time, and protects the instances from Terraform destruction. Existing tags remain outside this access-only module.

Import **every** listed instance and rule into the destination workspace before applying. A plan before import would attempt to create resources that already exist. Keep the map keys stable after import.

```hcl
module "db_access" {
  source = "github.com/dasmeta/terraform-aws-rds//modules/existing-aurora-private-access?ref=<commit>"

  security_group_id = "sg-existing"
  instances = {
    writer = {
      identifier         = "aurora-existing-0"
      cluster_identifier = "aurora-existing"
      instance_class      = "db.r6g.large"
      engine              = "aurora-mysql"
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

With a root module named `this`, import addresses use `module.this.aws_rds_cluster_instance.instances["writer"]` and `module.this.aws_vpc_security_group_ingress_rule.rules["proxy"]`. Import IDs are the DB instance identifier and EC2 security-group rule ID (`sgr-...`) respectively. Run a full plan after imports and require zero additions, changes, and destructions before normal applies.

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
