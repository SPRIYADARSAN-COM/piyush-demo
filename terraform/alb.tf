# Data source for existing certificate (assumes ACM certificate exists)
data "aws_acm_certificate" "main" {
  domain      = var.certificate_domain
  statuses    = ["ISSUED"]
  most_recent = true
}

# Application Load Balancer for Admin interface
resource "aws_lb" "admin_alb" {
  name               = "${var.project_name}-${var.environment}-admin-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.admin_alb.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = false

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-admin-alb"
  })
}

# Target Group for default backend (placeholder)
resource "aws_lb_target_group" "default" {
  name     = "${var.project_name}-${var.environment}-default-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "404" # Return 404 for default backend
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-default-tg"
  })
}

# HTTPS Listener for ALB
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.admin_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = data.aws_acm_certificate.main.arn

  # Default action returns 404
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Service not found"
      status_code  = "404"
    }
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-https-listener"
  })
}

# HTTP Listener for ALB (redirect to HTTPS)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.admin_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-http-listener"
  })
}