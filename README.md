Infrastructure as code to deploy anzchallenge app to EKS
=============

1. This repo will build Infrastructure in AWS and deploys and runs anzchallenge api in EKS through Terraform.

2. This repo creates VPC, Subnets, EKS Cluster and configures EC2 nodes to deploy and run the app in EKS cluster. Fargate is another option to host the app in EKS but decided to proceed with EC2 Nodes considering the cost and additional resources required for Fargate.

Requirements
---------

1. Requires S3 Bucket to initialize the Terraform State file in S3 Bucket
2. Need to pass the variable file (nonprod.tfvars / prod.tfvars) based on the environment and docker image name to be deployed on EKS

Terraform Init
------
cd terraform/anzchallenge

terraform init -backend-config=bucket=${S3_BUCKET_NAME} -backend-config=key=anzchallenge/app.tfstate -backend-config=region=${REGION_NAME}

Terraform Plan
-------
cd terraform/anzchallenge

terraform plan -var-file=\"nonprod.tfvars\" -var container_image_name=${DOCKER_IMAGE_URL}

Terraform Apply
-------
cd terraform/anzchallenge

terraform apply -var-file=\"nonprod.tfvars\" -var container_image_name=${DOCKER_IMAGE_URL}

