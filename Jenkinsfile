pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "alvinselva/k8simage"
        GITHUB_REPO = "https://github.com/Alvinbsi/kubernetes_CICD_Terrafrom.git"
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
