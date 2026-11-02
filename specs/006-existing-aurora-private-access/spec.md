# Existing Aurora private access

## Goal

Allow an existing Aurora cluster, its instances, and existing MySQL ingress rules to be adopted into Terraform without creating or replacing the cluster. The first consumer is Buycycle production DS-13913.

## Requirements

- Manage the `publicly_accessible = false` setting of each listed existing Aurora instance.
- Manage the existing cluster with its live engine, backup, maintenance, networking, Performance Insights, and deletion settings preserved; do not read or write its master password.
- Manage only explicitly listed ingress rules on an existing security group; never create the group or infer additional rules.
- Reject world-open IPv4 MySQL ingress in this private-access module.
- Fail planning when the existing target security group has a public IPv4 or IPv6 ingress rule, including one added outside Terraform.
- Protect the adopted cluster and instances from accidental Terraform destruction.
- Expose stable resource addresses for one-time imports of the cluster, each instance, and each security-group rule.
- Keep the module reusable without customer-specific IDs, secrets, or hostnames.

## Acceptance

- A clean `terraform init` and `terraform validate` pass for the module consumer.
- Tests demonstrate two instances, group and CIDR ingress, and rejection of a world-open source.
- Buycycle YAML renders the module call and a local live import plan has seven imports with no adds, changes, or destroys before merge.
