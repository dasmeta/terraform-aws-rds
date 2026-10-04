# Storage alarm contract
No new input. Existing alarms.enabled/sns_topic/custom_values.disk threshold, period, equation and statistic semantics remain.
Provisioned Aurora: FreeLocalStorage, cluster identifier, Minimum, <=5 GiB, 300 seconds.
Standalone: FreeStorageSpace, instance identifier, Average, <=8% allocated storage, 300 seconds.
Custom disk fields override defaults. Serverless-only clusters omit storage alarm; all alarms disabled means zero cw_alerts instances.
