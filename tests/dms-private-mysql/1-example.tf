module "this" {
  source = "../../modules/dms"

  name = "dasmeta-live-migration"

  network = {
    subnet_ids         = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]
    security_group_ids = ["sg-0123456789abcdef0"]
  }

  source_endpoint = {
    engine_name     = "aurora"
    database_name   = "application"
    secret_arn      = "arn:aws:secretsmanager:eu-central-1:111122223333:secret:dms-source-example"
    kms_key_arn     = "arn:aws:kms:eu-central-1:111122223333:key/00000000-0000-0000-0000-000000000001"
    certificate_arn = "arn:aws:dms:eu-central-1:111122223333:cert:SOURCECERTEXAMPLE"
  }

  target_endpoint = {
    engine_name     = "aurora"
    database_name   = "application"
    secret_arn      = "arn:aws:secretsmanager:eu-central-1:111122223333:secret:dms-target-example"
    kms_key_arn     = "arn:aws:kms:eu-central-1:111122223333:key/00000000-0000-0000-0000-000000000002"
    certificate_arn = "arn:aws:dms:eu-central-1:111122223333:cert:TARGETCERTEXAMPLE"
  }

  schema_name = "application"

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
