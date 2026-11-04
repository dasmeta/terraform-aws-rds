# Quickstart: Private MySQL-to-Aurora MySQL DMS Infrastructure

This example creates infrastructure only. Terraform leaves the replication task stopped.

```hcl
module "database_migration" {
  source = "dasmeta/rds/aws//modules/dms"

  name = "dasmeta-live-migration"

  network = {
    subnet_ids        = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]
    security_group_ids = ["sg-0123456789abcdef0"]
  }

  source_endpoint = {
    engine_name     = "aurora"
    database_name   = "application"
    secret_arn      = "arn:aws:secretsmanager:eu-central-1:111122223333:secret:dms-source-example"
    kms_key_arn     = "arn:aws:kms:eu-central-1:111122223333:key/00000000-0000-0000-0000-000000000001"
    certificate_arn = "arn:aws:dms:eu-central-1:111122223333:cert:SOURCECERTEXAMPLE"
  }

  target_endpoint = {
    engine_name     = "aurora"
    database_name   = "application"
    secret_arn      = "arn:aws:secretsmanager:eu-central-1:111122223333:secret:dms-target-example"
    kms_key_arn     = "arn:aws:kms:eu-central-1:111122223333:key/00000000-0000-0000-0000-000000000002"
    certificate_arn = "arn:aws:dms:eu-central-1:111122223333:cert:TARGETCERTEXAMPLE"
  }

  schema_name = "application"

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

## Before apply

- Enable and retain MySQL/Aurora MySQL binary logs long enough for the initial load and CDC catch-up.
- Create a least-privilege DMS source user with replication access and a target user with required DDL/DML permissions.
- Pre-create the target database/schema and compatible objects; perform schema conversion separately.
- Disable target triggers and scheduled events for the migration period.
- Store `username`, `password`, `serverName`, and `port` in each supplied Secrets Manager secret and register the trusted CA certificates with DMS. AWS DMS forbids setting endpoint hostname/port alongside `secrets_manager_arn`.
- Confirm private DNS, routes, NACLs, and security groups allow DMS to reach both endpoints and Secrets Manager/KMS.
- Confirm a recent restorable snapshot and an approved rollback procedure exist.

## After apply and before start

1. Confirm the task is stopped.
2. Run DMS connection tests for both endpoints.
3. Run the DMS premigration assessment and resolve all blockers.
4. Confirm CloudWatch logging and data validation settings.
5. Record the source binary-log position and operational baseline.
6. Start the task explicitly through the approved operational process—not Terraform.

Cutover is allowed only after full load completes, validation is clean, CDC latency is within the agreed threshold, and the maintenance-window owner approves the write pause.
