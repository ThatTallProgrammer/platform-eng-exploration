#!/bin/bash

set -euo pipefail

terraform apply -auto-approve

region=$(terraform output -raw region)
cluster_name=$(terraform output -raw eks-cluster-name)

aws eks update-kubeconfig --region "${region}" --name "${cluster_name}"
