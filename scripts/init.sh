#!/bin/bash

set -e

# Check if Frappe Bench already exists
if [[ -f "/workspaces/frappe_codespace/frappe-bench/apps/frappe" ]]
then
    echo "Bench already exists, skipping init"
    exit 0
fi

# Remove existing git repository to avoid conflicts
rm -rf /workspaces/frappe_codespace/.git

# Source NVM for Node Version Manager
source /home/frappe/.nvm/nvm.sh
nvm alias default 18
nvm use 18

echo "nvm use 18" >> ~/.bashrc

# Navigate to the workspace directory
cd /workspace

# Initialize Frappe Bench (with version 15)
bench init \
--ignore-exist \
--skip-redis-config-generation \
--frappe-branch version-15 \
frappe-bench

# Navigate to the Frappe Bench directory
cd frappe-bench

# Configure the Bench to use containers instead of localhost
bench set-mariadb-host mariadb
bench set-redis-cache-host redis-cache:6379
bench set-redis-queue-host redis-queue:6379
bench set-redis-socketio-host redis-socketio:6379

# Remove redis from Procfile
sed -i '/redis/d' ./Procfile

# Create a new site
bench new-site dev.localhost \
--mariadb-root-password 123 \
--admin-password admin \
--no-mariadb-socket

# Enable developer mode for the site
bench --site dev.localhost set-config developer_mode 1
bench --site dev.localhost clear-cache

# Use the created site
bench use dev.localhost

# Install ERPNext version 15
#bench get-app --branch version-15 --resolve-deps erpnext
bench get-app https://github.com/frappe/hrms.git

# Install the apps on the site
#bench --site dev.localhost install-app erpnext
bench --site dev.localhost install-app hrms

# Optional: Rebuild assets and restart the server
bench upgrade --patch
bench restart

echo "Frappe version 15 completed!"
