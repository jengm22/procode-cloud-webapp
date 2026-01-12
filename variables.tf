
variable "project_name" {
  description = "Project name prefix used for all resources."
  type        = string
}

variable "owner" {
  description = "Owner tag for resources (team/person)."
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g. dev, test, prod)."
  type        = string
}

variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "enable_nat_gateway" {
  description = "Whether to provision NAT Gateways for private subnets."
  type        = bool
}

variable "single_nat_gateway" {
  description = "Whether to use a single shared NAT Gateway."
  type        = bool
}

variable "enable_flow_logs" {
  description = "Enable VPC flow logs."
  type        = bool
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the ALB."
  type        = list(string)
}

variable "enable_https" {
  description = "Enable HTTPS listener on the ALB."
  type        = bool
}

variable "ssl_certificate_arn" {
  description = "ACM certificate ARN for HTTPS listener (required if enable_https = true)."
  type        = string
  default     = null
}

variable "health_check_path" {
  description = "ALB target group health check path."
  type        = string
  default     = "/"
}

variable "container_image" {
  description = "Container image to deploy."
  type        = string
}

variable "container_port" {
  description = "Port the container listens on."
  type        = number
}

variable "container_cpu" {
  description = "CPU units for the ECS task."
  type        = number
}

variable "container_memory" {
  description = "Memory (MiB) for the ECS task."
  type        = number
}

variable "desired_count" {
  description = "Desired number of ECS tasks."
  type        = number
}

variable "min_capacity" {
  description = "Minimum number of ECS tasks."
  type        = number
}

variable "max_capacity" {
  description = "Maximum number of ECS tasks."
  type        = number
}

variable "cpu_target_value" {
  description = "Target CPU utilization percentage for auto scaling."
  type        = number
}

variable "memory_target_value" {
  description = "Target memory utilization percentage for auto scaling."
  type        = number
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs."
  type        = number
}
