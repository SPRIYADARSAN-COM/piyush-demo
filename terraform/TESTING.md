# Testing and Deployment Guide

This document provides a comprehensive testing plan for the OpenSearch Dashboard ALB integration.

## Pre-Deployment Checklist

### 1. Prerequisites Verification
- [ ] AWS CLI configured with appropriate permissions
- [ ] Terraform >= 1.0 installed
- [ ] Valid ACM certificate exists for your domain
- [ ] Domain name configured for certificate_domain variable

### 2. Configuration Review
- [ ] Copy `terraform.tfvars.example` to `terraform.tfvars`
- [ ] Update `certificate_domain` with your actual domain
- [ ] Review and adjust instance types and sizes for your environment
- [ ] Verify CIDR blocks don't conflict with existing infrastructure

## Deployment Steps

### Step 1: Initialize Terraform
```bash
cd terraform
terraform init
```

### Step 2: Plan Deployment
```bash
terraform plan -var-file="terraform.tfvars"
```

### Step 3: Deploy Infrastructure
```bash
terraform apply -var-file="terraform.tfvars"
```

## Testing Plan

### Phase 1: Infrastructure Validation

#### 1.1 VPC and Networking
- [ ] Verify VPC creation with correct CIDR
- [ ] Check public and private subnets across AZs
- [ ] Validate NAT gateways and routing tables
- [ ] Test internet connectivity from public subnets

#### 1.2 Security Groups
- [ ] Verify ALB security group allows HTTP/HTTPS from internet
- [ ] Check OpenSearch security group allows traffic from ALB
- [ ] Validate Cognito security group configuration

#### 1.3 OpenSearch Domain
- [ ] Confirm OpenSearch domain is in ACTIVE state
- [ ] Verify domain is deployed in private subnets
- [ ] Check encryption at rest and in transit
- [ ] Validate access policies

### Phase 2: ALB and Authentication Testing

#### 2.1 Load Balancer
- [ ] Verify ALB is created and healthy
- [ ] Test HTTP to HTTPS redirect
- [ ] Check listener rules are correctly configured
- [ ] Validate SSL certificate attachment

#### 2.2 Cognito Authentication
- [ ] Verify User Pool creation
- [ ] Test User Pool Client configuration
- [ ] Check authentication flow
- [ ] Validate session management

### Phase 3: Integration Testing

#### 3.1 Dashboard Access
1. Navigate to: `https://<alb-dns>/opensearch/`
2. Expected behavior:
   - [ ] Redirect to Cognito login
   - [ ] Authentication required
   - [ ] Successful login redirects to OpenSearch dashboard
   - [ ] Dashboard loads correctly

#### 3.2 API Access
1. Test API endpoints:
   ```bash
   curl -H "Authorization: Bearer <token>" https://<alb-dns>/_cluster/health
   ```
2. Expected behavior:
   - [ ] Authorization header required
   - [ ] Redirect to OpenSearch API endpoint
   - [ ] Valid responses from OpenSearch

### Phase 4: Monitoring and Logging

#### 4.1 CloudWatch Logs
- [ ] Verify ALB access logs in CloudWatch
- [ ] Check OpenSearch logs are being created
- [ ] Validate log retention policies

#### 4.2 CloudWatch Dashboard
- [ ] Access CloudWatch dashboard
- [ ] Verify OpenSearch metrics are displayed
- [ ] Check ALB metrics are visible
- [ ] Validate alarm configurations

#### 4.3 S3 Access Logs
- [ ] Verify S3 bucket creation for ALB logs
- [ ] Check bucket encryption and policies
- [ ] Validate access log delivery

## Performance Testing

### Load Testing
1. Use tools like Apache Bench or Artillery.js
2. Test scenarios:
   - [ ] Multiple concurrent dashboard sessions
   - [ ] API throughput testing
   - [ ] Authentication load testing

### Monitoring
- [ ] Monitor OpenSearch cluster health
- [ ] Check ALB response times
- [ ] Validate auto-scaling behavior (if configured)

## Security Testing

### 4.1 Access Control
- [ ] Verify unauthenticated access is blocked
- [ ] Test authentication bypass attempts
- [ ] Validate session timeout functionality

### 4.2 Network Security
- [ ] Confirm OpenSearch is not directly accessible from internet
- [ ] Test security group restrictions
- [ ] Validate encrypted connections

## Troubleshooting Guide

### Common Issues

#### 1. Certificate Issues
**Problem**: SSL certificate errors
**Solution**: 
- Verify ACM certificate exists and is issued
- Check domain name matches certificate
- Ensure certificate is in the same region

#### 2. Authentication Issues
**Problem**: Cognito authentication fails
**Solution**:
- Check User Pool configuration
- Verify callback URLs match ALB DNS
- Review Cognito logs in CloudWatch

#### 3. OpenSearch Access Issues
**Problem**: Cannot reach OpenSearch dashboard
**Solution**:
- Verify OpenSearch domain is active
- Check security group rules
- Review VPC configuration

#### 4. Redirect Issues
**Problem**: Infinite redirects or redirect loops
**Solution**:
- Check listener rule priorities
- Verify path patterns don't overlap
- Review authentication configuration

### Debugging Commands

```bash
# Check Terraform state
terraform show

# View specific resource
terraform state show aws_opensearch_domain.main

# Check ALB target health
aws elbv2 describe-target-health --target-group-arn <target-group-arn>

# OpenSearch cluster health
curl -X GET "https://<opensearch-endpoint>/_cluster/health"

# View CloudWatch logs
aws logs describe-log-groups --log-group-name-prefix "/aws/opensearch"
```

## Clean Up

### Testing Environment Clean Up
```bash
terraform destroy -var-file="terraform.tfvars"
```

### Selective Resource Cleanup
```bash
# Remove specific resources
terraform destroy -target=aws_opensearch_domain.main
```

## Production Deployment Considerations

### 1. High Availability
- [ ] Deploy across multiple AZs
- [ ] Configure OpenSearch cluster with multiple nodes
- [ ] Implement proper backup strategies

### 2. Security Hardening
- [ ] Enable VPC Flow Logs
- [ ] Implement WAF rules
- [ ] Add MFA to Cognito
- [ ] Configure IP allowlisting if needed

### 3. Monitoring Enhancement
- [ ] Add SNS notifications to alarms
- [ ] Implement custom metrics
- [ ] Set up log aggregation
- [ ] Configure automated alerts

### 4. Performance Optimization
- [ ] Tune OpenSearch instance types
- [ ] Implement caching strategies
- [ ] Optimize ALB configuration
- [ ] Configure auto-scaling

## Success Criteria

The deployment is considered successful when:

1. **Infrastructure**: All AWS resources are created and healthy
2. **Security**: Authentication is enforced and working correctly
3. **Functionality**: OpenSearch dashboard is accessible through ALB
4. **Monitoring**: CloudWatch metrics and logs are operational
5. **Performance**: Response times meet requirements
6. **Documentation**: All configurations are documented and tested

## Next Steps

After successful deployment:

1. Create user accounts in Cognito User Pool
2. Configure OpenSearch index patterns and visualizations
3. Set up data ingestion pipelines
4. Implement backup and disaster recovery procedures
5. Plan for capacity scaling based on usage patterns