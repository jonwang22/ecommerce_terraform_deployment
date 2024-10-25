#!/bin/bash

# Installing dependencies for Jenkins
sudo apt update

# Installing fontconfig and JavaDevKit for Jenkins.
sudo apt install -y fontconfig openjdk-17-jre software-properties-common

# Installing Python packages
sudo add-apt-repository -y ppa:deadsnakes/ppa
sudo apt install -y python3.9 python3.9-venv python3-pip python3.9-dev

# Installing packages for Terraform
sudo apt-get update 
# software-properties-common was already downloaded prior, removing from this command.
# Instructions to install are found here https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli
sudo apt-get install -y gnupg 

# Installing Hashicorp GPG key
wget -O- https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor | \
sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

# Verifying Terraform key's fingerprint
gpg --no-default-keyring \
--keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
--fingerprint

# Should look something like this.
# /usr/share/keyrings/hashicorp-archive-keyring.gpg
# -------------------------------------------------
# pub   rsa4096 XXXX-XX-XX [SC]
# AAAA AAAA AAAA AAAA
# uid           [ unknown] HashiCorp Security (HashiCorp Package Signing) <security+packaging@hashicorp.com>
# sub   rsa4096 XXXX-XX-XX [E]

# Adding Hashicorp repo to system.
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
sudo tee /etc/apt/sources.list.d/hashicorp.list

# Download and install terraform
sudo apt-get update
sudo apt-get install terraform -y

# Downloaded the Jenkins respository key. Added the key to the /usr/share/keyrings directory
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key

# Added Jenkins repo to sources list
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc]" https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

# Downloaded all updates for packages again, installed Jenkins
sudo apt-get update
sudo apt-get install jenkins -y

# Started Jenkins and checked to make sure Jenkins is active and running with no issues
sudo systemctl start jenkins
sudo systemctl status jenkins