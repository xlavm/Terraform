# Author: Luis Angel Vanegas Martinez (xlavm)
# Version: 1.0

variable "access_key" {}
variable "secret_key" {}
variable "region" {}

# DEFINE PROVIDER
provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region     = var.region
}
