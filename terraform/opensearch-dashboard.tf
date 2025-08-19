# OpenSearch Dashboard ALB Integration
# This file implements the integration between the admin ALB and OpenSearch dashboard

# For VPC-based OpenSearch, we'll use a redirect approach since direct target group
# integration is complex with VPC endpoints. Users will be redirected to the
# OpenSearch dashboard endpoint after authentication.

# ALB Listener Rule for OpenSearch Dashboard with Cognito Authentication
resource "aws_lb_listener_rule" "opensearch_dashboard" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100 # High priority to handle before other rules

  # Path-based routing condition
  condition {
    path_pattern {
      values = [
        var.dashboard_path,
        "/opensearch*",
        "/_dashboards*",
        "/_plugins*"
      ]
    }
  }

  # Cognito authentication action
  action {
    type  = "authenticate-cognito"
    order = 1

    authenticate_cognito {
      user_pool_arn       = aws_cognito_user_pool.main.arn
      user_pool_client_id = aws_cognito_user_pool_client.main.id
      user_pool_domain    = aws_cognito_user_pool_domain.main.domain

      # Authentication flow configuration
      authentication_request_extra_params = {
        prompt = "login"
      }

      # Session configuration
      session_cookie_name = "AWSELBAuthSessionCookie"
      session_timeout     = 3600 # 1 hour
      scope               = "openid profile email"

      # Behavior on unauthenticated requests
      on_unauthenticated_request = "authenticate"
    }
  }

  # Redirect to OpenSearch dashboard endpoint after authentication
  action {
    type  = "redirect"
    order = 2

    redirect {
      protocol    = "HTTPS"
      port        = "443"
      host        = aws_opensearch_domain.main.endpoint
      path        = "/_dashboards/"
      status_code = "HTTP_302"
    }
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-opensearch-rule"
  })

  depends_on = [
    aws_cognito_user_pool.main,
    aws_cognito_user_pool_client.main,
    aws_cognito_user_pool_domain.main
  ]
}

# Additional Listener Rule for OpenSearch API access (with basic auth for programmatic access)
resource "aws_lb_listener_rule" "opensearch_api" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 101 # Lower priority than dashboard

  # Path-based routing condition for API endpoints
  condition {
    path_pattern {
      values = [
        "/_search*",
        "/_cat*",
        "/_cluster*",
        "/_nodes*",
        "/logs-*",
        "/metrics-*",
        "/_bulk*"
      ]
    }
  }

  # Header-based condition for API authentication (require Authorization header)
  condition {
    http_header {
      http_header_name = "Authorization"
      values           = ["*"]
    }
  }

  # Redirect to OpenSearch API endpoint
  action {
    type = "redirect"

    redirect {
      protocol    = "HTTPS"
      port        = "443"
      host        = aws_opensearch_domain.main.endpoint
      path        = "/#{path}"
      query       = "#{query}"
      status_code = "HTTP_302"
    }
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-opensearch-api-rule"
  })
}

# CloudWatch Log Group for ALB access logs
resource "aws_cloudwatch_log_group" "alb_logs" {
  name              = "/aws/alb/${var.project_name}-${var.environment}-admin-alb"
  retention_in_days = 7

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-alb-logs"
  })
}

# S3 bucket for ALB access logs (for compliance and detailed analysis)
resource "aws_s3_bucket" "alb_logs" {
  bucket = "${var.project_name}-${var.environment}-alb-logs-${random_string.bucket_suffix.result}"

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-alb-logs"
  })
}

resource "aws_s3_bucket_versioning" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Random string for S3 bucket suffix to ensure uniqueness
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# S3 bucket policy for ALB access logs
data "aws_elb_service_account" "main" {}

resource "aws_s3_bucket_policy" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = data.aws_elb_service_account.main.arn
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_logs.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_logs.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.alb_logs.arn
      }
    ]
  })
}

# CloudWatch Dashboard for monitoring OpenSearch and ALB metrics
resource "aws_cloudwatch_dashboard" "opensearch_monitoring" {
  dashboard_name = "${var.project_name}-${var.environment}-opensearch-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ES", "ClusterStatus.yellow", "DomainName", aws_opensearch_domain.main.domain_name, "ClientId", data.aws_caller_identity.current.account_id],
            [".", "ClusterStatus.red", ".", ".", ".", "."],
            [".", "Nodes", ".", ".", ".", "."]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "OpenSearch Cluster Status"
          yAxis = {
            left = {
              min = 0
            }
          }
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.admin_alb.arn_suffix],
            [".", "HTTPCode_ELB_5XX_Count", ".", "."],
            [".", "HTTPCode_Target_2XX_Count", ".", "."],
            [".", "TargetResponseTime", ".", "."]
          ]
          period = 300
          stat   = "Sum"
          region = data.aws_region.current.name
          title  = "ALB Request Metrics"
          yAxis = {
            left = {
              min = 0
            }
          }
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ES", "SearchLatency", "DomainName", aws_opensearch_domain.main.domain_name, "ClientId", data.aws_caller_identity.current.account_id],
            [".", "IndexingLatency", ".", ".", ".", "."],
            [".", "CPUUtilization", ".", ".", ".", "."]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "OpenSearch Performance Metrics"
          yAxis = {
            left = {
              min = 0
            }
          }
        }
      }
    ]
  })
}

# CloudWatch Alarms for monitoring
resource "aws_cloudwatch_metric_alarm" "opensearch_cluster_red" {
  alarm_name          = "${var.project_name}-${var.environment}-opensearch-cluster-red"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "ClusterStatus.red"
  namespace           = "AWS/ES"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "0"
  alarm_description   = "This metric monitors opensearch cluster red status"
  alarm_actions       = [] # Add SNS topic ARN for notifications

  dimensions = {
    DomainName = aws_opensearch_domain.main.domain_name
    ClientId   = data.aws_caller_identity.current.account_id
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-opensearch-red-alarm"
  })
}

resource "aws_cloudwatch_metric_alarm" "alb_high_5xx" {
  alarm_name          = "${var.project_name}-${var.environment}-alb-high-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "This metric monitors ALB 5xx errors"
  alarm_actions       = [] # Add SNS topic ARN for notifications

  dimensions = {
    LoadBalancer = aws_lb.admin_alb.arn_suffix
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-alb-5xx-alarm"
  })
}