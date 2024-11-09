#!/bin/bash

if [ -f .env ]; then
    source .env
else
    echo "Error: .env file not found"
    exit 1
fi

check_env_vars() {
    required_vars=(
        "CKAN_DB_PASSWORD"
        "CKAN_SITE_URL"
        "CKAN_SYSADMIN_NAME"
        "API_KEY"
        "CKAN_SMTP_SERVER"
        "CKAN_SMTP_STARTTLS"
        "CKAN_SMTP_USER"
        "CKAN_SMTP_PASSWORD"
        "CKAN_SMTP_MAIL_FROM"
    )

    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            echo "Error: Required environment variable $var is not set"
            exit 1
        fi
    done
    echo "Environment variables validated successfully"
}

setup_datastore() {
    echo "Setting up datastore..."

    echo "Dropping existing datastore database and user..."

    sudo -u postgres psql -c "DROP DATABASE IF EXISTS datastore_default;"
    sudo -u postgres psql -c "DROP ROLE IF EXISTS datastore_default;"

    sudo -u postgres psql -c "CREATE ROLE datastore_default WITH LOGIN PASSWORD E'${CKAN_DB_PASSWORD}';"
    
    sudo -u postgres createdb -O ckan_default datastore_default -E utf-8
    
    echo "Updating CKAN configuration..."
    CKAN_INI=/etc/ckan/default/ckan.ini

    sudo sed -i "s|sqlalchemy.url = postgresql://ckan_default:pass@localhost/ckan_default|sqlalchemy.url = postgresql://ckan_default:${CKAN_DB_PASSWORD}@localhost/ckan_default|" $CKAN_INI

    if ! grep -q "^ckan.datastore.write_url" "$CKAN_INI"; then
        sudo sed -i "/sqlalchemy.url/a ckan.datastore.write_url = postgresql://ckan_default:${CKAN_DB_PASSWORD}@localhost/datastore_default" $CKAN_INI
        echo "Added datastore write_url configuration"
    else
        echo "Datastore write_url already exists"
    fi

    if ! grep -q "^ckan.datastore.read_url" "$CKAN_INI"; then
        sudo sed -i "/ckan.datastore.write_url/a ckan.datastore.read_url = postgresql://datastore_default:${CKAN_DB_PASSWORD}@localhost/datastore_default" $CKAN_INI
        echo "Added datastore read_url configuration"
    else
        echo "Datastore read_url already exists"
    fi

    if ! grep -q "ckan.plugins.*datastore" "$CKAN_INI"; then
        sudo sed -i '/^ckan.plugins[[:space:]]*=/ s/$/ datastore/' "$CKAN_INI"
        echo "Added datastore plugin to CKAN plugins"
    else
        echo "Datastore plugin is already in CKAN plugins list"
    fi
    echo "Setting datastore permissions..."
    sudo ckan datastore set-permissions | sudo -u postgres psql --set ON_ERROR_STOP=1
    echo "Datastore setup completed successfully"
}

setup_email_settings() {
    echo "Configuring email settings..."
    sudo sed -i "s|^smtp.server.*|smtp.server = ${CKAN_SMTP_SERVER}|" $CKAN_INI
    sudo sed -i "s|^smtp.starttls.*|smtp.starttls = ${CKAN_SMTP_STARTTLS}|" $CKAN_INI
    sudo sed -i "s|^smtp.user.*|smtp.user = ${CKAN_SMTP_USER}|" $CKAN_INI
    sudo sed -i "s|^smtp.password.*|smtp.password = ${CKAN_SMTP_PASSWORD}|" $CKAN_INI
    sudo sed -i "s|^smtp.mail_from.*|smtp.mail_from = ${CKAN_SMTP_MAIL_FROM}|" $CKAN_INI

    echo "Email configuration completed"
}

