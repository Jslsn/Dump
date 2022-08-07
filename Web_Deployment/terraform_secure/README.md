# Jordan's basic Web Deployment(https edition)

This directory allows you to deploy the site with an enforced secure connection through https.

## For Deployment

### Requirments
- Terraform on your local environment.
- AWS Account.
- An existing, valid aws acm certificate.
- A Route53 Hosted Zone that the certificate belongs to.

### Deploying
To Deploy:
- Run a "terraform init" in this directory.
- Run "terraform apply" and enter the domain the acm certificate belongs to :smile: