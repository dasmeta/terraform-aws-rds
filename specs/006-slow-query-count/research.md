# Research

## Decision: preserve duration telemetry; add count metric
The existing duration metric emits $duration and defaults to zero; SampleCount counts defaults. Add RDSSlowQueryCount with value 1/default 0, use Sum. Changing only the statistic would sum duration. The module's locals comment documents five real queries plus two samples as the old PostgreSQL threshold7 rationale.
Sources: [AWS count example](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/CountOccurrencesExample.html), log-based-metrics.tf, alerts.tf, locals.tf.

## Decision: engine-aware count filters
PostgreSQL filter matches statement/execute with numeric millisecond threshold; existing statement-only duration filter is retained. MySQL/MariaDB need a Query_time header regex that matches separate events and full multiline records despite different optional header lines. Shared space-delimited suffix matching cannot search arbitrary middle tokens. An independent research agent verified header regex and its limits using AWS test-metric-filter.
Sources: [PostgreSQL logging](https://www.postgresql.org/docs/17/runtime-config-logging.html), [MySQL slow logs](https://dev.mysql.com/doc/refman/8.0/en/slow-query-log.html), [MariaDB slow logs](https://mariadb.com/docs/server/server-management/server-monitoring-logs/slow-query-log/slow-query-log-overview), [AWS filter syntax](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/FilterAndPatternSyntax.html).

## Decision: preserve consumer customization and require state migration
Existing period/threshold/equation/statistic overrides remain explicit choices. A custom count statistic retains SampleCount behavior and must be migrated to sum if desired. The monitoring renderer keys nested modules by name-source; adding Count to source changes state address. Consumer moved block avoids create/delete racing against unchanged CloudWatch alarm name.

## Alternatives rejected
Removing all default zeros breaks continuous zero reporting. Reusing the duration metric name for count corrupts existing dashboards/units. Globally modifying monitoring defaults affects unrelated modules. Numeric duration filtering in multiline MySQL/MariaDB requires fragile fixed header layouts; rely on long_query_time and document extra logging modes/session overrides. Adding a new public migration toggle broadens interface without need.

## CloudBrowser comparison
No matching Module returned by scm_url query. Existing Documentation matches were unrelated service evidence; no release/version record or accepted shared implementation documentation exists for this change. No CB catalog version or deployment claim will be created before release/adoption.
