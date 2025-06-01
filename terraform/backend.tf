terraform {
  backend "s3" {
    bucket         = "train-booking-terraform-state"
    key            = "terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
