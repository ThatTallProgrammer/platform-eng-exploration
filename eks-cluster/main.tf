provider "aws" {
  region = var.region
}

# Filter out local zones, which are not currently supported 
# with managed node groups
data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  cluster_name = "testing-eks-${random_string.suffix.result}"
  subnet_ids = [
    "subnet-87b14889", 
    "subnet-c08e598d"
  ]
  instance_types = [
    "t3.medium"
  ]
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_eks_cluster" "test-cluster" {
  name = local.cluster_name

  access_config {
    authentication_mode = "API"
  }

  role_arn = aws_iam_role.cluster.arn
  version  = "1.36"

  vpc_config {
    endpoint_private_access = true
    endpoint_public_access  = true

    subnet_ids = local.subnet_ids
  }

  # Ensure that IAM Role permissions are created before and deleted
  # after EKS Cluster handling. Otherwise, EKS will not be able to
  # properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
  ]
}

resource "aws_iam_role" "cluster" {
  name = "eks-cluster"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

resource "aws_eks_node_group" "ng-1" {
  cluster_name    = aws_eks_cluster.test-cluster.name
  node_group_name = "ng-1"
  node_role_arn   = aws_iam_role.eks-node-group.arn
  subnet_ids      = local.subnet_ids

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  instance_types = local.instance_types

  ami_type = "BOTTLEROCKET_x86_64"

  update_config {
    max_unavailable = 1
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.ng-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.ng-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.ng-AmazonEC2ContainerRegistryReadOnly,
  ]
}

resource "aws_iam_role" "eks-node-group" {
  name = "eks-node-group"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "ng-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks-node-group.name
}

resource "aws_iam_role_policy_attachment" "ng-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks-node-group.name
}

resource "aws_iam_role_policy_attachment" "ng-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks-node-group.name
}
