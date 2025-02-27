
# Installing docker

- Check if docker is installed if not install docker.
- Script fails and prompts user to install docker if not installed.

# Installing the CKAN package

- sudo apt update
- sudo apt install -y libpq5 redis-server nginx supervisor
- wget [https://packaging.ckan.org/python-ckan_2.11-jammy_amd64.deb](https://packaging.ckan.org/python-ckan_2.11-jammy_amd64.deb)
- sudo dpkg -i python-ckan_2.11-jammy_amd64.deb

# Installing and setting up the database

- sudo apt install -y postgresql
- sudo -u postgres psql -l
- sudo chmod 755 /home/azureuser # This is essential before you anything else related to the database this is changed to the user name.
- sudo -u postgres createuser -S -D -R -P ckan_default
- sudo -u postgres createdb -O ckan_default ckan_default -E utf-8
- sudo docker run --name ckan-solr -p 8983:8983 -d ckan/ckan-solr:2.10-solr9
- sudo mkdir -p /var/lib/ckan/default
- sudo chown www-data /var/lib/ckan/default
- sudo chmod u+rwx /var/lib/ckan/default

# Updating the configuration file

Updating the file /etc/ckan/default/ckan.ini with the relevant information. 

1. **Adding the ckan_default password** - this should be specified in a yaml file and checked before running the script. Below is the line that would be changed, `pass` should be changed with the password set in the .ini. 
    - `sqlalchemy.url = postgresql://ckan_default:pass@localhost/ckan_default`
2. Updating the site URL - for Azure this can be set as the public IP or domain for the VM. If a domain exits you can chuck it in here. This should be specified in YAML file then.
    - `ckan.site_url = [http://](http://zambia.swedencentral.cloudapp.azure.com/)localhost`

# Initialise the CKAN Database

- sudo ckan db init

# Fixing SQL errors - this is after initialising the database

- sudo -u postgres psql ckan_default
    - ALTER TABLE activity ADD COLUMN permission_labels TEXT[];
    - \q
- sudo supervisorctl reload
- sudo service nginx restart

# Add to sysadmin

This information should be specified in the YAML file. 

- sudo ckan sysadmin add < insert name>

## Installing Extensions

### Setting up datastore

- sudo -u postgres createuser -S -D -R -P -l datastore_default
- sudo -u postgres createdb -O ckan_default datastore_default -E utf-8
- Change the following in /etc/ckan/default/ckan.ini, pass is the same as CKAN_DB_PASSWORD in .env file:
    - ckan.datastore.write_url = postgresql://ckan_default:pass@localhost/datastore_default
    - ckan.datastore.read_url = postgresql://datastore_default:pass@localhost/datastore_default
- sudo ckan datastore set-permissions | sudo -u postgres psql --set ON_ERROR_STOP=1

### Installing Xloader

- Activate environment
    - .  /usr/lib/ckan/default/bin/activate
- Make necessary provisions:
    - sudo chown -R $USER /usr/lib/ckan/default/lib/
    - sudo chown -R $USER /usr/lib/ckan/default/bin/
- `pip install ckanext-xloader`
- pip install -r [https://raw.githubusercontent.com/ckan/ckanext-xloader/master/requirements.txt](https://raw.githubusercontent.com/ckan/ckanext-xloader/master/requirements.txt)
- pip install -U requests[security]
- Write the xloader settings to the .ini file:
    - ckanext.xloader.jobs_db.uri = postgresql://ckan_default:zambia@localhost/ckan_default
    - ckanext.xloader.api_token =

### Installing ckan-excel forms

.  /usr/lib/ckan/default/bin/activate

git clone https://github.com/ckan/ckanext-excelforms.git

pip install -e . 

### Installing ckan-charts

.  /usr/lib/ckan/default/bin/activate

git clone https://github.com/DataShades/ckanext-charts.git

pip install -e . 

### Install pdf viewer

.  /usr/lib/ckan/default/bin/activate

`pip install ckanext-pdfview`