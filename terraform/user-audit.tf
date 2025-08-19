# IAM role for OpenSearch service
resource "aws_iam_service_linked_role" "opensearch" {
  aws_service_name = "opensearchserverless.amazonaws.com"
  description      = "Service-linked role for OpenSearch"
}

# IAM policy document for OpenSearch domain access
data "aws_iam_policy_document" "opensearch_access_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "es:*",
    ]

    resources = [
      "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${var.project_name}-${var.environment}-opensearch/*"
    ]

    condition {
      test     = "IpAddress"
      variable = "aws:SourceIp"
      values   = [var.vpc_cidr]
    }
  }
}

# OpenSearch Domain
resource "aws_opensearch_domain" "main" {
  domain_name    = "${var.project_name}-${var.environment}-opensearch"
  engine_version = "OpenSearch_2.7"

  cluster_config {
    instance_type            = var.opensearch_instance_type
    instance_count           = var.opensearch_instance_count
    dedicated_master_enabled = false
    zone_awareness_enabled   = var.opensearch_instance_count > 1

    dynamic "zone_awareness_config" {
      for_each = var.opensearch_instance_count > 1 ? [1] : []
      content {
        availability_zone_count = 2
      }
    }
  }

  # VPC configuration
  vpc_options {
    security_group_ids = [aws_security_group.opensearch.id]
    subnet_ids         = slice(aws_subnet.private[*].id, 0, min(2, length(aws_subnet.private)))
  }

  # EBS configuration
  ebs_options {
    ebs_enabled = true
    volume_type = "gp3"
    volume_size = var.opensearch_volume_size
  }

  # Encryption configuration
  encrypt_at_rest {
    enabled = true
  }

  node_to_node_encryption {
    enabled = true
  }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  # Access policy
  access_policies = data.aws_iam_policy_document.opensearch_access_policy.json

  # Advanced options
  advanced_options = {
    "rest.action.multi.allow_explicit_index" = "true"
    "indices.fielddata.cache.size"           = "20"
    "indices.query.bool.max_clause_count"    = "1024"
  }

  # Log publishing options
  log_publishing_options {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.opensearch_logs.arn
    log_type                 = "INDEX_SLOW_LOGS"
  }

  log_publishing_options {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.opensearch_logs.arn
    log_type                 = "SEARCH_SLOW_LOGS"
  }

  log_publishing_options {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.opensearch_application_logs.arn
    log_type                 = "ES_APPLICATION_LOGS"
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-opensearch"
  })

  depends_on = [aws_iam_service_linked_role.opensearch]
}

# CloudWatch Log Group for OpenSearch logs
resource "aws_cloudwatch_log_group" "opensearch_logs" {
  name              = "/aws/opensearch/domains/${var.project_name}-${var.environment}-opensearch"
  retention_in_days = 14

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-opensearch-logs"
  })
}

# CloudWatch Log Group for OpenSearch application logs
resource "aws_cloudwatch_log_group" "opensearch_application_logs" {
  name              = "/aws/opensearch/domains/${var.project_name}-${var.environment}-opensearch/application-logs"
  retention_in_days = 14

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-opensearch-app-logs"
  })
}

# CloudWatch Log Resource Policy for OpenSearch
resource "aws_cloudwatch_log_resource_policy" "opensearch_log_policy" {
  policy_name = "${var.project_name}-${var.environment}-opensearch-log-policy"

  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "es.amazonaws.com"
        }
        Action = [
          "logs:PutLogEvents",
          "logs:PutLogEventsBatch",
          "logs:CreateLogGroup",
          "logs:CreateLogStream"
        ]
        Resource = "arn:aws:logs:*"
      }
    ]
  })
}