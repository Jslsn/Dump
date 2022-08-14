#The providers tf file, this file defines the provider we're using.
provider "aws" {
  region = "eu-west-1"
}

provider "tls" {}

provider "local" {}
