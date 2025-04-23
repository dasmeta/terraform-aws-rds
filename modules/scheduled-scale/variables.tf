variable "target" {
  type = object({
    resource_id        = string
    min_capacity       = optional(number, 1)
    max_capacity       = optional(number, 2)
    scalable_dimension = optional(string, "rds:cluster:ReadReplicaCount")
    service_namespace  = optional(string, "rds")
    create             = optional(string, false) // allows to create target if it was not been created yet
  })
  default = {
    resource_id = null
  }
  description = "App auto scaling target configs"
}

variable "policy" {
  type = object({
    name                                         = string
    policy_type                                  = string
    step_scaling_policy_configuration            = optional(any, null)
    target_tracking_scaling_policy_configuration = optional(any, null)
  })
  default     = null
  description = "App auto scaling policy configs"
}

variable "scheduled_actions" {
  type = list(object({
    name               = string                 # the name sof scheduled scale
    schedule           = string                 # the schedule time to apply auto scale, can be cron(min hour day month week-day year ), at(yyyy-mm-ddThh:mm:ss) or rate(value unit) formats
    min_capacity       = optional(number, null) # if not set defaults to target min_capacity
    max_capacity       = optional(number, null) # if not set defaults to target max_capacity
    scalable_dimension = optional(string, "rds:cluster:ReadReplicaCount")
    timezone           = optional(string, null) # by default it uses UTC, available values can be found here: https://www.joda.org/joda-time/timezones.html
  }))
  default     = []
  description = "App auto scaling configs"
}
