# Plan: Existing Aurora private access

## Design

Create `modules/existing-aurora-private-access` as a narrow module with two resource maps: `aws_rds_cluster_instance.instances` and `aws_vpc_security_group_ingress_rule.rules`. Inputs describe existing instance identity/class/engine/tags, existing DB security group, port, and exactly the allowed rule sources. The module forces private instance networking and blocks `0.0.0.0/0` IPv4 ingress. It creates no cluster, subnet group, security group, or proxy. Resource addresses are stable map keys for import.

## Boundaries

The consumer must import the existing resources before apply; otherwise Terraform would attempt creation and fail or duplicate rules. Customer IDs live only in the Buycycle YAML. Pin the module by immutable Git commit until a registry release is available. Do not apply production changes from this PR.

## Validation

Run `terraform fmt -check`, `terraform init -backend=false`, and `terraform validate` on an isolated test root. Validate the rendered Buycycle root and review an import plan when AWS credentials are restored. Terraform Cloud currently has expired AWS credentials, so a remote plan may remain blocked.

## Rollback

Before import, revert YAML/module reference. After import, preserve resources with state `removed` blocks or `terraform state rm` before removing code; never plan destruction of Aurora instances or needed ingress.
