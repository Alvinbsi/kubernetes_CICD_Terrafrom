# 1. Directory Structure
/kubernetes-project
├── main.tf                 # Terraform main configuration file
├── variables.tf            # Terraform variables file
├── outputs.tf              # Terraform outputs file
├── Jenkinsfile             # Jenkins pipeline definition
└── scripts/                
    ├── install_jenkins.sh  # Shell script to install Jenkins on EC2 instance
    ├── setup_pipeline.sh   # Shell script to set up pipeline and other configuration
    ├── deploy_k8s.sh       # Shell script for deploying to Kubernetes

# 2. Terraform Configuration Files
# main.tf
provider "aws" {
  region = "ap-south-1"  # Change to your desired AWS region
}

resource "aws_s3_bucket" "kops_bucket" {
  bucket = "annwen-traders-kops-bucket"  # Change this to a globally unique bucket name
  acl    = "private"
}

resource "aws_iam_role" "kops_role" {
  name = "kops-iam-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
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

# 2. variables.tf
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

# 3. outputs.tf
output "kops_bucket_name" {
  value = aws_s3_bucket.kops_bucket.bucket
  description = "S3 bucket name for storing kops state"
}

output "kops_security_group_id" {
  value = aws_security_group.kops_security_group.id
  description = "Security group ID"
}

# 4. Jenkinsfile

pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "alvinselva/k8sfrontend"
        GITHUB_REPO = "https://github.com/Iam-alvin/SaturdayProject.git"
        DOCKER_HUB_CREDENTIALS = "dockerhub-credentials"  // Jenkins credentials ID for DockerHub login
        AWS_ACCESS_KEY_ID = credentials('aws-access-key-id')  // Jenkins credentials for AWS
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key')  // Jenkins credentials for AWS
    }

    stages {
        stage('Terraform Init') {
            steps {
                script {
                    // Initialize Terraform (this will install the necessary providers)
                    sh 'terraform init'
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                script {
                    // Apply Terraform to provision infrastructure
                    // It is recommended to use 'terraform plan' and 'terraform apply' with auto-approve for non-interactive execution
                    sh 'terraform apply -auto-approve'
                }
            }
        }

        stage('Pull Code From GitHub') {
            steps {
                git branch: 'master', url: "${GITHUB_REPO}"
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    // Build Docker image
                    sh 'docker build -t $DOCKER_IMAGE .'
                    sh 'docker tag $DOCKER_IMAGE $DOCKER_IMAGE:latest'
                    sh 'docker tag $DOCKER_IMAGE $DOCKER_IMAGE:${BUILD_NUMBER}'
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    // Login to DockerHub and push the image
                    withCredentials([usernamePassword(credentialsId: DOCKER_HUB_CREDENTIALS, passwordVariable: 'DOCKER_PASSWORD', usernameVariable: 'DOCKER_USERNAME')]) {
                        sh "docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD"
                        sh "docker push $DOCKER_IMAGE:latest"
                        sh "docker push $DOCKER_IMAGE:${BUILD_NUMBER}"
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                script {
                    // Apply Kubernetes YAML files to deploy the image
                    sh 'kubectl apply -f pod.yaml'
                    sh 'kubectl rollout restart deployment loadbalancer-pod'
                }
            }
        }
    }
    
    post {
        always {
            cleanWs()  // Clean workspace after build
        }
    }
}

# 5. scripts/install_jenkins.sh
#!/bin/bash
# Install Java
sudo apt-get update
sudo apt-get install default-jdk -y
java -version

# Install Jenkins
wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -
sudo sh -c 'wget -q -O /etc/apt/sources.list.d/jenkins.list https://pkg.jenkins.io/debian/jenkins.io.key'
sudo apt-get update
sudo apt-get install jenkins -y

# Start Jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins

# 6. scripts/setup_pipeline.sh
#!/bin/bash
# Set up the pipeline by creating the job configuration
# This assumes Jenkins CLI is configured and Jenkins is accessible

JENKINS_URL="http://localhost:8080"
JOB_NAME="Kubernetes_CI_CD_Pipeline"

curl -X POST "${JENKINS_URL}/createItem?name=${JOB_NAME}" --data @jenkins-job-config.xml -H "Content-Type: application/xml"

# 7. scripts/deploy_k8s.sh
#!/bin/bash
# Deploy Kubernetes resources (Assumes kubectl is set up)
kubectl apply -f pod.yaml
kubectl rollout restart deployment loadbalancer-pod


