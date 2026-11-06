# Research

AWS Aurora CloudWatch dimensions support `DBClusterIdentifier, Role` with `WRITER` and `READER` values: https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/dimensions.html

The current module's Aurora alarm uses `DBClusterIdentifier` only. The production caller overrides the read threshold to 20,000 IOPS and pins module revision `2281e811eee615ce7b1a25d8e33ac6d8bf8efbb1`.

Historical November 5 metrics could not be queried because the local AWS credential returns `InvalidClientTokenId`. This remains a deployment validation gate.
