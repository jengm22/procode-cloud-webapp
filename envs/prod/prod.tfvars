# terraform.tfvars.example
# Copy this file to terraform.tfvars and customize the values

# General Configuration
project_name = "procode-webapp"
environment  = "prod"
aws_region   = "eu-west-2"
owner        = "Cloud Team"

# Networking Configuration
vpc_cidr           = "10.10.0.0/16"
enable_nat_gateway = true
single_nat_gateway = false # Set to true for cost optimization (not recommended for prod)
enable_flow_logs   = true

# Security Configuration - IMPORTANT: Replace with your IP address
# Get your IP: curl ifconfig.me
allowed_cidr_blocks = [
  "0.0.0.0/0" # Replace with your IP address, e.g., "203.0.113.1/32"
]

# Load Balancer Configuration
enable_https        = false # Set to true if you have an SSL certificate
ssl_certificate_arn = ""    # ARN of your SSL certificate if enable_https is true
health_check_path   = "/"

# Container Configuration
container_image  = "nginx:latest" # Can use: nginx:alpine, httpbin/httpbin, etc.
container_port   = 80
container_cpu    = 256 # 256 = 0.25 vCPU
container_memory = 512 # 512 MB

# ECS Service Configuration
desired_count = 3  # Number of tasks to run
min_capacity  = 2  # Minimum tasks for auto-scaling
max_capacity  = 10 # Maximum tasks for auto-scaling

# Auto Scaling Configuration
cpu_target_value    = 70 # Scale when CPU > 70%
memory_target_value = 80 # Scale when Memory > 80%

# Logging Configuration
log_retention_days = 30 # CloudWatch log retention