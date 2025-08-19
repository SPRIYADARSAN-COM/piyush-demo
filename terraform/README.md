# OpenSearch Dashboard ALB Integration - Terraform Configuration

This Terraform configuration creates an AWS infrastructure to expose a VPC-based OpenSearch dashboard endpoint through an Application Load Balancer (ALB) with Cognito authentication.

## Overview

The solution implements the following components:

### Core Infrastructure
- **VPC**: Private network with public and private subnets across multiple availability zones
- **Application Load Balancer (ALB)**: Admin ALB to handle incoming traffic with SSL termination
- **Security Groups**: Properly configured to allow secure communication between ALB and OpenSearch
- **NAT Gateways**: For outbound internet access from private subnets

### OpenSearch Configuration
- **VPC-based OpenSearch Domain**: Deployed in private subnets for security
- **Target Group**: Configured for OpenSearch dashboard with health checks
- **Listener Rules**: Path-based routing with Cognito authentication
- **Logging**: CloudWatch integration for monitoring and troubleshooting

### Authentication & Security
- **Cognito User Pool**: For user authentication and authorization
- **SSL/TLS**: End-to-end encryption using ACM certificates
- **Access Policies**: Restrict access to authenticated users only

## Architecture

```
Internet -> ALB (HTTPS) -> Cognito Auth -> Target Group -> OpenSearch Dashboard (VPC)
```

### Access Patterns

1. **Dashboard Access**: `https://<alb-dns>/opensearch/_dashboards/`
   - Requires Cognito authentication
   - Path-based routing: `/opensearch/*`, `/_dashboards*`, `/_plugins*`
   - Session management with sticky sessions

2. **API Access**: `https://<alb-dns>/_search`, `/_cat`, etc.
   - Programmatic access for applications
   - Header-based authentication
   - Direct API endpoints

## File Structure

```
terraform/
├── main.tf                    # Provider configuration and data sources
├── variables.tf               # Variable definitions
├── outputs.tf                 # Output values
├── vpc.tf                     # VPC, subnets, routing
├── security-groups.tf         # Security group configurations
├── alb.tf                     # Application Load Balancer setup
├── cognito.tf                 # Cognito User Pool and authentication
├── user-audit.tf              # OpenSearch domain configuration
├── opensearch-dashboard.tf    # OpenSearch ALB integration
└── README.md                  # This documentation
```

## Key Features

### 1. Reuse Existing Admin ALB
- The configuration creates an admin ALB that can be reused for multiple services
- HTTPS listener with proper SSL configuration
- HTTP to HTTPS redirection

### 2. OpenSearch Target Group
- Dedicated target group for OpenSearch domain endpoints
- Health checks configured for OpenSearch dashboard
- Sticky sessions for consistent user experience

### 3. Path-based Routing with Authentication
- Listener rules with priority 100 for dashboard access
- Cognito authentication for secure access
- Additional API rules for programmatic access

### 4. Security Configuration
- VPC-based OpenSearch deployment in private subnets
- Security groups allowing only necessary traffic
- Encryption in transit and at rest

### 5. Health Checks
- Configured health checks on `/_dashboards/app/home`
- Proper HTTP status code matching (200, 301, 302)
- Unhealthy threshold and timeout configuration

### 6. Monitoring and Logging
- CloudWatch log groups for OpenSearch and ALB
- S3 bucket for ALB access logs (compliance)
- Log retention policies

## Prerequisites

1. **AWS CLI**: Configured with appropriate permissions
2. **Terraform**: Version >= 1.0
3. **ACM Certificate**: Valid SSL certificate for your domain
4. **IAM Permissions**: Required for creating all resources

