mock_provider "aws" {
  mock_data "aws_partition" {
    defaults = {
      partition  = "aws"
      dns_suffix = "amazonaws.com"
    }
  }

  mock_data "aws_region" {
    defaults = {
      name   = "eu-central-1"
      region = "eu-central-1"
    }
  }

  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "111122223333"
      arn        = "arn:aws:iam::111122223333:user/terraform-test"
      user_id    = "AIDATERRAFORMTEST"
    }
  }

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}

variables {
  name = "dasmeta-test"

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
}

run "rejects_single_subnet" {
  command = plan

  variables {
    network = {
      subnet_ids         = ["subnet-0123456789abcdef0"]
      security_group_ids = ["sg-0123456789abcdef0"]
    }
  }

  expect_failures = [var.network]
}

run "rejects_unsupported_source_engine" {
  command = plan

  variables {
    source_endpoint = {
      engine_name     = "postgres"
      database_name   = "application"
      secret_arn      = "arn:aws:secretsmanager:eu-central-1:111122223333:secret:dms-source-example"
      kms_key_arn     = "arn:aws:kms:eu-central-1:111122223333:key/00000000-0000-0000-0000-000000000001"
      certificate_arn = "arn:aws:dms:eu-central-1:111122223333:cert:SOURCECERTEXAMPLE"
    }
  }

  expect_failures = [var.source_endpoint]
}

run "rejects_system_schema" {
  command = plan

  variables {
    schema_name = "information_schema"
  }

  expect_failures = [var.schema_name]
}

run "rejects_name_too_long_for_iam_prefix" {
  command = plan

  variables {
    name = "dasmeta-name-over-twenty-two"
  }

  expect_failures = [var.name]
}
