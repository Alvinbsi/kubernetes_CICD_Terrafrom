provider "aws" {
  region = "ap-south-1"  # Change to your desired AWS region
}

resource "aws_s3_bucket" "kops_bucket" {
  bucket = "annwen-traders-kops-bucket"  # Change this to a globally unique bucket name
  acl    = "private"
}

resource "aws_iam_user" "kops_user" {
  name = "kops-iam-user"

  tags = {
    Name = "Kops IAM User"
  }
}

# Attach AdministratorAccess policy to IAM user
resource "aws_iam_user_policy_attachment" "admin_access" {
  user       = aws_iam_user.kops_user.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_access_key" "kops_user_access_key" {
  user = aws_iam_user.kops_user.name
}

resource "aws_security_group" "kops_security_group" {
  name        = "kops-security-group"
  description = "Allow all inbound traffic for Kops cluster"

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "kops_ubuntu" {
  ami           = "ami-0d8f6eb4f6413f6f6"  # Example for Ubuntu 24.04 AMI, update based on your region
  instance_type = "t2.medium"
  key_name      = "annwen_traders"  # Ensure the key is available in your AWS account
  security_groups = [aws_security_group.kops_security_group.name]

  tags = {
    Name = "Kops-EC2"
  }
}

# Create an access key for the IAM user
resource "aws_iam_access_key" "kops_user_access_key" {
  user = aws_iam_user.kops_user.name
}

# Output the access key ID and secret access key
output "kops_user_access_key_id" {
  value = aws_iam_access_key.kops_user_access_key.id
}

output "kops_user_secret_access_key" {
  value = aws_iam_access_key.kops_user_access_key.secret
  sensitive = true
}
