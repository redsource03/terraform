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