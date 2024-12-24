## This terraform module allows to create rds cluster attached rds proxy

### basic example

```terraform
module "rds_proxy" {
    source  = "dasmeta/rds/aws//modules/proxy"
    version = "1.4.0"

    name                   = "my-test-proxy" # in this case this will be also identifier of rds cluster
    subnet_ids             = ["subnet-xxxxxxxx","subnet-xxxxxx"]
    vpc_security_group_ids = ["sg-xxxxxxxxx"]
    credentials_secret_arn = "arn-of-secret-containing-db-username-and-password"
}
```
