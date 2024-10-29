#!/bin/bash

# Cloning Github Repo
git clone https://github.com/jonwang22/ecommerce_terraform_deployment.git
cd ~/ecommerce_terraform_deployment

#############################
### DJANGO SETUP ###
#############################
# Installing Python and Python-related software for the application
echo "Updating current installed packages..."
sudo apt update

echo "Installing software properties for managing PPAs..."
sudo apt install -y software-properties-common

echo "Adding Deadsnakes PPA repository for Python..."
sudo add-apt-repository -y ppa:deadsnakes/ppa

echo "Installing Python resources..."
sudo apt install -y python3.9 python3.9-venv python3-pip

echo "Creating Python Virtual Environment..."
python3.9 -m venv venv
source venv/bin/activate

# Building Application
echo "Upgrading PIP..."
pip install --upgrade pip

echo "Installing all necessary application dependencies..."
pip install -r ./backend/requirements.txt

# Configuring Allowed Hosts in settings.py
sed -i 's/ALLOWED_HOSTS = \[\]/ALLOWED_HOSTS = \["${backend_private_ip}"\]/' settings.py
