#!/bin/bash

# Environment variables
ENVIRONMENT=$1

check_num_of_args() {
# Checking the number of arguments
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <environment>"
    exit 1
fi
}

activate_infra_environment() {
# Acting based on the argument value
if [ "$ENVIRONMENT" == "local" ]; then
  echo "Running script for Local Environment..."
elif [ "$ENVIRONMENT" == "testing" ]; then
  echo "Running script for Testing Environment..."
elif [ "$ENVIRONMENT" == "production" ]; then
  echo "Running script for Production Environment..."
else
  echo "Invalid environment specified. Please use 'local', 'testing', or 'production'."
  exit 2
fi
}

# Function to check if AWS CLI is installed
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        echo "AWS CLI is not installed. Please install it before proceeding."
        return 1
    fi
}

# Function to check if AWS profile is set
check_aws_profile() {
    if [ -z "$AWS_PROFILE" ]; then
        echo "AWS profile environment variable is not set."
        return 1
    fi
}

# Function to create EC2 Instances in Amazon Linux, Ubuntu and Centos
create_ec2_instances() {
	# Array of ami-id
	AMIS=("ami-0c55b159cbfafe1f0" "ami-0d5eff06f840b45e9" "ami-0cfe02c7ff480b5b2")
	# Array of instance name
	INSTANCE_NAMES=("AmazonLinux" "Ubuntu" "CentOS")

	#Loop through the array and create each instances
	for ((i=0; i<${#AMIS[@]}; i++)) do
	
		# Create the EC2 instances
    		aws ec2 run-instances \
        	--image-id "${AMIS[$i]}" \
        	--instance-type t2.micro \
        	--count 1 \
        	--key-name MyKeyPair \
		--tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${INSTANCE_NAMES[$i]}]"
        
    		# Check if the EC2 instances were created successfully
    		if [ $? -eq 0 ]; then
        		echo "EC2 instances '${INSTANCE_NAMES[$i]}' created successfully."
    		else
        		echo "Failed to create EC2 instances '${INSTANCE_NAMES[$i]}'."
    		fi
	done
}

#Function to deploy apache and sample web page
deploy_apache_samplepage () {
	 local instance_ip=$1
	 #Loop the instance_ip and deploy apache and sample-webpage
	 for instance_ip in $(aws ec2 describe-instances --query 'Reservations[*].Instances[*].PublicIpAddress' --output text); do
		 ssh -i /path/to/your/key.pem ec2-user@"$instance_ip" "sudo yum install -y httpd && sudo systemctl start httpd && sudo systemctl enable httpd"
		 ssh -i /path/to/your/key.pem ec2-user@"$instance_ip" "echo '<html><body><h1>Hello, World!</h1></body></html>' | sudo tee /var/www/html/index.html"

		# Check if it has been deployed
		if [ $? -eq 0 ]; then
			echo "Apache and Samplewebpage for '$instance_ip' succesfully deployed"
		else
			echo "Failed to deploy for '$instance_ip'."
		fi
	done
}

# Function to create S3 buckets for different departments
create_s3_buckets() {
    # Define a company name as prefix
    company="datawise"
    # Array of department names
    departments=("Marketing" "Sales" "HR" "Operations" "Media")
    
    # Loop through the array and create S3 buckets for each department
    for department in "${departments[@]}"; do
        bucket_name="${company}-${department}-Data-Bucket"
        # Create S3 bucket using AWS CLI
        aws s3api create-bucket --bucket "$bucket_name" --region your-region
        if [ $? -eq 0 ]; then
            echo "S3 bucket '$bucket_name' created successfully."
        else
            echo "Failed to create S3 bucket '$bucket_name'."
        fi
    done
}

# Script Enhancement to include IAM

# Function to create IAM users
create_iam_users () {
	# Define iam user name array
	IAM_USERS=("userA" "userB" "userC" "userD" "userE")
	#Loop through the array and create the iam users
	for user in "${IAM_USERS[@]}"; do
		aws iam create-user --user-name "$user"
		if [$? -eq 0 ]; then
			echo "iam users '$user' created successfully."
		else
			echo "Failed to create iam users '$users'."
		fi
	done
}

# Function to create IAM group and attach policy
create_iam_group () {
	# Define group name
	IAM_GROUP="AdminGroup"
	# Create group
	aws iam create-group --group-name "$IAM_GROUP"
	# Attach administrative policy
	aws iam attach-group-policy --group-name "$IAM_GROUP" --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
	# Check if group was created
	if [$? -eq 0]; then
		echo "iam group '$IAM_GROUP' created successfully."
	else
		echo "Failed to create iam group '$IAM_GROUP'."
	fi
}
# Function to assign user to group
assign_user_group () {
	#Loop through the array of users and assign to group
	for user in "${IAM_USERS[@]}"; do
		aws iam add-user-to-group --group-name "$IAM_GROUP" --user-name "$user"
		# Check if user was added
		if [$? -eq 0]; then
			echo "user '$user' successfully added to group '$IAM_GROUP'."
		else
			echo "Failed to add user '$user' to group '$IAM_GROUP'."
		fi
	done
}

check_num_of_args
activate_infra_environment
check_aws_cli
check_aws_profile
create_ec2_instances
deploy_apache_samplepage
create_s3_buckets
create_iam_users
create_iam_group
assign_user_group
