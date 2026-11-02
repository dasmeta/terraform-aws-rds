variable "cluster" {
  description = "Existing Aurora cluster to adopt without changing its current production settings."
  type = object({
    identifier                            = string                    # Existing cluster identifier used as the Terraform import ID.
    engine                                = string                    # Current Aurora engine, such as aurora-mysql.
    engine_version                        = string                    # Current engine version retained during adoption.
    database_name                         = string                    # Existing default database name.
    db_subnet_group_name                  = string                    # Existing DB subnet group name.
    db_cluster_parameter_group_name       = string                    # Existing DB cluster parameter group name.
    backup_retention_period               = number                    # Current number of retained backup days.
    preferred_backup_window               = string                    # Current daily UTC backup window.
    preferred_maintenance_window          = string                    # Current weekly UTC maintenance window.
    storage_encrypted                     = bool                      # Current at-rest encryption setting; never change during adoption.
    deletion_protection                   = bool                      # Current AWS deletion-protection setting; Terraform prevent_destroy remains enabled.
    enable_http_endpoint                  = bool                      # Current RDS Data API endpoint setting.
    skip_final_snapshot                   = bool                      # Current Terraform final-snapshot behavior, protected by prevent_destroy.
    performance_insights_enabled          = bool                      # Current cluster Performance Insights setting.
    performance_insights_kms_key_id       = string                    # Current Performance Insights KMS key ARN.
    performance_insights_retention_period = number                    # Current Performance Insights retention period in days.
    iam_database_authentication_enabled   = bool                      # Current IAM database authentication setting.
    copy_tags_to_snapshot                 = bool                      # Current snapshot-tag copy setting.
    port                                  = number                    # Existing database listener port.
    tags                                  = optional(map(string), {}) # Existing cluster tags, retained without changing them.
  })
}

variable "instances" {
  description = "Existing Aurora cluster instances to adopt and keep private. Map keys are stable Terraform import addresses."
  type = map(object({
    identifier     = string                    # Existing DB instance identifier to import.
    instance_class = string                    # Current DB instance class, retained during adoption.
    engine         = string                    # Existing Aurora engine, such as aurora-mysql.
    tags           = optional(map(string), {}) # Existing instance tags to preserve on import.
  }))
}

variable "security_group_id" {
  description = "Existing Aurora security group that receives the listed ingress rules."
  type        = string
}

variable "port" {
  description = "Database TCP port allowed by each rule."
  type        = number
  default     = 3306

  validation {
    condition     = var.port > 0 && var.port <= 65535
    error_message = "port must be a valid TCP port."
  }
}

variable "ingress_rules" {
  description = "Existing ingress rules to adopt. Each rule must use exactly one private security-group or IPv4 CIDR source. Map keys are stable Terraform import addresses."
  type = map(object({
    description                  = string           # Current rule description to preserve on import.
    referenced_security_group_id = optional(string) # Existing source security group, when access comes from a VPC peer or service.
    cidr_ipv4                    = optional(string) # Existing private IPv4 CIDR source, when group reference is not used.
  }))

  validation {
    condition = alltrue([
      for rule in values(var.ingress_rules) :
      (rule.referenced_security_group_id != null ? 1 : 0) + (rule.cidr_ipv4 != null ? 1 : 0) == 1
    ])
    error_message = "Each ingress rule must set exactly one source: referenced_security_group_id or cidr_ipv4."
  }

  validation {
    condition = alltrue([
      for rule in values(var.ingress_rules) : rule.cidr_ipv4 != "0.0.0.0/0"
    ])
    error_message = "World-open IPv4 ingress is not allowed for private Aurora access."
  }
}
