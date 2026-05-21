# Rollout: Aurora PostgreSQL fixes (>= 1.12.1)

## Upgrade from 1.12.0 (Keycloak / Aurora + alarms)

1. Bump YAML: `version: 1.12.1` (or latest patch).
2. Regenerate Payconomy `_terraform` workspace.
3. `terraform init -upgrade`
4. Expect **one-time** alarm migration:
   - **Destroy** ~10 alarms named `... on Instance ...`
   - **Create** ~9 alarms named `... on Cluster ...` with `DBClusterIdentifier`
5. Apply locally or via TFC (same remote state).
6. Confirm CloudWatch → Alarms → filter `prod-keycloak-aurora` → Cluster-named alarms, SNS attached.

## Terraform Cloud

After step 5 with remote state:

- Next TFC run should show **no** alarm churn if state is current.
- If TFC still plans alarm destroy/create, verify workspace uses **1.12.1** and same state backend.

## Rollback

- Revert YAML to `version: 1.12.0` and `alarms.enabled: false` if needed.
- Old Instance alarms can be recreated manually from state backup (not recommended).
