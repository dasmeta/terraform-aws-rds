# Data model: dasmeta/rds/aws (logical configuration)

**Date**: 2026-05-20  
**Spec**: [spec.md](./spec.md)

## Topology selection

```text
engine (string)
    │
    ├─ startswith "aurora" ──► Aurora path (module.db_aurora)
    │       ├─ aurora_configs.engine_mode
    │       ├─ aurora_configs.instances{ key → instance_class, ... }
    │       └─ aurora_configs.autoscaling{ enabled, min/max, schedules[] }
    │
    └─ else ──► Standalone RDS (module.db)
            ├─ multi_az
            ├─ allocated_storage / max_allocated_storage
            └─ instance_class
```

## Engine family derivation

```text
engine
    │
    ├─ contains "postgres" ──► POSTGRESQL (port 5432)
    │       └─ prepared_configs.POSTGRESQL + common
    │
    └─ mysql family ──► MYSQL (port 3306)
            └─ prepared_configs.MYSQL + common
```

## Configuration bundles (locals)

| Bundle | Trigger | Effects |
|--------|---------|---------|
| Slow queries | `slow_queries.enabled` (default true) | Params + log exports + metric filters |
| TLS | `enforce_client_tls` (default true) | SSL params (instance/cluster merge) |
| Full monitoring | `enable_full_monitoring` | PI, insights, monitoring role, logs, merges slow_queries on |

## Parameter merge order (instance)

1. `slow_query_params_map`  
2. `enable_full_monitoring_params_map`  
3. `user_instance_params_map` (wins on key collision)

## Parameter merge order (cluster)

1. `slow_query_params_map`  
2. `enforce_client_tls_params_map`  
3. `enable_full_monitoring_params_map`  
4. `user_cluster_params_map`

## Optional submodules

| Submodule | Condition | Target |
|-----------|-----------|--------|
| `security_group` | `create_security_group` | VPC rules + auto VPC CIDR ingress |
| `cw_alerts` | `alarms.enabled` | SNS + RDS CloudWatch alarms |
| `cloudwatch_metric_filters` | `slow_queries.enabled` × log exports | Log-based slow query metrics |
| `scheduled_scale` | Aurora + autoscaling + schedules | App autoscaling scheduled actions |
| `proxy` | `proxy.enabled` | RDS Proxy → cluster or instance |

## Outputs by topology

| Topology | Primary connection outputs |
|----------|---------------------------|
| Standalone | `db_instance_endpoint`, `db_instance_address`, `db_instance_port` |
| Aurora | `cluster_endpoint`, `cluster_reader_endpoint`, `cluster_instance_endpoint_suffix` |
| Both | `db_username`, `db_password` (sensitive) |

## External dependencies (data sources)

- `aws_vpc.this` — when creating security group (CIDR for auto ingress)
- `aws_ec2_instance_type.this` — alarm threshold sizing (memory)
- `aws_db_instance.database` — alarm storage threshold (when alarms enabled)
