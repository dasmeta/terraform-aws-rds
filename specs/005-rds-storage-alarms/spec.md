# Feature Specification: Correct RDS storage alarm defaults

Repository: dasmeta/terraform-aws-rds. Existing feature continuation for PR #68.

Provisioned Aurora uses FreeLocalStorage with DBClusterIdentifier, Minimum over
300 seconds and a 5 GiB baseline. Standalone RDS retains FreeStorageSpace,
DBInstanceIdentifier, Average and 8% of current allocated storage. Disk overrides
retain precedence. Serverless-only clusters omit unsupported local-storage alarms;
mixed clusters monitor provisioned members.

Review requirements: retain no client-specific evidence in the PR commits; restore
storage documentation and alarm dimensions; document a consumer moved block so
existing Aurora alarms update in place. No database, provider or interface changes.
No production apply, release or merge is included in this request.
