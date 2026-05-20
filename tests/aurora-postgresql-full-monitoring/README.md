# aurora-postgresql-full-monitoring

Validates `engine = aurora-postgresql` with `enable_full_monitoring = true` plans without an empty `engine_family` error.

Requires module version **>= 1.11.2** (see root `README.md` NOTEs).

## Validate locally

```bash
cd tests/aurora-postgresql-full-monitoring
terraform init
terraform plan
```

Expect plan to succeed (no `Invalid index` on `local.prepared_configs[local.engine_family]`). Apply is optional and creates billable Aurora resources.
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_this"></a> [this](#module\_this) | ../.. | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_subnets.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets) | data source |
| [aws_vpc.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Inputs

No inputs.

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
