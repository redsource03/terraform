provider "aws" {
  region = var.region
}

###### ##
## ALB SG
######

resource "aws_security_group" "team1-alb-sg" {
  name        = "team1-alb-sg"
  description = "Allow TLS inbound traffic on 8080"
  vpc_id      = var.vpc-id

  tags = var.tags
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
  cidr_ipv4         = var.vpc-cidr-block
  ip_protocol       = "-1" # semantically equivalent to all ports
}


####
# Services SG
###
resource "aws_security_group" "services-sg" {
  name        = "team1-services-sg"
  description = "Allow TLS inbound traffic on 8080 and all outbound traffic"
  vpc_id      = var.vpc-id

  tags = var.tags
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