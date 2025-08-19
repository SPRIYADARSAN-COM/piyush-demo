# Security Groups for ALB and OpenSearch communication

# ALB Security Group
resource "aws_security_group" "admin_alb" {
  name_prefix = "${var.project_name}-${var.environment}-admin-alb-"
  vpc_id      = aws_vpc.main.id
  description = "Security group for admin ALB"

  # Allow HTTP traffic from internet
  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTPS traffic from internet
  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-admin-alb-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# OpenSearch Security Group
resource "aws_security_group" "opensearch" {
  name_prefix = "${var.project_name}-${var.environment}-opensearch-"
  vpc_id      = aws_vpc.main.id
  description = "Security group for OpenSearch domain"

  # Allow HTTPS traffic from ALB security group
  ingress {
    description     = "HTTPS from ALB"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.admin_alb.id]
  }

  # Allow HTTP traffic from ALB security group (for health checks)
  ingress {
    description     = "HTTP from ALB for health checks"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.admin_alb.id]
  }

  # Allow OpenSearch API traffic from ALB (port 9200)
  ingress {
    description     = "OpenSearch API from ALB"
    from_port       = 9200
    to_port         = 9200
    protocol        = "tcp"
    security_groups = [aws_security_group.admin_alb.id]
  }

  # Allow all outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-opensearch-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Security group for Cognito User Pool
resource "aws_security_group" "cognito" {
  name_prefix = "${var.project_name}-${var.environment}-cognito-"
  vpc_id      = aws_vpc.main.id
  description = "Security group for Cognito resources"

  # Allow HTTPS traffic for Cognito endpoints
  ingress {
    description = "HTTPS for Cognito"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Allow all outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-cognito-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}