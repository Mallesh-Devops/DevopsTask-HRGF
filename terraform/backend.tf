terraform {
  backend "s3" {
    # Your DigitalOcean Spaces bucket endpoint
    # endpoint                    = "https://sgp1.digitaloceanspaces.com"  
    # bucket                      = "terraform-devopstask"        
    # key                         = "k8s-cluster/terraform.tfstate"
    region                      = "us-east-1"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    
    # Credentials are set via environment variables:
    # AWS_ACCESS_KEY_ID - Set to your DigitalOcean Spaces Access Key
    # AWS_SECRET_ACCESS_KEY - Set to your DigitalOcean Spaces Secret Key
  }
}
