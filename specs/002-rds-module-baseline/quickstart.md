# Quickstart: dasmeta/rds/aws

**Date**: 2026-05-20  
**Spec**: [spec.md](./spec.md) | **Contract**: [contracts/module-interface.md](./contracts/module-interface.md)

## Prerequisites

- AWS VPC with **private subnets** for `subnet_ids`
- **SNS topic** name/ARN for `alarms.sns_topic`
- Module version **>= 1.11.2** if using `aurora-postgresql` + `enable_full_monitoring`

## 1. Standalone PostgreSQL

```hcl
module "rds" {
  source  = "dasmeta/rds/aws"
  version = "1.11.2"

  identifier = "my-postgres"
  engine     = "postgres"
  engine_version = "16"

  instance_class    = "db.t4g.medium"
  allocated_storage = 100
  db_name           = "app"
  db_username       = "app"
  db_password       = var.db_password

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  alarms = {
    sns_topic = "account-alarms"
  }
}
```

**Connect**: `module.rds.db_instance_endpoint`

## 2. Aurora PostgreSQL (production-style)

```hcl
module "rds" {
  source  = "dasmeta/rds/aws"
  version = "1.11.2"

  identifier     = "my-aurora"
  engine         = "aurora-postgresql"
  engine_version = "17.7"
  instance_class = "db.r6g.large"
  allocated_storage = null

  db_name     = "db_name"
  db_username = "db_username"
  db_password = var.db_password

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  aurora_configs = {
    engine_mode = "provisioned"
    instances = {
      master = { instance_class = "db.r6g.large" }
    }
  }

  enforce_client_tls     = true
  enable_full_monitoring = true

  alarms = {
    sns_topic = "account-alarms"
  }
}
```

**Connect (writer)**: `module.rds.cluster_endpoint`  
**Connect (reader)**: `module.rds.cluster_reader_endpoint`

## 3. RDS Proxy (two-step)

**Step 1** — Create DB with `proxy.enabled = false`, apply.  
**Step 2** — Set `proxy.enabled = true`, apply again.

## 4. Validate locally

```bash
cd tests/basic-postgres   # or relevant test dir
terraform init
terraform plan
```

## 5. Run repository checks

```bash
pre-commit run --all-files
```

## Common mistakes

| Mistake | Fix |
|---------|-----|
| `engine = postgres` for Aurora | Use `aurora-postgresql` |
| Missing `instance_class` on Aurora | Set root `instance_class` |
| `enable_full_monitoring` on 1.11.1 + aurora-postgresql | Upgrade to >= 1.11.2 |
| Proxy on first apply | Disable proxy first apply |
| Using `db_instance_endpoint` for Aurora | Use `cluster_endpoint` |
