# CKAN Setup and Deployment Guide 🚀

## Overview 📋

This guide provides a step-by-step process for setting up and deploying a CKAN instance, an open-source data management system that simplifies publishing, sharing, and accessing data. The setup instructions are geared towards a Linux-based server, such as Ubuntu, and cover everything from installation to configuration and deployment, utilizing Docker and following best practices.

## Table of Contents

- [CKAN Setup and Deployment Guide 🚀](#ckan-setup-and-deployment-guide-)
  - [Overview 📋](#overview-)
  - [Table of Contents](#table-of-contents)
  - [Prerequisites 🛠](#prerequisites-)
  - [Installing CKAN from Package 📦](#installing-ckan-from-package-)
    - [Installation Steps 🪜](#installation-steps-)
    - [Post-Installation 🔧](#post-installation-)
  - [Installing Extensions 🧩](#installing-extensions-)
    - [Steps for Installing Extensions](#steps-for-installing-extensions)
  - [Troubleshooting ⚙️](#troubleshooting-️)

---

## Prerequisites 🛠

Before starting the installation, make sure you have the following:

- **Docker Engine** (latest version) – [Installation Guide](https://docs.docker.com/engine/install/ubuntu/)
- **Sudo privileges** to execute installation commands
- **Port 80** open for web traffic, as CKAN serves over HTTP

---

## Installing CKAN from Package 📦

This guide supports the automatic installation of CKAN 2.11 using the `install-from-package.sh` script, tested on Ubuntu 22.04 LTS.

### Installation Steps 🪜

1. **Set Environment Variables:**
   - Create a `.env` file in the root directory with the following parameters:
     ```env
     CKAN_DB_PASSWORD=
     CKAN_SITE_URL=
     CKAN_SYSADMIN_NAME=
     ```

2. **Make the Script Executable:**
   - Set the correct permissions for the script:
     ```sh
     chmod +x install-from-package.sh
     ```

3. **Run the Installation Script:**
   - Execute the script to start the installation:
     ```sh
     ./install-from-package.sh
     ```
   - **Note:** Running this script will uninstall any existing CKAN installation and drop the associated databases and roles.

### Post-Installation 🔧

Upon successful installation, the process will automatically:

- ✅ Configure PostgreSQL databases and roles
- ✅ Set CKAN directories and permissions
- ✅ Update CKAN configuration files
- ✅ Initialize a Solr container for indexing
- ✅ Prepare the CKAN database
- ✅ Apply SQL adjustments (specific to Ubuntu 22.04)
- ✅ Restart essential services
- ✅ Create the specified sysadmin user

**Logs:** Installation logs are saved to `/var/log/ckan/install.log`. If any issues arise, review this log for details. In case of failure, the script will perform cleanup, stopping services, removing partial installations, and deleting the Solr container. For script details, refer to [`install-from-package.sh`](install-from-package.sh).

---

## Installing Extensions 🧩

CKAN extensions can be installed after the core installation is complete to add additional features and enhance functionality. Use the `install-extensions.sh` script for a streamlined setup. Before installing the extensions, log into the CKAN sysadmin to generate an API key which would be used by some of the extensions for authentification. 

### Steps for Installing Extensions

1. **Update the Environment Variables:**
   - Add the following SMTP and API configuration variables to your `.env` file:
     ```env
     API_KEY=
     CKAN_SMTP_SERVER=
     CKAN_SMTP_STARTTLS=
     CKAN_SMTP_USER=
     CKAN_SMTP_PASSWORD=
     CKAN_SMTP_MAIL_FROM=
     ```

2. **Make the Script Executable:**
   - Set appropriate permissions for the extension installation script:
     ```sh
     chmod +x install-extensions.sh
     ```

3. **Run the Extension Installation Script:**
   - Start the script to install and configure extensions:
     ```sh
     ./install-extensions.sh
     ```

This script will:

- Validate necessary environment variables
- Set up the datastore
- Configure email settings
- Install and configure the following extensions:
  - XLoader (data loading)
  - Excel Forms (data input via Excel)
  - Charts (data visualization)
  - PDF Viewer (PDF file preview)
  - CKAN API Extension (for API enhancements)
- Register all specified plugins in the CKAN instance

**Logs:** Check `/var/log/ckan/extensions.log` for the installation log. If an issue arises, the script will halt, perform cleanup, and stop all services.

---

## Troubleshooting ⚙️

- **Permissions Errors:** Ensure all scripts have executable permissions.
- **Service Failures:** Review log files in `/var/log/ckan/` for more details on failures.
- **Environment Variable Errors:** Double-check the `.env` file for required variable formatting and values.
  
For more troubleshooting tips, consult CKAN’s [documentation](https://docs.ckan.org/).

---
