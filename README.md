Infrastructure as code to deploy anzchallenge app to EKS
=============

1. This repo will build Infrastructure in AWS and deploys and runs anzchallenge api in EKS through Terraform.

2. This repo creates and configures EC2 nodes to deploy and run the app in EKS cluster. Fargate is another option to host the app in EKS but decided to proceed with EC2 Nodes considering cost and additional resources required for Fargate.

Requirements
---------

