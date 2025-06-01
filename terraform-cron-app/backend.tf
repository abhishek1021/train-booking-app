# Uncomment this section after the first successful deployment
# to start using remote state management

# terraform {
#   backend "s3" {
#     bucket         = "train-booking-terraform-state"
#     key            = "cron-app/terraform.tfstate"
#     region         = "ap-south-1"
#     dynamodb_table = "terraform-locks"
#     encrypt        = true
#   }
# }
