variable "project_name" {
  type        = string
  description = "Project name prefix for resources."
}

variable "environment" {
  type        = string
  description = "Environment name (e.g., dev, test, prod)."
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where the ALB will be deployed."
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "Public subnet IDs for the ALB."
}

variable "alb_security_group_id" {
  type        = string
  description = "Security group ID to attach to the ALB."
}

variable "allowed_cidr_blocks" {
  type        = list(string)
  description = "CIDR blocks allowed to access the ALB."
  default     = ["0.0.0.0/0"]
}

variable "enable_https" {
  type        = bool
  description = "Whether to enable HTTPS listener."
  default     = false
}

variable "ssl_certificate_arn" {
  type        = string
  description = "ACM certificate ARN for HTTPS."
  default     = null
}

variable "health_check_path" {
  type        = string
  description = "Target group health check path."
  default     = "/"
}
