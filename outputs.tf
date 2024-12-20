output "kops_bucket_name" {
  value = aws_s3_bucket.kops_bucket.bucket
  description = "S3 bucket name for storing kops state"
}

output "kops_security_group_id" {
  value = aws_security_group.kops_security_group.id
  description = "Security group ID"
}
