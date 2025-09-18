#!/bin/bash

# Script to make a user an admin by email
# Uses database configuration from setup-dev-postgres.sh
# Usage: ./scripts/make_admin.sh

set -e

echo "Admin User Promotion Script"
echo "==========================="
echo ""

# Database configuration from setup-dev-postgres.sh
DB_HOST="127.0.0.1"
DB_NAME="shard_dev"
DB_USER="shard"
DB_PASSWORD="Chu7eeg0iih2yeiN"

# Prompt for email
read -p "Enter the email address of the user to make admin: " email

# Validate email is not empty
if [ -z "$email" ]; then
    echo "Error: Email cannot be empty"
    exit 1
fi

# Check if user exists and get current admin status
user_check=$(PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT id, admin FROM users WHERE email = '$email';")

if [ -z "$user_check" ]; then
    echo "Error: No user found with email '$email'"
    exit 1
fi

# Parse the result
user_id=$(echo "$user_check" | awk '{print $1}' | tr -d ' ')
is_admin=$(echo "$user_check" | awk '{print $3}' | tr -d ' ')

if [ "$is_admin" = "t" ]; then
    echo "User '$email' is already an admin."
else
    # Update the user to be an admin
    echo "Promoting user '$email' to admin..."
    
    PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -c "UPDATE users SET admin = true, updated_at = NOW() WHERE email = '$email';"
    
    if [ $? -eq 0 ]; then
        echo "Success! User '$email' has been promoted to admin."
    else
        echo "Error: Failed to update user"
        exit 1
    fi
fi

echo "Script completed."
