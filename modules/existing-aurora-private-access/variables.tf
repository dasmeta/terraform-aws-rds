variable "instances" {
  description = "Existing Aurora cluster instances to adopt and keep private. Map keys are stable Terraform import addresses."
  type = map(object({
    identifier         = string                    # Existing DB instance identifier to import.
    cluster_identifier = string                    # Existing Aurora cluster identifier; this module does not create it.
    instance_class     = string                    # Current DB instance class, retained during adoption.
    engine             = string                    # Existing Aurora engine, such as aurora-mysql.
    tags               = optional(map(string), {}) # Existing instance tags to preserve on import.
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
