#!/bin/bash

set -euo pipefail

cluster_name=$(terraform output -raw eks-cluster-name) 

terraform destroy --auto-approve 

kubectl config delete-context "${cluster_name}" 
