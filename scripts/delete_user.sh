#!/bin/bash

# Script to delete a user by email
# Uses database configuration from setup-dev-postgres.sh
# Usage: ./scripts/delete_user.sh

set -e

echo "User Deletion Script"
echo "==================="
echo ""
echo "WARNING: This will permanently delete the user and all associated data!"
echo ""

# Database configuration from setup-dev-postgres.sh
DB_HOST="127.0.0.1"
DB_NAME="shard_dev"
DB_USER="shard"
DB_PASSWORD="Chu7eeg0iih2yeiN"

# Prompt for email
read -p "Enter the email address of the user to delete: " email

# Validate email is not empty
if [ -z "$email" ]; then
    echo "Error: Email cannot be empty"
    exit 1
fi

# Check if user exists and get user info
user_info=$(PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT id, email, admin FROM users WHERE email = '$email';")

if [ -z "$user_info" ]; then
    echo "Error: No user found with email '$email'"
    exit 1
fi

# Parse the result
user_id=$(echo "$user_info" | awk '{print $1}' | tr -d ' ')
user_email=$(echo "$user_info" | awk '{print $3}' | tr -d ' ')
is_admin=$(echo "$user_info" | awk '{print $5}' | tr -d ' ')

echo "Found user:"
echo "  ID: $user_id"
echo "  Email: $user_email"
echo "  Admin: $is_admin"
echo ""

# Get character count for this user
character_count=$(PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM characters WHERE user_id = $user_id;")
character_count=$(echo "$character_count" | tr -d ' ')

if [ "$character_count" -gt 0 ]; then
    echo "This user has $character_count character(s) that will also be deleted."
fi

echo ""
read -p "Are you sure you want to delete this user? Type 'DELETE' to confirm: " confirmation

if [ "$confirmation" != "DELETE" ]; then
    echo "Deletion cancelled."
    exit 0
fi

echo ""
echo "Deleting user and associated data..."

# Delete characters first (due to foreign key constraint)
if [ "$character_count" -gt 0 ]; then
    echo "Deleting $character_count character(s)..."
    PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -c "DELETE FROM characters WHERE user_id = $user_id;"
fi

# Delete user tokens
echo "Deleting user tokens..."
PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -c "DELETE FROM users_tokens WHERE user_id = $user_id;"

# Delete the user
echo "Deleting user..."
PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -c "DELETE FROM users WHERE id = $user_id;"

if [ $? -eq 0 ]; then
    echo "Success! User '$email' and all associated data have been deleted."
else
    echo "Error: Failed to delete user"
    exit 1
fi

echo "Script completed."
