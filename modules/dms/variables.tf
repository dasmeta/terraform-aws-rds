variable "name" {
  description = "Stable identifier used for the DMS migration resources."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,21}$", var.name))
    error_message = "name must contain 3-22 lowercase letters, numbers, or hyphens and start with a letter so generated IAM role prefixes remain valid."
  }
}

variable "network" {
  description = "Private subnet and existing security group placement for the DMS replication instance."
  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
  })

  validation {
    condition     = length(distinct(var.network.subnet_ids)) >= 2
    error_message = "network.subnet_ids must contain at least two distinct private subnet IDs."
  }

  validation {
    condition     = length(var.network.security_group_ids) > 0
    error_message = "network.security_group_ids must contain at least one security group ID."
  }
}

variable "source_endpoint" {
  description = "Secret-backed MySQL-compatible source endpoint using a registered DMS certificate."
  type = object({
    engine_name                 = string
    database_name               = string
    secret_arn                  = string
    kms_key_arn                 = string
    certificate_arn             = string
    extra_connection_attributes = optional(string)
  })

  validation {
    condition     = contains(["mysql", "aurora"], var.source_endpoint.engine_name)
    error_message = "source_endpoint.engine_name must be mysql or aurora."
  }

  validation {
    condition = alltrue([
      startswith(var.source_endpoint.secret_arn, "arn:"),
      startswith(var.source_endpoint.kms_key_arn, "arn:"),
      startswith(var.source_endpoint.certificate_arn, "arn:")
    ])
    error_message = "source_endpoint secret_arn, kms_key_arn, and certificate_arn must be nonempty ARNs."
  }
}

variable "target_endpoint" {
  description = "Secret-backed MySQL-compatible target endpoint using a registered DMS certificate."
  type = object({
    engine_name                 = string
    database_name               = string
    secret_arn                  = string
    kms_key_arn                 = string
    certificate_arn             = string
    extra_connection_attributes = optional(string)
  })

  validation {
    condition     = contains(["mysql", "aurora"], var.target_endpoint.engine_name)
    error_message = "target_endpoint.engine_name must be mysql or aurora."
  }

  validation {
    condition = alltrue([
      startswith(var.target_endpoint.secret_arn, "arn:"),
      startswith(var.target_endpoint.kms_key_arn, "arn:"),
      startswith(var.target_endpoint.certificate_arn, "arn:")
    ])
    error_message = "target_endpoint secret_arn, kms_key_arn, and certificate_arn must be nonempty ARNs."
  }
}

variable "schema_name" {
  description = "Explicit application schema whose tables are included in the migration."
  type        = string

  validation {
    condition = (
      trimspace(var.schema_name) != "" &&
      !contains(["mysql", "information_schema", "performance_schema", "sys"], lower(var.schema_name)) &&
      !strcontains(var.schema_name, "%")
    )
    error_message = "schema_name must be one explicit non-system schema and cannot contain wildcards."
  }
}

variable "instance_class" {
  description = "DMS replication instance class."
  type        = string
  default     = "dms.r6i.large"
}

variable "engine_version" {
  description = "DMS replication engine version."
  type        = string
  default     = "3.6.1"
}

variable "allocated_storage" {
  description = "DMS replication instance storage in GiB."
  type        = number
  default     = 100

  validation {
    condition     = var.allocated_storage >= 5 && var.allocated_storage <= 6144
    error_message = "allocated_storage must be between 5 and 6144 GiB."
  }
}

variable "multi_az" {
  description = "Whether the provisioned DMS replication instance is Multi-AZ."
  type        = bool
  default     = false
}

variable "maintenance_window" {
  description = "Optional weekly DMS maintenance window in UTC."
  type        = string
  default     = null
}

variable "max_full_load_subtasks" {
  description = "Maximum number of tables loaded concurrently."
  type        = number
  default     = 8

  validation {
    condition     = var.max_full_load_subtasks >= 1 && var.max_full_load_subtasks <= 49
    error_message = "max_full_load_subtasks must be between 1 and 49."
  }
}

variable "transaction_consistency_timeout" {
  description = "Seconds DMS waits for open transactions before beginning full load."
  type        = number
  default     = 600

  validation {
    condition     = var.transaction_consistency_timeout > 0
    error_message = "transaction_consistency_timeout must be positive."
  }
}

variable "commit_rate" {
  description = "Maximum records transferred together during full load."
  type        = number
  default     = 10000

  validation {
    condition     = var.commit_rate > 0
    error_message = "commit_rate must be positive."
  }
}

variable "tags" {
  description = "Tags applied to all supported resources."
  type        = map(string)
  default     = {}
}
