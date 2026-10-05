data "aws_vpc" "this" {
  id = var.vpc_id
}

locals {
  https = var.certificate_arn != null
}

resource "aws_security_group" "this" {
  name_prefix = "${var.name}-alb-"
  description = "Load balancer ${var.name}"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = "${var.name}-alb" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  # checkov:skip=CKV_AWS_260: public load balancer; port 80 only redirects to HTTPS when a certificate is set
  for_each = toset(var.ingress_cidr_blocks)

  security_group_id = aws_security_group.this.id
  description       = "HTTP${local.https ? " (redirected to HTTPS)" : ""}"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_ingress_rule" "https" {
  for_each = local.https ? toset(var.ingress_cidr_blocks) : toset([])

  security_group_id = aws_security_group.this.id
  description       = "HTTPS"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = each.value
}

# Only towards the VPC: the load balancer talks to targets, nothing else.
resource "aws_vpc_security_group_egress_rule" "to_targets" {
  security_group_id = aws_security_group.this.id
  description       = "Targets inside the VPC"
  ip_protocol       = "tcp"
  from_port         = 0
  to_port           = 65535
  cidr_ipv4         = data.aws_vpc.this.cidr_block
}

resource "aws_lb" "this" {
  # checkov:skip=CKV_AWS_91: access logs are optional (var.access_logs_bucket)
  # checkov:skip=CKV_AWS_150: deletion protection is configurable (var.deletion_protection)
  # checkov:skip=CKV2_AWS_20: HTTP redirects to HTTPS whenever var.certificate_arn is set
  # checkov:skip=CKV2_AWS_28: WAF is attached by the caller (aws_wafv2_web_acl_association) where needed
  name                       = var.name
  load_balancer_type         = "application"
  internal                   = false
  subnets                    = var.subnet_ids
  security_groups            = [aws_security_group.this.id]
  idle_timeout               = var.idle_timeout
  drop_invalid_header_fields = true
  enable_deletion_protection = var.deletion_protection

  dynamic "access_logs" {
    for_each = var.access_logs_bucket != null ? [1] : []
    content {
      bucket  = var.access_logs_bucket
      prefix  = var.name
      enabled = true
    }
  }

  tags = var.tags
}

resource "aws_lb_listener" "http" {
  # checkov:skip=CKV_AWS_2: becomes a redirect to HTTPS when var.certificate_arn is set
  # checkov:skip=CKV_AWS_103: TLS policy applies to the HTTPS listener; this one only redirects or serves 404
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  dynamic "default_action" {
    for_each = local.https ? [1] : []
    content {
      type = "redirect"
      redirect {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }

  dynamic "default_action" {
    for_each = local.https ? [] : [1]
    content {
      type = "fixed-response"
      fixed_response {
        content_type = "application/json"
        message_body = "{\"title\":\"Not Found\",\"status\":404}"
        status_code  = "404"
      }
    }
  }

  tags = var.tags
}

resource "aws_lb_listener" "https" {
  count = local.https ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.certificate_arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "application/json"
      message_body = "{\"title\":\"Not Found\",\"status\":404}"
      status_code  = "404"
    }
  }

  tags = var.tags
}
