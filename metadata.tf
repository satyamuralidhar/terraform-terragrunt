#note update the ami id on dev/enviroment.yaml
# terragrunt fmt 
# terragrunt plan
# terragrunt apply -var "aws_access_key=$AWS_ACCESS_KEY" -var "aws_secret_key=$AWS_SECRET_KEY" --auto-approve
# terragrunt destroy -var "aws_access_key=$AWS_ACCESS_KEY" -var "aws_secret_key=$AWS_SECRET_KEY" --auto-approve