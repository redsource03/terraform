variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}
variable "tags" {
  type        = map(string)
  default = {
    "Name" = "team1"
  }
}

variable "vpc-id" {
  type = string
  description = "vpc id"
  default = ""
}
variable "vpc-cidr-block" {
  type = string
  description = "vpc-cidr-block"
  default = ""
}