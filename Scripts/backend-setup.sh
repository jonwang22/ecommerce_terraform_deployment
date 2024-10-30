#!/bin/bash

#############################
### ADD CODON SSH PUB KEY ###
#############################
SSH_PUB_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDSkMc19m28614Rb3sGEXQUN+hk4xGiufU9NYbVXWGVrF1bq6dEnAD/VtwM6kDc8DnmYD7GJQVvXlDzvlWxdpBaJEzKziJ+PPzNVMPgPhd01cBWPv82+/Wu6MNKWZmi74TpgV3kktvfBecMl+jpSUMnwApdA8Tgy8eB0qELElFBu6cRz+f6Bo06GURXP6eAUbxjteaq3Jy8mV25AMnIrNziSyQ7JOUJ/CEvvOYkLFMWCF6eas8bCQ5SpF6wHoYo/iavMP4ChZaXF754OJ5jEIwhuMetBFXfnHmwkrEIInaF3APIBBCQWL5RC4sJA36yljZCGtzOi5Y2jq81GbnBXN3Dsjvo5h9ZblG4uWfEzA2Uyn0OQNDcrecH3liIpowtGAoq8NUQf89gGwuOvRzzILkeXQ8DKHtWBee5Oi/z7j9DGfv7hTjDBQkh28LbSu9RdtPRwcCweHwTLp4X3CYLwqsxrIP8tlGmrVoZZDhMfyy/bGslZp5Bod2wnOMlvGktkHs="

echo "$SSH_PUB_KEY" >> /home/ubuntu/.ssh/authorized_keys


#############################
### NODE EXPORTER ###
#############################
# Install wget if not already installed
sudo apt install wget -y

# Download and install Node Exporter
NODE_EXPORTER_VERSION="1.5.0"
wget https://github.com/prometheus/node_exporter/releases/download/v$NODE_EXPORTER_VERSION/node_exporter-$NODE_EXPORTER_VERSION.linux-amd64.tar.gz
tar xvfz node_exporter-$NODE_EXPORTER_VERSION.linux-amd64.tar.gz
sudo mv node_exporter-$NODE_EXPORTER_VERSION.linux-amd64/node_exporter /usr/local/bin/
rm -rf node_exporter-$NODE_EXPORTER_VERSION.linux-amd64*

# Create a Node Exporter user
sudo useradd --no-create-home --shell /bin/false node_exporter

# Create a Node Exporter service file
cat << EOF | sudo tee /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, start and enable Node Exporter service
sudo systemctl daemon-reload
sudo systemctl start node_exporter
sudo systemctl enable node_exporter

# Print the public IP address and Node Exporter port
echo "Node Exporter installation complete. It's accessible at http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):9100/metrics"

#############################
### DJANGO SETUP ###
#############################
# Cloning Github Repo
git clone https://github.com/jonwang22/ecommerce_terraform_deployment.git /home/ubuntu/ecommerce_terraform_deployment

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
cd /home/ubuntu/ecommerce_terraform_deployment
python3.9 -m venv venv
source venv/bin/activate

# Building Application
echo "Upgrading PIP..."
pip install --upgrade pip

echo "Installing all necessary application dependencies..."
pip install -r /home/ubuntu/ecommerce_terraform_deployment/backend/requirements.txt

backend_private_ip=$(hostname -i | awk '{print $1}')

# Configuring Allowed Hosts in settings.py
sed -i "s/ALLOWED_HOSTS = \[\]/ALLOWED_HOSTS = \['$backend_private_ip'\]/" /home/ubuntu/ecommerce_terraform_deployment/backend/my_project/settings.py || { echo "Backend Private IP failed to update."; exit 1; }

# Configuring RDS DB information in settings.py
sed -i "s/#'ENGINE': 'django.db.backends.postgresql'/'ENGINE': 'django.db.backends.postgresql'/g" || { echo "Unable to uncomment ENGINE field."; exit 1; }
sed -i "s/#'NAME': 'your_db_name'/'NAME': '${db_name}'/g" /home/ubuntu/ecommerce_terraform_deployment/backend/my_project/settings.py || { echo "DB Name failed to update."; exit 1; }
sed -i "s/#'USER': 'your_username'/'USER': '${db_username}'/g" /home/ubuntu/ecommerce_terraform_deployment/backend/my_project/settings.py || { echo "DB Username failed to update."; exit 1; }
sed -i "s/#'PASSWORD': 'your_password'/'PASSWORD': '${db_password}'/g" /home/ubuntu/ecommerce_terraform_deployment/backend/my_project/settings.py || { echo "DB Password failed to update."; exit 1; }
sed -i "s/#'HOST': 'your-rds-endpoint.amazonaws.com'/'HOST': '${rds_address}'/g" /home/ubuntu/ecommerce_terraform_deployment/backend/my_project/settings.py || { echo "DB Host Address failed to update."; exit 1; }
sed -i "s/#'PORT': '5432'/'PORT': '5432'/g" /home/ubuntu/ecommerce_terraform_deployment/backend/my_project/settings.py || { echo "Unable to uncomment PORT field."; exit 1; }
sed -i "s/#\},/},/g" /home/ubuntu/ecommerce_terraform_deployment/backend/my_project/settings.py || { echo "Unable to uncomment curly bracket."; exit 1; }
sed -i "s/#'sqlite': {/\ 'sqlite': {/g" /home/ubuntu/ecommerce_terraform_deployment/backend/my_project/settings.py || { echo "Unable to uncomment sqlite field."; exit 1; }


# Creating tables in RDS and connecting to RDS
cd /home/ubuntu/ecommerce_terraform_deployment/backend/
python manage.py makemigrations account
python manage.py makemigrations payments
python manage.py makemigrations product
python manage.py migrate

# Start Django Server
mkdir /home/ubuntu/logs
touch /home/ubuntu/logs/myapp.log
python manage.py runserver 0.0.0.0:8000 > /home/ubuntu/logs/myapp.log 2>&1 &