setup_xloader(){
    echo "Setting up xloader..."
    
    . /usr/lib/ckan/default/bin/activate
    
    # Set permissions
    sudo chown -R $USER /usr/lib/ckan/default/lib/
    sudo chown -R $USER /usr/lib/ckan/default/bin/
    
    pip install ckanext-xloader
    pip install -r https://raw.githubusercontent.com/ckan/ckanext-xloader/master/requirements.txt
    pip install -U requests[security]
    
    if ! grep -q "^ckanext.xloader.jobs_db.uri" "$CKAN_INI"; then
        sudo sed -i "/ckan.datastore.read_url/a ckanext.xloader.jobs_db.uri = postgresql://ckan_default:${CKAN_DB_PASSWORD}@localhost/ckan_default" $CKAN_INI
        echo "Added xloader jobs_db uri configuration"
    fi

    if ! grep -q "^ckanext.xloader.api_token" "$CKAN_INI"; then
        sudo sed -i "/ckanext.xloader.jobs_db.uri/a ckanext.xloader.api_token = ${API_KEY}" $CKAN_INI
        echo "Added xloader api_token configuration"
    fi

    if ! grep -q "^ckanext.xloader.ignore_hash" "$CKAN_INI"; then
        sudo sed -i "/ckanext.xloader.api_token/a ckanext.xloader.ignore_hash = False" $CKAN_INI
        echo "Added xloader ignore_hash configuration"
    fi

    if ! grep -q "^ckanext.xloader.use_type_guessing" "$CKAN_INI"; then
        sudo sed -i "/ckanext.xloader.ignore_hash/a ckanext.xloader.use_type_guessing = True" $CKAN_INI
        echo "Added xloader type guessing configuration"
    fi
    
    if ! grep -q "ckan.plugins.*xloader" "$CKAN_INI"; then
        sudo sed -i '/^ckan.plugins[[:space:]]*=/ s/$/ xloader/' "$CKAN_INI"
        echo "Added xloader to CKAN plugins"
    fi
    
    echo "Xloader setup completed"
}



setup_excelforms() {
    echo "Setting up Excel Forms extension..."
    . /usr/lib/ckan/default/bin/activate

    sudo chown -R $USER /usr/lib/ckan/default/lib/
    sudo chown -R $USER /usr/lib/ckan/default/bin/
    
    git clone https://github.com/ckan/ckanext-excelforms.git
    cd ckanext-excelforms
    pip install -e .
    
    echo "Excel Forms setup completed"
}

setup_charts() {
    echo "Setting up Charts extension..."
    . /usr/lib/ckan/default/bin/activate

    cd ..
    git clone https://github.com/DataShades/ckanext-charts.git
    cd ckanext-charts
    pip install -e .

    echo "Charts setup completed"
}

setup_pdfview() {
    echo "Setting up PDF viewer extension..."
    . /usr/lib/ckan/default/bin/activate
    
    pip install ckanext-pdfview
    
    echo "PDF viewer setup completed"
}

register_extensions() {
    echo "Registering CKAN plugins..."
    
    plugins=(
        "excelforms"
        "tabledesigner"
        "image_view"
        "datatables_view"
        "text_view"
        "video_view"
        "audio_view"
        "pdf_view"
        "charts_view"
        "charts_builder_view"
        "scheming_datasets"
        "scheming_groups"
        "scheming_organizations"
    )

    for plugin in "${plugins[@]}"; do
        if ! grep -q "ckan.plugins.*${plugin}" "$CKAN_INI"; then
            sudo sed -i "/^ckan.plugins[[:space:]]*=/ s/$/ ${plugin}/" "$CKAN_INI"
            echo "Added ${plugin} to CKAN plugins"
        else
            echo "${plugin} already registered"
        fi
    done

    echo "Plugin registration completed"
}

LOGFILE="/var/log/ckan/extensions.log"

cleanup() {
    local exit_code=$?
    echo "Cleanup triggered with exit code: $exit_code"
    
    if [ $exit_code -ne 0 ]; then
        echo "[$(date)] Extension installation failed with exit code $exit_code" | sudo tee -a "$LOGFILE"
        
        sudo supervisorctl stop all 2>/dev/null
        
        if [ -n "$VIRTUAL_ENV" ]; then
            deactivate
        fi
        
        if [ -d "ckanext-excelforms" ]; then
            rm -rf ckanext-excelforms
        fi
        if [ -d "ckanext-charts" ]; then
            rm -rf ckanext-charts
        fi
        
        echo "Cleanup completed. Check $LOGFILE for details"
    else
        echo "[$(date)] Extension installation completed successfully" | sudo tee -a "$LOGFILE"
    fi
}

trap cleanup EXIT

main() {
    sudo mkdir -p /var/log/ckan
    
    set -e
    
    check_env_vars || exit 1
    setup_datastore || exit 1
    setup_email_settings || exit 1
    setup_xloader || exit 1
    setup_excelforms || exit 1
    setup_charts || exit 1
    setup_pdfview || exit 1
    register_extensions || exit 1

    sudo supervisorctl reload
    
    echo "Extension installation and setup complete!"
}

sudo chmod 755 "/home/$(whoami)"
sudo supervisorctl stop all
main "$@"
