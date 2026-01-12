# main.tf - Root module orchestrating all infrastructure components

# Data source to get available AZs in the region
data "aws_availability_zones" "available" {
  state = "available"
}

# Networking Module - VPC, Subnets, NAT Gateways, Route Tables
module "networking" {
  source = "./modules/networking"

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 3)
  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = var.single_nat_gateway
  enable_flow_logs   = var.enable_flow_logs
  log_kms_key_arn    = aws_kms_key.cloudwatch_logs.arn
}

# Security Module - Security Groups and IAM Roles
module "security" {
  source = "./modules/security"

  project_name        = var.project_name
  environment         = var.environment
  vpc_id              = module.networking.vpc_id
  allowed_cidr_blocks = var.allowed_cidr_blocks
  container_port      = var.container_port
}

# Application Load Balancer Module
module "alb" {
  source = "./modules/alb"

  project_name          = var.project_name
  environment           = var.environment
  vpc_id                = module.networking.vpc_id
  public_subnet_ids     = module.networking.public_subnet_ids
  alb_security_group_id = module.security.alb_security_group_id
  allowed_cidr_blocks   = var.allowed_cidr_blocks
  enable_https          = var.enable_https
  ssl_certificate_arn   = var.ssl_certificate_arn
  health_check_path     = var.health_check_path
}

# ECS Module - Cluster, Task Definition, Service, Auto Scaling
module "ecs" {
  source = "./modules/ecs"

  project_name                = var.project_name
  environment                 = var.environment
  vpc_id                      = module.networking.vpc_id
  private_subnet_ids          = module.networking.private_subnet_ids
  ecs_security_group_id       = module.security.ecs_security_group_id
  ecs_task_execution_role_arn = module.security.ecs_task_execution_role_arn
  ecs_task_role_arn           = module.security.ecs_task_role_arn
  target_group_arn            = module.alb.target_group_arn
  alb_listener_rule_arn       = module.alb.ip_whitelist_rule_arn


  # Container configuration
  container_image  = var.container_image
  container_port   = var.container_port
  container_cpu    = var.container_cpu
  container_memory = var.container_memory

  # Service configuration
  desired_count = var.desired_count
  min_capacity  = var.min_capacity
  max_capacity  = var.max_capacity

  # Auto scaling configuration
  cpu_target_value    = var.cpu_target_value
  memory_target_value = var.memory_target_value

  # Logging
  log_retention_days = var.log_retention_days
  log_kms_key_arn    = aws_kms_key.cloudwatch_logs.arn
}