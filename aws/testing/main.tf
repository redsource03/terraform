
provider "aws" {
  region = local.region
}

data "aws_availability_zones" "available" {}

locals {
  region = "eu-central-1"
  name   = "testing"

  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  container_name = "hello-world-java"
  container_port = 8080

  tags = {
    Name = local.name
  }
}

################################################################################
# Cluster
################################################################################

module "ecs_cluster" {
  source = ".//modules/cluster"

  cluster_name = format("%s-%s", local.name, "cluster")
  # Capacity provider
  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 50
        base   = 20
      }
    }
    FARGATE_SPOT = {
      default_capacity_provider_strategy = {
        weight = 50
      }
    }
  }

  tags = local.tags
}

################################################################################
# Service
################################################################################

module "ecs_service" {
  source = ".//modules/ecs-service"

  name        = local.name
  cluster_arn = module.ecs_cluster.arn

  cpu    = 256
  memory = 512

  # Enables ECS Exec
  enable_execute_command = true
  service_connect_configuration = {
    namespace = aws_service_discovery_http_namespace.example.name
    service = {
      client_alias = {
        port     = local.container_port
        dns_name = local.container_name
      }
      port_name      = local.container_name
      discovery_name = local.container_name
    }
  }
  # Container definition(s)
  container_definitions = {
    (local.container_name) = {
      readonly_root_filesystem = false
      cpu                      = 256
      memory                   = 512
      essential                = true
      image                    = "redsource/simple-web-java:latest"
      port_mappings = [
        {
          name          = local.container_name
          containerPort = local.container_port
          hostPort      = local.container_port
          protocol      = "tcp"
        }
      ]
      environment = [
          {"name":"API_HOST", "value": "http://hello-world-java-2:8080" },
          {"name":"CONTEXT_PATH", "value": "/app1" },
          {"name":"API_CONTEXT_PATH", "value": "/app2" }
      ]
    }
  }

  load_balancer = {
    service = {
      target_group_arn = module.alb.target_groups["hello-world-tg"].arn
      container_name   = local.container_name
      container_port   = local.container_port
    }
  }

  subnet_ids = module.vpc.private_subnets
  
  security_group_ids = [ aws_security_group.services-sg.id ]
  security_group_rules = {
    alb_ingress_3000 = {
      type                     = "ingress"
      from_port                = local.container_port
      to_port                  = local.container_port
      protocol                 = "tcp"
      description              = "Service port"
      source_security_group_id = aws_security_group.services-sg.id
    }
  }

  service_tags = {
    "ServiceTag" = "Tag on service level"
  }

  tags = local.tags
}

################################################################################
# SERVICE2
################################################################################
module "ecs_service_2" {
  source = ".//modules/ecs-service"

  name        = format("%s-%s", local.name, "2")
  cluster_arn = module.ecs_cluster.arn

  cpu    = 256
  memory = 512

  # Enables ECS Exec
  enable_execute_command = true
  service_connect_configuration = {
    namespace = aws_service_discovery_http_namespace.example.name
    service = {
      client_alias = {
        port     = local.container_port
        dns_name = format("%s-%s", local.container_name, "2")
      }
      port_name      = format("%s-%s", local.container_name, "2")
      discovery_name = format("%s-%s", local.container_name, "2")
    }
  }
  # Container definition(s)
  container_definitions = {
    format("%s-%s", local.container_name, "2") = {
      readonly_root_filesystem = false
      cpu                      = 256
      memory                   = 512
      essential                = true
      image                    = "redsource/simple-web-java:latest"
      port_mappings = [
        {
          name          = format("%s-%s", local.container_name, "2")
          containerPort = local.container_port
          hostPort      = local.container_port
          protocol      = "tcp"
        }
      ]
      environment = [
          {"name":"API_HOST", "value": "http://hello-world-java:8080" },
          {"name":"CONTEXT_PATH", "value": "/app2" },
          {"name":"API_CONTEXT_PATH", "value": "/app1" }
      ]
      
    }
  }

  load_balancer = {
    service = {
      target_group_arn = module.alb.target_groups["hello-world-tg-2"].arn
      container_name   = format("%s-%s", local.container_name, "2")
      container_port   = local.container_port
    }
  }

  subnet_ids = module.vpc.private_subnets
  security_group_ids = [ aws_security_group.services-sg.id ]
  security_group_rules = {
    alb_ingress_3000 = {
      type                     = "ingress"
      from_port                = local.container_port
      to_port                  = local.container_port
      protocol                 = "tcp"
      description              = "Service port"
      source_security_group_id = aws_security_group.services-sg.id
    }
  }
  service_tags = {
    "ServiceTag" = "Tag on service level"
  }

  tags = local.tags
}

################################################################################
# Supporting Resources
################################################################################

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.0"

  name = format("%s-%s", local.name, "alb")

  load_balancer_type = "application"

  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.public_subnets

  # For example only
  enable_deletion_protection = false

  # Security Group
  security_groups = [aws_security_group.team1-alb-sg.id]
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

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = format("%s-%s", local.name, "vpc")
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 48)]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = local.tags
}

### 
# SG
###

resource "aws_security_group" "team1-alb-sg" {
  name        = "team1-alb-sg"
  description = "Allow TLS inbound traffic on 8080"
  vpc_id      = module.vpc.vpc_id

  tags = local.tags
}

resource "aws_vpc_security_group_ingress_rule" "allow_http_8080_alb" {
  security_group_id = aws_security_group.team1-alb-sg.id
  cidr_ipv4   = "0.0.0.0/0"
  from_port         = 8080
  ip_protocol       = "tcp"
  to_port           = 8080
}


resource "aws_vpc_security_group_egress_rule" "alb_allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.team1-alb-sg.id
  cidr_ipv4         = module.vpc.vpc_cidr_block
  ip_protocol       = "-1" # semantically equivalent to all ports
}


####
# Services SG
###
resource "aws_security_group" "services-sg" {
  name        = "team1-services-sg"
  description = "Allow TLS inbound traffic on 8080 and all outbound traffic"
  vpc_id      = module.vpc.vpc_id

  tags = local.tags
}


resource "aws_security_group_rule" "services-ingress" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.team1-alb-sg.id
  security_group_id        = aws_security_group.services-sg.id
}

resource "aws_vpc_security_group_egress_rule" "services_allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.services-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}
resource "aws_service_discovery_http_namespace" "example" {
  name        = local.name
  description = "example"
}