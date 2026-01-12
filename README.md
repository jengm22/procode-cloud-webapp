###########
Overview
###########

    The platform creates a highly available ECS Fargate service running in private subnets across multiple availability zones. Traffic is routed through an internet-facing Application Load Balancer, while outbound access is controlled through NAT gateways.

    The infrastructure is fully defined using Terraform modules and supports multiple environments (e.g., dev and prod).

####################
Architecture Summary
####################

This solution implements a Three-Tier Architecture with clear separation of concerns:

    1) Presentation Tier: Application Load Balancer (Public Subnets)
    2) Application Tier: ECS Fargate Tasks (Private Subnets)
    3) Infrastructure Tier: NAT Gateways, Internet Gateway, Route Tables


################
Design Decisions
################

    - ECS Fargate was chosen to remove server management overhead and provide native scaling.
    - Public/private subnet separation enforces defense in depth and controlled access.
    - Terraform modules improve maintainability, reusability, and clarity.
    - Remote state with locking enables safe collaboration and automation.
    - GitHub Actions with OIDC demonstrates modern, secure CI/CD practices.


############
Traffic flow
############

    Internet → Application Load Balancer (public subnets) → ECS Fargate tasks (private subnets) → NAT gateways → Internet

###############
Core components
###############

    - VPC with public and private subnets across three availability zones
    - Application Load Balancer with restricted inbound access
    - ECS cluster, task definition, and Fargate service
    - Target tracking auto scaling policies (CPU and memory)
    - CloudWatch log groups and ECS Container Insights
    - IAM roles following least-privilege principles
    - A detailed breakdown is available in ARCHITECTURE.md.

########
Features
########

    - Multi-AZ, highly available architecture
    - Infrastructure as Code using Terraform modules
    - Secure networking (public/private subnet separation)
    - Least-privilege IAM roles for ECS tasks
    - Auto scaling based on CPU and memory utilization
    - Centralized logging and monitoring
    - Remote Terraform state stored in S3 with DynamoDB locking
    - Region-agnostic and environment-isolated design

#############
Prerequisites
#############

    1) Terraform >= 1.6
    2) AWS CLI configured with valid credentials
    3) An AWS account with permissions for VPC, ECS, ALB, IAM, KMS and CloudWatch

################
Getting Started
################

    1. Clone the repository
        git clone <repository-url>
    2. cd procode-cloud-webapp
    3. Run the setup script:
        chmod +x scripts/setup-backend.sh
        ./scripts/setup-backend.sh 

            This creates:
                - an encrypted S3 bucket for Terraform state
                - a DynamoDB table for state locking
                - an environment-specific backend config file
    4. Update tfvars allowed CIDR blocks for ALB access
            to get your ip address run "curl ifconfig.me" on terminal

######################
Local Deployment
######################

    Development:
        1. terraform workspace select dev || terraform workspace new dev
        2. terraform init -backend-config=envs/dev/dev.backend.hcl
        3. terraform plan -var-file=envs/dev/dev.tfvars
        4. terraform apply -var-file=envs/dev/dev.tfvars -auto-approve

    Production:
        1. terraform workspace select prod || terraform workspace new prod
        2. terraform init -backend-config=envs/prod/prod.backend.hcl
        3. terraform plan -var-file=envs/prod/prod.tfvars
        4. terraform apply -var-file=envs/prod/prod.tfvars -auto-approve

######################
Automated Deployment
######################

Automated deployment is restricted an requires access from admin

Manually triggering pipeline without anu=y code changes
    1) go to Actions
    2) on workflows select terraform-cd pipeline
    3) then run workflow

######################
How the pipeline works
######################

CI (validation on PRs)
    - terraform fmt -check
    - terraform validate
    - tflint
    - tfsec

CD (plan + apply)
    -  On Pull Requests and pushes to main, the workflow runs       terraform plan
    - On push to main, if the plan contains changes, an apply job runs only after environment approval (if enabled)

#############################
Trigger automated deployment
#############################
Deploy to dev/prod:
    1) Commit changes to Terraform code or envs/dev/dev.tfvars
    2) GitHub Actions will:
        - run terraform plan
        - run terraform apply (if changes exist), gated by environment approval 


#########################
Accessing the Application
#########################

    1. terraform output application_url or get ALB dns from AWS console
    2. Open the URL in a browser or test with:
    3. curl -I $(terraform output -raw application_url)

#####
CI/CD
#####

    GitHub Actions workflows are included to demonstrate a production-style pipeline:

        - Terraform formatting and validation
        - Static analysis with tflint and tfsec
        - Terraform plan on pull requests
        - Gated apply on the main branch
        - AWS authentication via OIDC (no long-lived secrets)
        - Environment approval required for production apply

########
Security
########

    - ECS workloads run in private subnets
    - ALB ingress restricted by CIDR allow list
    - Least-privilege IAM task and execution roles
    - Security groups scoped to minimum required access
    - Encrypted Terraform remote state
    - VPC Flow Logs enabled
    - Monitoring and Observability
    - CloudWatch Logs for all containers
    - ECS Container Insights enabled
    - ALB target group health checks
    - Auto scaling metrics for CPU and memory

#######
Testing
#######

    1. IP restriction validation:
        curl $(terraform output -raw application_url)
        Requests from non-allowed IPs should return HTTP 403.

#######
Cleanup
#######

Destroy environment: locally

    1. terraform destroy -var-file=envs/dev/dev.tfvars
    2. Remove backend resources if created:
    3. aws s3 rm s3://<bucket-name> --recursive
    4. aws s3api delete-bucket --bucket <bucket-name>
    5. aws dynamodb delete-table --table-name <lock-table-name>

####################################
Destroy infrastructure (pipeline only)
#####################################

A separate workflow is provided for safe teardown.
    1) Go to Actions → terraform-destroy
    2) Click Run workflow
    3) Select the environment (dev or prod)