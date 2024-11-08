#!/bin/bash

LOGFILE="/var/log/ckan/install.log"

source .env

set -e

check_env_vars() {
    required_vars=("CKAN_DB_PASSWORD" "CKAN_SITE_URL" "CKAN_SYSADMIN_NAME")
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            echo "Error: $var is not set in .env file"
            exit 1
        fi
    done
}

is_installed() {
    dpkg -l | grep -q "$1"
}

install_dependencies() {
    echo "Updating package list and installing dependencies..."
    sudo apt update
    sudo apt install -y libpq5 redis-server nginx supervisor postgresql wget
}

install_ckan() {
    echo "Checking if CKAN package is already downloaded..."
    if [ ! -f python-ckan_2.11-jammy_amd64.deb ]; then
        echo "Downloading CKAN package..."
        wget https://packaging.ckan.org/python-ckan_2.11-jammy_amd64.deb
    else
        echo "CKAN package already exists. Skipping download."
    fi

    if dpkg -l | grep -q python-ckan; then
        echo "CKAN is already installed. Uninstalling it first."
        sudo dpkg -r python-ckan
    fi

    echo "Installing CKAN package..."
    sudo dpkg -i python-ckan_2.11-jammy_amd64.deb
}

setup_postgresql() {
    echo "Setting up PostgreSQL database..."

    echo "Dropping CKAN related databases..."
    sudo -u postgres psql -c "DROP DATABASE IF EXISTS datastore_default;"
    sudo -u postgres psql -c "DROP ROLE IF EXISTS datastore_default;"
    sudo -u postgres psql -c "DROP DATABASE IF EXISTS ckan_default;"
    
    echo "Dropping CKAN related role..."
    sudo -u postgres psql -c "DROP ROLE IF EXISTS ckan_default;"

    CKAN_DB_PASSWORD=$CKAN_DB_PASSWORD
    
    sudo -u postgres psql -c "CREATE ROLE ckan_default WITH LOGIN PASSWORD '$CKAN_DB_PASSWORD';"
    sudo -u postgres createdb -O ckan_default ckan_default -E utf8
}

setup_ckan_directories() {
    echo "Setting up CKAN directories and permissions..."
    sudo mkdir -p /var/lib/ckan/default
    sudo chown www-data /var/lib/ckan/default
    sudo chmod u+rwx /var/lib/ckan/default
}

update_ckan_config() {
    echo "Updating CKAN configuration file..."

    CKAN_INI="/etc/ckan/default/ckan.ini"

    sudo sed -i "s|sqlalchemy.url = postgresql://ckan_default:pass@localhost/ckan_default|sqlalchemy.url = postgresql://ckan_default:${CKAN_DB_PASSWORD}@localhost/ckan_default|" $CKAN_INI
    sudo sed -i "s|ckan.site_url = .*|ckan.site_url = ${CKAN_SITE_URL}|" $CKAN_INI
    sudo sed -i 's|ckan.auth.route_after_login = dashboard.datasets|ckan.auth.route_after_login = home.index|' "$CKAN_INI"

    echo "Configuration file updated."
}

initialise_solr() {
    echo "Initialising Solr..."
    
    # Check if a container named 'ckan-solr' is already running
    if [ "$(sudo docker ps -q -f name=ckan-solr)" ]; then
        echo "Solr is already running."
    else
        # Check if a container named 'ckan-solr' exists but is stopped
        if [ "$(sudo docker ps -a -q -f name=ckan-solr)" ]; then
            echo "Removing stopped Solr container..."
            sudo docker rm ckan-solr
        fi
        
        sudo docker run --name ckan-solr -p 8983:8983 -d ckan/ckan-solr:2.10-solr9
        
        # Wait until the container is running
        while [ -z "$(sudo docker ps -q -f name=ckan-solr)" ]; do
            echo "Waiting for Solr container to start..."
            sleep 2
        done
        echo "Solr container has started."
    fi
}

initialize_ckan_db() {
    echo "Initializing CKAN database..."
    sudo ckan db init
}

# Fix SQL errors (optional step) this can be removed for other versions of Ubuntu
fix_sql_errors() {
    echo "Fixing SQL errors..."
    sudo -u postgres psql ckan_default -c "ALTER TABLE activity ADD COLUMN permission_labels TEXT[];"
}

restart_services() {
    echo "Restarting Supervisor and Nginx services..."
    sudo supervisorctl reload
    sudo service nginx restart
}

setup_sysadmin() {
    SYSADMIN_NAME=$CKAN_SYSADMIN_NAME
    sudo ckan sysadmin add $SYSADMIN_NAME
}

# Add after set -e
LOGFILE="/var/log/ckan/install.log"

cleanup() {
    local exit_code=$?
    echo "Cleanup triggered with exit code: $exit_code"
    
    if [ $exit_code -ne 0 ]; then
        echo "[$(date)] Installation failed with exit code $exit_code" | sudo tee -a "$LOGFILE"
        
        # Stop running services
        sudo service nginx stop 2>/dev/null
        sudo supervisorctl stop all 2>/dev/null
        
        # Remove partial installations
        if dpkg -l | grep -q python-ckan; then
            sudo dpkg -r python-ckan
        fi
        
        # Clean up Solr container
        if [ "$(sudo docker ps -q -f name=ckan-solr)" ]; then
            sudo docker stop ckan-solr
            sudo docker rm ckan-solr
        fi
        
        echo "Cleanup completed. Check $LOGFILE for details"
    else
        echo "[$(date)] Installation completed successfully" | sudo tee -a "$LOGFILE"
    fi
}

trap cleanup EXIT


main() {
    check_env_vars
    
    sudo mkdir -p /var/log/ckan
    
    install_dependencies || exit 1
    install_ckan || exit 1
    setup_postgresql || exit 1
    setup_ckan_directories || exit 1
    update_ckan_config || exit 1
    initialise_solr || exit 1
    sleep 10
    initialize_ckan_db || exit 1
    fix_sql_errors || exit 1
    setup_sysadmin || exit 1
    restart_services || exit 1

    echo "CKAN installation and setup complete!"
}

main "$@"