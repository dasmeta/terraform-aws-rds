# aurora-postgresql-alarms-enabled

Aurora PostgreSQL with `alarms.enabled = true`. Disk alarm threshold uses `allocated_storage` (or default), not `data.aws_db_instance`.

```bash
terraform init
terraform validate
```
