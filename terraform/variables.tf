variable "aws_region" {
  default = "ap-south-1"
}

variable "acm_certificate_arn" {
  description = "The ARN of the ACM certificate for the custom domain. Must be in us-east-1."
  type        = string
}

variable "custom_domain" {
  description = "Custom domain name for API Gateway."
  type        = string
  default     = "services.tatkalpro.in"
}
