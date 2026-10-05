# Verification and rollout

From repository root:

```sh
terraform init -backend=false
terraform validate
terraform test -filter=tests/slow-query-count.tftest.hcl
python3 tests/verify-slow-query-filters.py --profile <read-only-profile> --region eu-central-1
```

Tests create no infrastructure. Native tests use mocks; filter fixtures use read-only AWS test-metric-filter. Review README upgrade/moved-block guidance before changing a consumer module pin. Production apply and release publishing are separate actions.
