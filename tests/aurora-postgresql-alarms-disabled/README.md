# aurora-postgresql-alarms-disabled

Regression test for Aurora PostgreSQL clusters where `alarms.enabled = false`.

Ensures the module does not create `data.aws_db_instance.database` (cluster `identifier` is not a DB instance id) and plan/apply does not fail with `couldn't find resource` for the cluster identifier.

```bash
terraform init
terraform validate
```
