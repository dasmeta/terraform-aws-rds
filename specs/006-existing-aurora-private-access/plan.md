# Plan: Existing Aurora private access

## Design

Create `modules/existing-aurora-private-access` as a narrow adoption module with `aws_rds_cluster.existing`, `aws_rds_cluster_instance.instances`, and `aws_vpc_security_group_ingress_rule.rules`. Inputs record the live cluster engine, network, backups, maintenance, Performance Insights, and safety settings without a master password, plus instance identity/class and exactly allowed ingress sources. The module forces private instance networking and blocks public ingress. It creates no new cluster, subnet group, security group, or proxy after import. Resource addresses are stable for import.

## Boundaries

The consumer must import all seven existing resources before apply; otherwise Terraform would attempt creation and fail or duplicate rules. Customer IDs live only in the Buycycle YAML. The consumer uses a registry version after the module release. Do not apply production changes from this PR.

## Validation

Run `terraform fmt -check`, `terraform init -backend=false`, and `terraform validate` on an isolated test root. Validate the rendered Buycycle root. A read-only local import plan against live AWS with the Buycycle profile produced seven imports, zero additions, zero changes, and zero destructions. Terraform Cloud's workspace credential remains expired, so remote validation is still blocked.

## Rollback

Before import, revert YAML/module reference. After import, preserve resources with state `removed` blocks or `terraform state rm` before removing code; never plan destruction of Aurora instances or needed ingress.
