# Verification

1. Run `terraform fmt -check alerts.tf`.
2. Verify the Aurora ReadIOPS dimension includes `DBClusterIdentifier` and `Role=WRITER`; verify the non-Aurora dimension remains `DBInstanceIdentifier`.
3. In a credentialed production session, compare November 5 `ReadIOPS` for `Role=WRITER` and `Role=READER` with the 20,000 threshold and inspect the Terraform plan before apply.
