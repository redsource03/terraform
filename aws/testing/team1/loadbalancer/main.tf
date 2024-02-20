
provider "aws" {
  region = var.region
}

################################################################################
# Supporting Resources
################################################################################
locals {
  container_port = 8080
  tags = {
    Name = "team1"
  }
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.0"

  name = "team1-alb"

  load_balancer_type = "application"

  vpc_id  = var.vpc-id
  subnets = var.public-subnets

  # For example only
  enable_deletion_protection = false
  security_groups = [var.alb-sg-id]

  listeners = {
    ex_http = {
      port     = 8080
      protocol = "HTTP"
      forward = {
        target_group_key = "hello-world-tg"
      }
      rules = {
        forward-app = {
          actions = [
            {
              type             = "forward"
              target_group_key = "hello-world-tg"
            }
          ]

          conditions = [{
            path_pattern = {
              values = ["/app1/*"]
            }
          }]
        }

        forward-app-2 = {
          actions = [
            {
              type             = "forward"
              target_group_key = "hello-world-tg-2"
            }
          ]

          conditions = [{
            path_pattern = {
              values = ["/app2/*"]
            }
          }]
        }
      }
    }
  }

  target_groups = {
    hello-world-tg = {
      backend_protocol                  = "HTTP"
      backend_port                      = local.container_port
      target_type                       = "ip"
      deregistration_delay              = 5
      load_balancing_cross_zone_enabled = true

      health_check = {
        enabled             = true
        healthy_threshold   = 5
        interval            = 30
        matcher             = "200"
        path                = "/app1/"
        port                = "traffic-port"
        protocol            = "HTTP"
        timeout             = 5
        unhealthy_threshold = 2
      }

      create_attachment = false
    }

    hello-world-tg-2 = {
      backend_protocol                  = "HTTP"
      backend_port                      = local.container_port
      target_type                       = "ip"
      deregistration_delay              = 5
      load_balancing_cross_zone_enabled = true

      health_check = {
        enabled             = true
        healthy_threshold   = 5
        interval            = 30
        matcher             = "200"
        path                = "/app2/"
        port                = "traffic-port"
        protocol            = "HTTP"
        timeout             = 5
        unhealthy_threshold = 2
      }

      create_attachment = false
    }
  }

  tags = local.tags
}