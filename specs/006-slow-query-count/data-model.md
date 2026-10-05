# Monitoring definitions

- Duration metric: existing RDSSlowQueries, duration units, existing filter/name/state keys retained.
- Count metric: RDSSlowQueryCount, Count unit, value1/default0, one matching event per statement; query log group only.
- Effective alarm: existing name/actions; count source, Sum, default5/300s/gte; user overrides retain priority.
- Consumer migration: old nested alarm module name-source key -> new count source key, with moved block before production plan.
