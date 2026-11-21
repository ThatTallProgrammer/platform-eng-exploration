output "region" {
  description = "AWS region"
  value       = var.region
}

output "eks-cluster-name" {
  description = "Name of the EKS cluster"
  value = aws_eks_cluster.test-cluster.name
}