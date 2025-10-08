#!/bin/bash

########################################################
# Author: Vaibhav Umbarkar
# Version: v1.0
# Description: This script automates the deployment of infrastructure using Terraform.
########################################################

set -e
LOG_FILE="deployment_$(date +%F_%T).log"

echo "[INFO] Starting deployment..." | tee -a $LOG_FILE

# Check dependencies
for cmd in terraform aws; do
    if ! command -v $cmd &>/dev/null; then
        echo "[ERROR] $cmd is not installed. Please install it and try again." | tee -a $LOG_FILE
        exit 1
    fi
done

# Initialize Terraform
echo "[INFO] Initializing Terraform..." | tee -a $LOG_FILE
terraform init | tee -a $LOG_FILE

# Validate Terraform Configuration
echo "[INFO] Validating Terraform configuration..." | tee -a $LOG_FILE
terraform validate | tee -a $LOG_FILE

# Plan Terraform Deployment
echo "[INFO] Planning Terraform deployment..." | tee -a $LOG_FILE
terraform plan -out=tfplan | tee -a $LOG_FILE

# Apply Terraform deployment
echo "[INFO] Applying Terraform deployment..." | tee -a $LOG_FILE
terraform apply -auto-approve tfplan | tee -a $LOG_FILE 

# Output
echo "[INFO] Fetching output..." | tee -a $LOG_FILE
terraform output | tee -a $LOG_FILE