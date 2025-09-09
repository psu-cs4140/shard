#!/bin/bash

# Script to configure PostgreSQL for local development
# Sets up password authentication for local connections and creates shard user

set -e # Exit on any error

# Configuration
PG_HBA_FILE="/etc/postgresql/16/main/pg_hba.conf"
POSTGRES_SERVICE="postgresql"
USERNAME="shard"
PASSWORD="Chu7eeg0iih2yeiN"

echo "Setting up PostgreSQL for development..."

# Check if running as root (required for editing config and restarting service)
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root"
    exit 1
fi

# Check if PostgreSQL is installed
if ! command -v psql &>/dev/null; then
    echo "PostgreSQL is not installed. Please install it first."
    exit 1
fi

# Backup the original pg_hba.conf file
echo "Backing up pg_hba.conf..."
cp "$PG_HBA_FILE" "${PG_HBA_FILE}.backup"

# Check if local network connections with password auth are already enabled
if grep -q "host.*all.*all.*127.0.0.1/32.*md5" "$PG_HBA_FILE"; then
    echo "Local network connections with password auth already enabled"
else
    echo "Enabling local network connections with password authentication..."

    # Add or modify the line for local connections to use md5 (password) authentication
    # First, comment out any existing conflicting lines
    sed -i 's/^\(host.*all.*all.*127.0.0.1\/32\)/#\1/' "$PG_HBA_FILE"

    # Add the new line for password authentication
    echo "host    all             all             127.0.0.1/32            md5" >>"$PG_HBA_FILE"

    # Also handle IPv6 localhost
    if grep -q "host.*all.*all.*::1/128.*md5" "$PG_HBA_FILE"; then
        echo "IPv6 local connections already configured"
    else
        sed -i 's/^\(host.*all.*all.*::1\/128\)/#\1/' "$PG_HBA_FILE"
        echo "host    all             all             ::1/128                 md5" >>"$PG_HBA_FILE"
    fi
fi

# Restart PostgreSQL to apply configuration changes
echo "Restarting PostgreSQL service..."
systemctl restart "$POSTGRES_SERVICE"

# Wait a moment for the service to fully start
sleep 2

# Check if the shard user already exists
if sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='$USERNAME'" | grep -q 1; then
    echo "User $USERNAME already exists"
else
    echo "Creating PostgreSQL user: $USERNAME"
    sudo -u postgres psql -c "CREATE USER $USERNAME WITH PASSWORD '$PASSWORD';"
fi

# Grant the user database creation privileges
echo "Granting database creation privileges to $USERNAME"
sudo -u postgres psql -c "ALTER USER $USERNAME CREATEDB;"

echo "PostgreSQL setup complete!"
echo "You should now be able to run 'mix ecto.create' to create the database."
