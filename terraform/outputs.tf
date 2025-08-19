# Output values for the Terraform configuration

# VPC Information
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

# ALB Information
output "admin_alb_arn" {
  description = "ARN of the admin ALB"
  value       = aws_lb.admin_alb.arn
}

output "admin_alb_dns_name" {
  description = "DNS name of the admin ALB"
  value       = aws_lb.admin_alb.dns_name
}

output "admin_alb_zone_id" {
  description = "Zone ID of the admin ALB"
  value       = aws_lb.admin_alb.zone_id
}

output "admin_alb_url" {
  description = "HTTPS URL of the admin ALB"
  value       = "https://${aws_lb.admin_alb.dns_name}"
}

# OpenSearch Information
output "opensearch_domain_arn" {
  description = "ARN of the OpenSearch domain"
  value       = aws_opensearch_domain.main.arn
}

output "opensearch_domain_id" {
  description = "Domain ID of the OpenSearch domain"
  value       = aws_opensearch_domain.main.domain_id
}

output "opensearch_endpoint" {
  description = "Domain-specific endpoint used to submit index, search, and data upload requests"
  value       = aws_opensearch_domain.main.endpoint
}

output "opensearch_dashboard_endpoint" {
  description = "Domain-specific endpoint for accessing OpenSearch Dashboards"
  value       = aws_opensearch_domain.main.dashboard_endpoint
}

output "opensearch_dashboard_url" {
  description = "Full URL to access OpenSearch Dashboard through ALB with authentication"
  value       = "https://${aws_lb.admin_alb.dns_name}/opensearch/"
}

# Cognito Information
output "cognito_user_pool_id" {
  description = "ID of the Cognito User Pool"
  value       = aws_cognito_user_pool.main.id
}

output "cognito_user_pool_arn" {
  description = "ARN of the Cognito User Pool"
  value       = aws_cognito_user_pool.main.arn
}

output "cognito_user_pool_client_id" {
  description = "ID of the Cognito User Pool Client"
  value       = aws_cognito_user_pool_client.main.id
  sensitive   = true
}

output "cognito_user_pool_domain" {
  description = "Domain name of the Cognito User Pool"
  value       = aws_cognito_user_pool_domain.main.domain
}

output "cognito_login_url" {
  description = "Login URL for Cognito authentication"
  value       = "https://${aws_cognito_user_pool_domain.main.domain}.auth.${data.aws_region.current.name}.amazoncognito.com/login"
}

# Security Group Information
output "admin_alb_security_group_id" {
  description = "ID of the admin ALB security group"
  value       = aws_security_group.admin_alb.id
}

output "opensearch_security_group_id" {
  description = "ID of the OpenSearch security group"
  value       = aws_security_group.opensearch.id
}

# CloudWatch Log Groups
output "opensearch_log_group_name" {
  description = "Name of the OpenSearch CloudWatch log group"
  value       = aws_cloudwatch_log_group.opensearch_logs.name
}

output "alb_log_group_name" {
  description = "Name of the ALB CloudWatch log group"
  value       = aws_cloudwatch_log_group.alb_logs.name
}

# CloudWatch Dashboard
output "cloudwatch_dashboard_name" {
  description = "Name of the CloudWatch dashboard for monitoring"
  value       = aws_cloudwatch_dashboard.opensearch_monitoring.dashboard_name
}

# S3 Bucket for ALB Logs
output "alb_logs_bucket_name" {
  description = "Name of the S3 bucket for ALB access logs"
  value       = aws_s3_bucket.alb_logs.bucket
}

output "alb_logs_bucket_arn" {
  description = "ARN of the S3 bucket for ALB access logs"
  value       = aws_s3_bucket.alb_logs.arn
}

# Environment Information
output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "project_name" {
  description = "Project name"
  value       = var.project_name
}

output "aws_region" {
  description = "AWS region"
  value       = data.aws_region.current.name
}

output "aws_account_id" {
  description = "AWS account ID"
  value       = data.aws_caller_identity.current.account_id
}