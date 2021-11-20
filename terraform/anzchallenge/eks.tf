module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = var.cluster_name
  cluster_version = "1.20"
  subnets         = module.vpc.private_subnets

  tags = {
    name = "anzchallenge"
  }

  vpc_id = module.vpc.vpc_id

}

resource "aws_iam_role" "anzchallengenoderole" {
  name = "eks-node-group-anzchallengenoderole"

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
   depends_on            = [module.eks]
}

resource "aws_iam_role_policy_attachment" "anzchallengenoderole-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.anzchallengenoderole.name
  depends_on = [aws_iam_role.anzchallengenoderole]
}

resource "aws_iam_role_policy_attachment" "anzchallengenoderole-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.anzchallengenoderole.name
  depends_on = [aws_iam_role.anzchallengenoderole]
}

resource "aws_iam_role_policy_attachment" "anzchallengenoderole-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.anzchallengenoderole.name
  depends_on = [aws_iam_role.anzchallengenoderole]
}


resource "aws_eks_node_group" "anzchallengenodes" {
  cluster_name    = var.cluster_name
  node_group_name = "anzchallengenodes"
  node_role_arn   = aws_iam_role.anzchallengenoderole.arn
  subnet_ids      = module.vpc.private_subnets
  instance_types  = ["t3.micro"]

  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.anzchallengenoderole-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.anzchallengenoderole-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.anzchallengenoderole-AmazonEC2ContainerRegistryReadOnly,
  ]
}

resource "kubernetes_deployment" "anzchallengepod" {
  metadata {
    name = "anzchallenge-app"
    labels = {
      app = "anzchallenge-app"
    }
  }
  spec {
      replicas = 2
      selector {
      match_labels = {
        app = "anzchallenge-app"
      }
    }
    template {
      metadata {
        labels = {
          app = "anzchallenge-app"
        }
      }
  
  spec {
    container {
      image = var.container_image_name
      name  = "anzchallenge-app"
      image_pull_policy = "Always"
      port {
        container_port = 8085
      }
      }
    }
    }
  }
    depends_on  = [aws_eks_node_group.anzchallengenodes]
}

resource "kubernetes_service" "anzchallenge-service" {
  metadata {
    name = "anzchallenge-service"
  }
  spec {
    selector = {
      app = kubernetes_deployment.anzchallengepod.metadata.0.labels.app
    }
    port {
      port        = 80
      target_port = 8085
    }
    type = "LoadBalancer"
}
depends_on  = [kubernetes_deployment.anzchallengepod]
}


data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}
