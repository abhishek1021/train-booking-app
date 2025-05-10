#!/bin/bash
# Destroys only the mock JSON server resources (and its dependencies) using Terraform
# Do NOT run this script from the backend/infra root, only from mockjson directory
# Usage: bash destroy-mockjson.sh

set -e

echo "Destroying mock JSON server resources..."
terraform init
terraform destroy -auto-approve

echo "Mock JSON server resources destroyed."
