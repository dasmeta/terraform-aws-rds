# Research
- Decision: use Aurora FreeLocalStorage at DBClusterIdentifier with Minimum. AWS documents instance-local byte metrics and cluster dimensions; this avoids static member enumeration and averaging away low members. Confirm real cluster/member datapoints during deployment.
- Threshold: default 5 GiB, tunable through existing custom_values.disk.threshold; do not derive from Aurora allocated_storage. AWS workload guidance favors thresholds around 10–20% of local capacity, so consumers must tune.
- Alternatives: per-instance alarms require extra lifecycle handling for autoscaled readers; changing shared monitoring serialization is unsupported by current evidence and outside this repair.
- Serverless: FreeLocalStorage does not apply; omit only the unsupported storage alarm for Serverless-only clusters. Mixed clusters monitor provisioned-member local disks.
- Replacement: alert key includes metric source, so source correction replaces Aurora storage alarm, preserving all other keys.
Sources: https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.AuroraMonitoring.Metrics.html ; https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/dimensions.html ; https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Best_Practice_Recommended_Alarms_AWS_Services.html
