#!/bin/bash

# Configuration
DB_INSTANCE_IDENTIFIER="mydbinstance"  # Replace with your DB instance identifier
REGION="us-east-1"                    # Replace with your AWS region
AWS_PROFILE="default"                 # Replace with your AWS CLI profile (optional)

# Set AWS CLI profile (if specified)
if [ -n "$AWS_PROFILE" ]; then
  export AWS_PROFILE=$AWS_PROFILE
fi

# Function to check if the DB instance exists
check_db_instance() {
  aws rds describe-db-instances \
    --db-instance-identifier "$DB_INSTANCE_IDENTIFIER" \
    --region "$REGION" >/dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo "Error: DB instance $DB_INSTANCE_IDENTIFIER does not exist in region $REGION."
    exit 1
  fi
}

# Function to check and disable deletion protection
disable_deletion_protection() {
  DELETION_PROTECTION=$(aws rds describe-db-instances \
    --db-instance-identifier "$DB_INSTANCE_IDENTIFIER" \
    --region "$REGION" \
    --query 'DBInstances[0].DeletionProtection' \
    --output text)
  
  if [ "$DELETION_PROTECTION" == "true" ]; then
    echo "Disabling deletion protection for $DB_INSTANCE_IDENTIFIER..."
    aws rds modify-db-instance \
      --db-instance-identifier "$DB_INSTANCE_IDENTIFIER" \
      --no-deletion-protection \
      --apply-immediately \
      --region "$REGION"
    
    # Wait for modification to complete
    aws rds wait db-instance-modified \
      --db-instance-identifier "$DB_INSTANCE_IDENTIFIER" \
      --region "$REGION"
    echo "Deletion protection disabled."
  else
    echo "Deletion protection is already disabled."
  fi
}

# Function to delete the DB instance
delete_db_instance() {
  echo "Deleting DB instance $DB_INSTANCE_IDENTIFIER..."
  aws rds delete-db-instance \
    --db-instance-identifier "$DB_INSTANCE_IDENTIFIER" \
    --skip-final-snapshot \
    --delete-automated-backups \
    --region "$REGION"
  
  if [ $? -eq 0 ]; then
    echo "Deletion request submitted. Waiting for DB instance to be deleted..."
    aws rds wait db-instance-deleted \
      --db-instance-identifier "$DB_INSTANCE_IDENTIFIER" \
      --region "$REGION"
    echo "DB instance $DB_INSTANCE_IDENTIFIER deleted successfully."
  else
    echo "Error: Failed to delete DB instance $DB_INSTANCE_IDENTIFIER."
    exit 1
  fi
}

# Main script
echo "Starting RDS DB instance deletion process..."

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
  echo "Error: AWS CLI is not installed. Please install it and configure credentials."
  exit 1
fi

# Check if the DB instance exists
check_db_instance

# Disable deletion protection if enabled
disable_deletion_protection

# Delete the DB instance
delete_db_instance

echo "Process completed."
