# CKAN Setup and Deployment

This repository contains instructions and scripts for setting up and deploying a CKAN instance, an open-source data management system. CKAN makes it easy to publish, share, and use data. This setup guide covers the installation, configuration, and deployment of CKAN on a Linux-based server (e.g., Ubuntu), utilising common tools and best practices.

## Installing CKAN from Package

This guide helps you install CKAN 2.11 automatically using the `install-from-package.sh` script. This has been tested on Ubuntu 22.04 LTS.


### Prerequisites

1. [Docker Engine](https://docs.docker.com/engine/install/ubuntu/) (latest version).
2. Sudo privileges.
3. Port 80 available for web traffic. 


### Installation Steps

1. **Create a `.env` file** with the following parameters:
    ```env
    CKAN_DB_PASSWORD=
    CKAN_SITE_URL=
    CKAN_SYSADMIN_NAME=
    ```

2. **Give the script the correct install permissions**:
    ```sh
    chmod +x install-from-package.sh
    ```

3. **Run the script**:
    ```sh
    ./install-from-package.sh
    ```

**Warning⚠️:** Running this script will uninstall the current CKAN installation and drop the corresponding databases and roles.

### Logging

The installation process logs its output to `/var/log/ckan/install.log`. Check this file for details in case of any issues.

### Cleanup

If the installation fails, the script will automatically clean up by stopping services, removing partial installations, and cleaning up the Solr container.

### Post-Installation

After the installation completes, the following steps are performed:
- PostgreSQL databases and roles are set up.
- CKAN directories and permissions are configured.
- The CKAN configuration file is updated.
- A Solr container is initialized.
- The CKAN database is initialized.
- SQL errors are fixed (optional step but necessary when installing on Ubuntu 22.04).
- Supervisor and Nginx services are restarted.
- A sysadmin user is set up.

For more details, refer to the script [`install-from-package.sh`](install-from-package.sh).

### Installing Extensions 