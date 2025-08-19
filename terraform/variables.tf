# Variable definitions for the Terraform configuration

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "piyush-demo"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "opensearch_instance_type" {
  description = "Instance type for OpenSearch domain"
  type        = string
  default     = "t3.small.search"
}

variable "opensearch_instance_count" {
  description = "Number of instances in OpenSearch domain"
  type        = number
  default     = 2
}

variable "opensearch_volume_size" {
  description = "Size of EBS volume for each OpenSearch instance (in GB)"
  type        = number
  default     = 20
}

variable "certificate_domain" {
  description = "Domain name for SSL certificate"
  type        = string
  default     = "*.example.com"
}

variable "dashboard_path" {
  description = "Path for OpenSearch dashboard routing"
  type        = string
  default     = "/opensearch/*"
}

# Common tags for all resources
variable "common_tags" {
  description = "Common tags to be applied to all resources"
  type        = map(string)
  default = {
    Project     = "piyush-demo"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}