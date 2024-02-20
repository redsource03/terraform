variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "alb-sg-id" {
  description = "Security Group of the ALB"
  type        = string
  default = ""
}

variable "vpc-id" {
  description = "VPC id"
  type        = string
  default = ""
}

variable "public-subnets" {
  description = "VPC id"
  type        = list(string)
  default = []
}