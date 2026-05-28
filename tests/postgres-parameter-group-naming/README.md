# postgres-parameter-group-naming

Ensures module-created DB parameter groups use `identifier-${parameter_group_family}`.

For `engine = postgres` and `engine_version = "17"`, expect:

```text
spielerplus-wagtail-cms-test-postgres17
```

```bash
terraform init
terraform validate
# With AWS: terraform plan and confirm db_parameter_group name suffix
```
