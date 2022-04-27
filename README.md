# Terraform

## Prerrequisites

AWS
```bash
sudo apt-get install awscli

aws --version

aws configure

aws configure list
```

## Install

```bash
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common curl

curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -

sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"

sudo apt-get update && sudo apt-get install terraform

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
# executing script
terraform apply -auto-approve
# inspect state
terraform show
# list resources of main.tf
terraform state list
```

taked of: https://learn.hashicorp.com/collections/terraform/aws-get-started