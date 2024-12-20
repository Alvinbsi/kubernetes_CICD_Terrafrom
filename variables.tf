variable "aws_access_key" {
  type        = string
  description = "AWS Access Key"
}

variable "aws_secret_key" {
  type        = string
  description = "AWS Secret Key"
}

variable "aws_region" {
  type        = string
  description = "AWS region for the resources"
  default     = "ap-south-1"
}

variable "cluster_name" {
  type        = string
  description = "Kubernetes cluster name"
  default     = "alvin.k8s.local"
}

variable "bucket_name" {
  type        = string
  description = "S3 Bucket for storing Kops state"
  default     = "annwen-traders-kops-bucket"
}
