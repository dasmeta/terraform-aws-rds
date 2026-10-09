# Implementation Plan: PR #68 review fixes

Reuse the reviewed storage-alarm implementation and 23 mocked regression cases.
The existing feature package was removed during documentation cleanup; this
package restores only reusable module requirements and excludes client evidence.
Shared standards: constitution/skills/terraform-module-developer/references/internal-module-standards.md.

Rebuild the PR on origin/main with its exact alerts.tf, locals.tf and storage tests
patch. Restore README storage defaults, serverless limits and override guidance;
add a consumer moved block with generic database/example names. Preserve the
existing RDS/Aurora wrappers, version bounds and grouped input contracts. Modern
capabilities rule is inactive; no new module ability. No breaking interface or
interface widening is introduced by this review correction.

Validate with init, validate, fmt, all native tests, rendered slow-query verification,
known-account alarm checks and diff checks. Check the example parses and its two
addresses match the pinned alerts renderer. Verify the cleaned commit range has
none of the removed feature artifacts or client details. Publish using an explicit
force-with-lease against the reviewed head, protecting concurrent contributions.
Delete the source branch only after a separately authorized merge.

Existing examples, CI, hooks and release setup remain outside the bounded review
correction. CloudBrowser read found no repository-linked documentation; generic
RDS catalog entries lack repository links. Record only verified reusable evidence.

Consumer rollout: add the moved block, require an in-place alarm update, and reject
same-name delete/create. Verify live metrics and notification delivery after apply.
Rollback requires a reviewed reverse address migration and restores the old metric.

## Validation evidence (2026-10-09)

Terraform 1.15.7: init and validate pass; all 23 mocked tests pass. Both Python
rendered-resource verifiers pass (10 slow-query plans and two pending-DB plans).
Migration HCL parses with terraform fmt; the pinned renderer keys by name-source.
Source and storage tests match the reviewed PR head byte-for-byte. Diff checks
and applicable pre-commit hooks pass. terraform-docs generates successfully; its
mutating hook is skipped because the installed version rewrites unrelated README
separator formatting. Existing upstream aws_region.name deprecation warnings
remain. Live AWS alarm transitions and metric delivery were not tested.
