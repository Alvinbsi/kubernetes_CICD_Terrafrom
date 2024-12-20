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
