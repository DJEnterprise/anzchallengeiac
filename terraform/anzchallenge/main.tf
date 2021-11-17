data "aws_availability_zones" "available" {}

locals {
  cluster_name = "anzchallenge-eks-cluster"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.2.0"

  name                 = "anzchallenge-vpc"
  cidr                 = "10.0.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets       = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = local.cluster_name
  cluster_version = "1.20"
  subnets         = module.vpc.private_subnets

  tags = {
    name = "anzchallenge"
 
  }

  vpc_id = module.vpc.vpc_id

}

resource "aws_iam_role" "anzchallenge_eks_role" {
  name = "anzchallenge-eks-fargate-profile-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks-fargate-pods.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "anzchallenge-AmazonEKSFargatePodExecutionRolePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.anzchallenge_eks_role.name
}

resource "aws_eks_fargate_profile" "anzchallenge-eks-fargate-profile" {
  cluster_name           = local.cluster_name
  fargate_profile_name   = "anzchallenge-eks-fargate-profile"
  pod_execution_role_arn = aws_iam_role.anzchallenge_eks_role.arn
  subnet_ids             = module.vpc.private_subnets

  selector { 
    namespace = "fargatenamespace"
  }
  depends_on            = [module.eks]
}

resource "kubernetes_pod" "anzchallenge_pod" {
  metadata {
    name = "anzchallenge_app"
    labels{
        App = "anzchallenge_app"
    }
  }
  spec {
    container {
      image = "621255284514.dkr.ecr.ap-southeast-2.amazonaws.com/mydockerrepo:latest"
      name  = "anzchallenge_app"

      port {
        container_port = 8085
      }
      }
    }
    depends_on  = [aws_eks_fargate_profile.anzchallenge-eks-fargate-profile]
}

resource "kubernetes_service" "anzchallenge_service" {
  metadata {
    name = "anzchallenge_service"
  }
  spec {
    selector {
      App = "${kubernetes_pod.anzchallenge_pod.metadata.0.labels.App}"
    }
    port {
      port        = 80
      target_port = 8085
    }
    type = "LoadBalancer"
}
depends_on  = [kubernetes_pod.anzchallenge_pod]
}


data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}
