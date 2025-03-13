terraform {
  backend "s3" {
    bucket = "mybucket.mustafa.flm" # Replace with your actual S3 bucket name
    key    = "eks-project/terraform.tfstate"
    region = "us-east-1"
  }
}
