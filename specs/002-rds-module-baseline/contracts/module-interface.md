# Module interface contract (as-built): dasmeta/rds/aws

Derived from `variables.tf` and `output.tf`. Required inputs have no default.

## Required inputs

| Name | Type | Notes |
|------|------|-------|
| `identifier` | string | RDS instance id or Aurora cluster name |
| `subnet_ids` | list(string) | DB subnet group |
| `alarms.sns_topic` | string | SNS topic for CloudWatch alarms |

## Topology selection

| Input | Effect |
|-------|--------|
| `engine` starts with `aurora` | Aurora path (`module.db_aurora`) |
| else | Standalone RDS (`module.db`) |

## High-impact optional inputs

| Name | Default | Behavior |
|------|---------|----------|
| `engine` | `mysql` | Engine + family detection |
| `engine_version` | `5.7.26` | Upstream engine version |
| `instance_class` | `db.t3.micro` | Compute class |
| `create_security_group` | `true` | Create SG vs `vpc_security_group_ids` |
| `enforce_client_tls` | `true` | SSL parameter presets |
| `slow_queries.enabled` | `true` | Slow query logs + optional alarm |
| `enable_full_monitoring` | `false` | Full observability bundle |
| `aurora_configs` | `{}` | Aurora-only: instances, autoscaling, engine_mode |
| `proxy.enabled` | `false` | RDS Proxy submodule |
| `alarms.enabled` | `true` | Disable to skip `cw_alerts` |

## Outputs (by path)

### Standalone RDS (`module.db`)

- `db_instance_address`
- `db_instance_arn`
- `db_instance_endpoint`
- `db_instance_port`
- `db_instance_cloudwatch_log_groups`

### Aurora (`module.db_aurora`)

- `cluster_endpoint` (writer)
- `cluster_reader_endpoint`
- `cluster_instance_endpoint_suffix`

### Common

- `db_username`
- `db_password` (sensitive)

## Submodule boundaries

| Submodule | Trigger |
|-----------|---------|
| `modules/proxy` | `proxy.enabled` |
| `modules/scheduled-scale` | Aurora + autoscaling + non-empty `schedules` |
| `modules/proxysql` | Not wired in root `main.tf`; separate use |
