# Terraform

## Prerrequisites

AWS
```bash
# install AWS CLI
sudo apt-get install awscli

# verificate the installation
aws --version
```

## Install

```bash
# update packages 
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common curl

# add the HashiCorp GPG key.
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -

# add the official HashiCorp Linux repository.
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"

# update to add the repository, and install the Terraform CLI.
sudo apt-get update && sudo apt-get install terraform

# verificate the installation
terraform -help

```

## Executing 

```bash
# init the project
terraform init

# format file
terraform fmt

# validate format
terraform validate

# see what will be implemented
terraform plan

# executing script
terraform apply -auto-approve

# inspect state
terraform show

# list resources of main.tf
terraform state list

# destroy infrastructure
terraform destroy -auto-approve
```

taked of: https://learn.hashicorp.com/collections/terraform/aws-get-started



# single-infra.tf

Single infra in AWS 

take of: https://registry.terraform.io/providers/hashicorp/aws/latest/docs

## Executing Local

create the file in the principal path and into multi-infra path `terraform.tfvars` whit the next content:

```TF
access_key  = "<YOUR_AWS_ACCESS_KEY_ID>"
secret_key  = "<YOUR_AWS_SECRET_ACCESS_KEY>"
region      = "<YOUR_AWS_REGION>"
```

execute in the command line:

```bash
# init
terraform init

# executing script
terraform apply -auto-approve
```

or for executing multi-infra:

```bash
# go to dir
cd multi-infra

# init
terraform init

# executing script
terraform apply -auto-approve
```


## infrastructure proposal
