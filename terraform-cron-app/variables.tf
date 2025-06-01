variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-south-1"
}

variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate for the custom domain"
  type        = string
  default     = ""
}
