# Comment out the S3 backend initially until the DynamoDB table is created
# After running 'terraform apply' once with local state, you can uncomment this section
# and run 'terraform init' with the -migrate-state flag to move the state to S3

# The S3 bucket already exists, but we still need to create the DynamoDB table first
# terraform {
#   backend "s3" {
#     bucket         = "train-booking-terraform-state"
#     key            = "terraform.tfstate"
#     region         = "ap-south-1"
#     dynamodb_table = "terraform-locks"
#     encrypt        = true
#   }
# }
