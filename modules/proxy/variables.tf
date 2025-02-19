variable "name" {
  type        = string
  description = "The name/identifier of rds proxy"
}

variable "db_cluster_identifier" {
  type        = string
  default     = ""
  description = "The rds db cluster name/identifier to use. If this value not passed then it will use proxy name as identifier"
}

variable "db_instance_identifier" {
  type        = string
  default     = ""
  description = "The rds db instance name/identifier to use"
}

variable "engine_family" {
  type        = string
  default     = "MYSQL"
  description = "The cluster engine family, valid values are `MYSQL` or `POSTGRESQL`"
}

variable "credentials_secret_arn" {
  type        = string
  default     = null
  description = "The aws secret manager secret arn which contains rds cluster username/password accesses, NOTE: if you do not set this you have to set db_username/db_password params"
}

variable "credentials_secret_recovery_window" {
  type        = number
  default     = 0
  description = "The aws secret manager secret recovery window in days. If value is 0 this means the secret will be removed immediately"
}

variable "db_username" {
  type        = string
  default     = null
  description = "Username for the master DB user. NOTE: this variable should be set only in case if you do not set cluster_master_user_secret variable"
}

variable "db_password" {
  type        = string
  sensitive   = true
  default     = null
  description = "Password for the master DB user. NOTE: this variable should be set only in case if you do not set cluster_master_user_secret variable"
}

variable "client_auth_type" {
  type        = string
  default     = "MYSQL_NATIVE_PASSWORD"
  description = "The type of authentication the proxy uses for connections from clients"
}

variable "iam_auth" {
  type        = string
  default     = "DISABLED"
  description = "Whether IAM auth enabled for proxy"
}

variable "target_db_cluster" {
  type        = bool
  default     = true
  description = "Whether target is cluster"
}

variable "endpoints" {
  type        = any
  default     = {} # for more info and available options check resource doc https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_proxy_endpoint
  description = "map of {<name>: <configs>} additional proxy endpoints(by default we have already one read/write endpoint), only name can be passed all other attributes are optional."
}

variable "subnet_ids" {
  type        = list(string)
  description = "A list of VPC subnet IDs"
}

variable "vpc_security_group_ids" {
  type        = list(string)
  description = "List of VPC security groups to associate"
  default     = []
}

variable "debug_logging" {
  type        = bool
  default     = false
  description = "Whether the enhanced logging is enabled"
}

variable "idle_client_timeout" {
  type        = number
  default     = 1800
  description = "The timeout of idle connections, default is 30 minutes"
}

variable "tags" {
  type        = any
  default     = {}
  description = "The tags to attach resources"
}
