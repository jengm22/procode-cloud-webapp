########################
# Required identifiers
########################

variable "project_name" {
  description = "Project name prefix for resource naming."
  type        = string
}

variable "environment" {
  description = "Environment name (e.g. dev, test, prod)."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for ECS networking resources."
  type        = string
}

########################
# Networking + Security
########################

variable "private_subnet_ids" {
  description = "Private subnet IDs where ECS tasks will run."
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "Security group ID attached to ECS tasks."
  type        = string
}

########################
# IAM roles
########################

variable "ecs_task_execution_role_arn" {
  description = "IAM role ARN for ECS task execution (pull image, write logs)."
  type        = string
}

variable "ecs_task_role_arn" {
  description = "IAM role ARN for the running task (app permissions)."
  type        = string
}

########################
# Load balancing
########################

variable "target_group_arn" {
  description = "ALB Target Group ARN the ECS service should register with."
  type        = string
}

########################
# Container configuration
########################

variable "container_image" {
  description = "Container image to deploy."
  type        = string
}

variable "container_port" {
  description = "Container port."
  type        = number
}

variable "container_cpu" {
  description = "CPU units for the Fargate task."
  type        = number
}

variable "container_memory" {
  description = "Memory (MiB) for the Fargate task."
  type        = number
}

########################
# Service configuration
########################

variable "desired_count" {
  description = "Desired number of running tasks."
  type        = number
  default     = 1
}

variable "min_capacity" {
  description = "Minimum tasks for autoscaling."
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum tasks for autoscaling."
  type        = number
  default     = 3
}

########################
# Auto scaling targets
########################

variable "cpu_target_value" {
  description = "Target CPU utilization percentage for autoscaling."
  type        = number
  default     = 60
}

variable "memory_target_value" {
  description = "Target Memory utilization percentage for autoscaling."
  type        = number
  default     = 70
}

########################
# Logging
########################

variable "log_retention_days" {
  description = "CloudWatch log retention in days."
  type        = number
  default     = 14
}

variable "log_kms_key_arn" {
  type        = string
  description = "KMS key ARN for encrypting CloudWatch log groups"
}

variable "alb_listener_rule_arn" {
  type        = string
  description = "Listener rule ARN to ensure target group is associated before ECS service create."
}
