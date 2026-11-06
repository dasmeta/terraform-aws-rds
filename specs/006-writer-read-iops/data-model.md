# Data Model

The ReadIOPS alarm has a metric namespace, name, dimension map, statistic, period, threshold, and destination. Aurora writer alarms add `Role=WRITER` to their existing cluster identifier dimension. Non-Aurora alarms retain their instance identifier dimension.
