provider "aws" {
  region     = var.region
  access_key = data.onepassword_item.aws_credentials.username
  secret_key = data.onepassword_item.aws_credentials.credential
}

provider "onepassword" {
  connect_url   = var.onepassword_endpoint
  connect_token = var.onepassword_token
}