## Required AWS Permissions

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "elasticloadbalancing:*",
        "es:*",
        "cognito-idp:*",
        "cognito-identity:*",
        "iam:*",
        "logs:*",
        "s3:*",
        "acm:*"
      ],
      "Resource": "*"
    }
  ]
}
```

## Usage

### 1. Initialize Terraform
```bash
cd terraform
terraform init
```

### 2. Review and Customize Variables
```bash
# Copy and modify variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your specific values
```

### 3. Plan Deployment
```bash
terraform plan
```

### 4. Apply Configuration
```bash
terraform apply
```

### 5. Access OpenSearch Dashboard
1. Navigate to the ALB DNS name output by Terraform
2. Access: `https://<alb-dns>/opensearch/_dashboards/`
3. Authenticate using Cognito credentials

## Configuration Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `aws_region` | AWS region for resources | `us-west-2` | No |
| `environment` | Environment name | `dev` | No |
| `project_name` | Project name | `piyush-demo` | No |
| `vpc_cidr` | VPC CIDR block | `10.0.0.0/16` | No |
| `opensearch_instance_type` | OpenSearch instance type | `t3.small.search` | No |
| `opensearch_instance_count` | Number of OpenSearch instances | `2` | No |
| `certificate_domain` | Domain for SSL certificate | `*.example.com` | Yes |
| `dashboard_path` | Path for dashboard routing | `/opensearch/*` | No |

## Outputs

After successful deployment, Terraform provides these key outputs:

- `admin_alb_url`: Direct URL to access the ALB
- `opensearch_dashboard_url`: Complete URL for OpenSearch Dashboard
- `cognito_login_url`: Cognito authentication URL
- `opensearch_endpoint`: Direct OpenSearch API endpoint
- `opensearch_dashboard_endpoint`: OpenSearch dashboard endpoint

## Security Considerations

### Network Security
- OpenSearch deployed in private subnets only
- Security groups with minimal required access
- VPC flow logs enabled (optional)

### Authentication
- Cognito User Pool with strong password policies
- Multi-factor authentication support (configurable)
- Session timeout configuration

### Encryption
- TLS 1.2+ enforced on ALB
- OpenSearch encryption at rest and in transit
- S3 bucket encryption for logs

### Access Control
- IAM policies for least privilege access
- OpenSearch access policies restricted to VPC
- CloudWatch logs for audit trail

## Monitoring and Troubleshooting

### CloudWatch Logs
- ALB access logs: `/aws/alb/{project}-{env}-admin-alb`
- OpenSearch logs: `/aws/opensearch/domains/{project}-{env}-opensearch`
- Application logs: `/aws/opensearch/domains/{project}-{env}-opensearch/application-logs`

### Health Check Monitoring
- Target group health in ALB console
- OpenSearch cluster health in OpenSearch dashboard
- CloudWatch metrics for both services

### Common Issues
1. **Certificate Issues**: Ensure ACM certificate is issued and matches domain
2. **Cognito Configuration**: Verify callback URLs match ALB DNS name
3. **Security Groups**: Check that ALB can reach OpenSearch on port 443
4. **Health Checks**: Verify OpenSearch dashboard is accessible

## Cleanup

To destroy all resources:
```bash
terraform destroy
```

## Integration with Existing Infrastructure

This configuration is designed to integrate with existing AWS infrastructure:

1. **Existing Certificates**: Uses data source to find existing ACM certificates
2. **Naming Conventions**: Follows consistent naming with project and environment
3. **Tagging Strategy**: Applies common tags to all resources
4. **Modular Design**: Can be easily integrated into larger Terraform modules

## Cost Optimization

- Uses appropriate instance sizes for development environments
- Configurable instance counts and types
- Log retention policies to manage storage costs
- Option to disable resources for cost savings in non-production environments

## Future Enhancements

1. **Multi-Environment Support**: Terraform workspaces or separate state files
2. **Auto Scaling**: OpenSearch cluster auto-scaling based on load
3. **Backup Strategy**: Automated snapshots and cross-region replication
4. **Advanced Security**: WAF integration and additional security headers
5. **CI/CD Integration**: Pipeline for automated deployments