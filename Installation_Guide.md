# **Adamant Deployment and Installation Guide**

This guide outlines the setup and deployment process for the **EMPI RF ADAMANT** project across two separate machines:

- **Machine 1**: Hosts the Adamant Webapp including the **React frontend**, **Flask backend**, **MariaDB database**, and background **Bash scripts** (configured via cronjobs).
- **Machine 2**: Hosts a **Nextcloud** instance and executes **Bash scripts for data preprocessing**, also run via cronjobs.

This guide also describes how to automate installation using Docker and/or Bash scripts and make commands.

---

## **1. System Overview**

### **Machine 1 - Web Application Host**
- Flask Backend (Python)
- React Frontend (Node.js)
- MariaDB Database
- Bash Scripts for scheduled tasks (via cron)

### **Machine 2 - Nextcloud Host**
- Nextcloud Server
- Bash Scripts for data preprocessing (via cron)

---

## **2. System Requirements**

### **General Requirements for Both Machines**
- Ubuntu 20.04 or higher
- Docker & Docker Compose
- Bash shell
- Git

### **Machine 1 Specific**
- Python 3.8+
- pip package manager
- Node.js
- npm package manager
- Nginx
- Lets Encrypt Certbot for SSL
- rsync
- inotify-tools
- jq
- SSH Access to Machine 2 Configured (hostname: nextcloud)

### **Machine 2 Specific**
- Nextcloud
- jq
- inotifywait

---

## **3. Repository Setup**

On both machines:
```bash
git clone https://github.com/mohamedatawfik/adamant.git
cd adamant
```

---

## **4. Backend Setup (Machine 1)**

### **Database Configuration**
Ensure that the following environment variables are set correctly in the Flask backend (`api.py`) to connect to the database:
```python
# Database configuration
DB_HOST = '127.0.0.1'
DB_PORT = 3306
DB_USER = 'new_user'
DB_PASSWORD = 'new_password'
DB_NAME = 'experiment_data'
```
These credentials must match what is set up in the MariaDB instance.

### **Manual Setup (Python Environment)**
```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python api.py
```

### **Dockerized Setup**
Ensure `docker-compose.yml` is correctly configured:
```bash
docker-compose up -d api
```

### **Verify API**
```bash
curl http://<machine-1-ip>:5000
```

---

## **5. Frontend Setup (Machine 1)**

### **Manual Setup (Node.js Environment)**
```bash
cd adamant
npm install
npm run build
cd react-mui-demo
npm install
npm run build
```

Move the nested build directory into the main build directory:
```bash
mkdir -p ../build/react-mui-demo
mv build/* ../build/react-mui-demo/
```

Place the compiled frontend into the Nginx web root:
```bash
sudo cp -r ../build /var/www/html/adamant
```

Copy and configure the Nginx configuration:
```bash
sudo cp nginx.default.prod.conf /etc/nginx/conf.d/adamant.conf
sudo systemctl restart nginx
```

### **SSL Setup with Let's Encrypt (Certbot)**
Install Certbot:
```bash
sudo apt update
sudo apt install certbot python3-certbot-nginx -y
```

Run Certbot to obtain SSL certificates and configure Nginx:
```bash
sudo certbot --nginx -d example.empi-rf.test
```

Verify HTTPS access:
```
https://example.empi-rf.test
```

---

## **6. Database Setup (MariaDB on Machine 1)**

Install MariaDB:
```bash
sudo apt update
sudo apt install mariadb-server
```

### **Create the required database**
Log into MariaDB:
```bash
sudo mysql -u root
```

Once inside the MariaDB prompt, create the database:
```sql
CREATE DATABASE experiment_data;
```

Verify the database exists:
```sql
SHOW DATABASES;
```
Expected output:
```
+--------------------+
| Database           |
+--------------------+
| experiment_data    |
| ...                |
+--------------------+
```

### **Database Users**
To view current users:
```sql
SELECT User, Host FROM mysql.user;
```
Example output:
```
+-------------+-----------+
| User        | Host      |
+-------------+-----------+
| new_user    | %         |
| mariadb.sys | localhost |
| mysql       | localhost |
| new_user    | localhost |
| root        | localhost |
| user        | localhost |
+-------------+-----------+
```

Check user privileges:
```sql
SHOW GRANTS FOR 'new_user'@'localhost';
SHOW GRANTS FOR 'new_user'@'%';
```
Example grants:
```
GRANT USAGE ON *.* TO 'new_user'@'localhost' IDENTIFIED BY PASSWORD '*0913BF2E2CE20CE21BFB1961AF124D4920458E5F'
GRANT ALL PRIVILEGES ON `expirement_data`.* TO 'new_user'@'localhost'
GRANT ALL PRIVILEGES ON `experiment_data`.* TO 'new_user'@'localhost'
```

These privileges allow the Flask backend to fully access the `experiment_data` database using the credentials specified in `api.py`.

---

## **7. Bash Scripts & Cron Jobs in `bin/`**

### **Machine 1 (Adamant Web Server)**

#### Script: insert_data2db.sh

- **Purpose:**  
  Scans the `data_sorted` directory for JSON files, extracts data, and inserts it into the corresponding MariaDB tables. Each subdirectory within `data_sorted` represents a table, and each JSON file corresponds to a new row.

- **Setup:**
Place in `/home/user/scripts/` and make executable:
```bash
chmod +x /home/user/scripts/insert_data2db.sh
```

Schedule with cron:
```bash
crontab -e
0 * * * * /home/user/scripts/insert_data2db.sh
```

#### Script: syncscript.sh

- **Purpose:**  
  Uses rsync over SSH to sync the data_sorted directory from the remote Nextcloud machine to the local machine. It ensures that Adamant always works with the most recent data from Nextcloud.

- **Setup:**
Place in `/home/user/scripts/` and make executable:
```bash
chmod +x /home/user/scripts/syncscript.sh
```

Schedule with cron:
```bash
crontab -e
0 * * * * /home/user/scripts/syncscript.sh
```

### **Machine 2 (Nextcloud Server)**

#### Script: data_preprocessing.sh

- **Purpose:**  
Monitors the `nextcloud_dir/rawData` directory for new JSON files. When a file is added, the script:

- Parses the JSON content.
- Extracts a unique `SchemaID` from the file.
- Moves the file into a corresponding subfolder under `data_sorted/`, named after the `SchemaID`.
- Adds a `documentlocation` field to the JSON, indicating its absolute path, for use in downstream processing.

- **Setup:**
Place in `/home/user/scripts/` and make executable:
```bash
chmod +x /home/user/scripts/data_preprocessing.sh
```

Schedule with cron:
```bash
crontab -e
0 * * * * /home/user/scripts/data_preprocessing.sh
```

---

## **8. Automation Scripts / Docker Setup**

### **Option 1: Bash Scripts and Makefile (Preferred)**
To streamline installation and reduce manual configuration errors, the Adamant project provides a set of **Bash scripts** and a **Makefile** that automates the full setup for both Machine 1 and Machine 2.

---

### **Directory Structure Overview**

adamant/
├── backend/
├── frontend/
├── bin/                         # Utility scripts for cron jobs
├── deployment/                  # Automation scripts and Makefile logic
│   ├── deploy_web_server.sh
│   ├── setup_cron_web_server.sh
│   ├── deploy_nextcloud.sh
│   ├── setup_cron_nextcloud.sh
├── Makefile                     # Top-level Makefile

---

### **Makefile Usage**

The `Makefile` provides a high-level interface for running deployment and setup steps without manually invoking each script. It supports the following commands:

| Command               | Description                                                                 |
|-----------------------|-----------------------------------------------------------------------------|
| `make all`            | Deploys **both** Machine 1 and Machine 2 (web server + Nextcloud)           |
| `make machine1`       | Deploys **only Machine 1** (frontend, backend, DB, Nginx, SSL, scripts)     |
| `make machine2`       | Deploys **only Machine 2** (Nextcloud and preprocessing scripts)            |

---

### **Before You Begin**

Ensure your system meets the required dependencies:

```bash
sudo apt update && sudo apt install -y make git curl
```

Clone the repository and move into it:

```bash
git clone https://github.com/mohamedatawfik/adamant.git
cd adamant
```

Then run the desired Makefile target:
```bash
make machine1      # Deploy only Machine 1
make all           # Deploy both machines
```

---

### **About the Bash Scripts in `deployment/`**

Each script is modular and designed to handle a specific aspect of the system setup. These scripts automate the installation, configuration, and cron scheduling for both machines.

---

#### **For Machine 1 (Web Server)**

- **`deploy_web_server.sh`**  
  Performs the full setup for the Adamant web server:
  - Clones the Adamant GitHub repository
  - Sets up the Python backend environment with **Gunicorn**
  - Builds and deploys the **React frontend**
  - Configures **Nginx** and sets up **SSL certificates** using Certbot
  - Copies background Bash scripts:
    - `insert_data2db.sh`
    - `syncscript.sh`  
    into `/home/user/scripts/`

- **`setup_cron_web_server.sh`**  
  - Installs and registers **cron jobs** to periodically execute backend automation scripts (e.g., inserting data to DB, syncing sorted_data folders).

---

#### **For Machine 2 (Nextcloud Data Preprocessing)**

- **`deploy_nextcloud.sh`**  
  Automates the installation and configuration of the Nextcloud server:
  - Installs necessary dependencies (JQ, inotify-tools)
  - Copies the data preprocessing script:
    - `data_preprocessing.sh`  
    into `/home/user/scripts/`

- **`setup_cron_nextcloud.sh`**  
  - Installs and registers **cron jobs** to execute the preprocessing script at scheduled intervals.

---

These scripts are intended to be invoked either manually or via the `Makefile`, providing a clean and automated way to bring up the system on both machines with minimal user interaction.


### **Option 2: Docker Compose Client (frontend) and Server (Backend)**
- `cd adamant`
- `adamant$ docker−compose build`—build the docker images for both back-end and front-end
- `adamant$ docker−compose up -d`—start both client and server containers, i.e., the whole system

---

## **9. Maintenance & Troubleshooting**

### **Logs and Troubleshooting**

Once the Adamant Web Server is deployed, to monitor the services and identify any issues using system logs and service status, below are essential commands and tips for debugging common components.

#### **Flask Backend (Gunicorn via systemd)**


- **Check service status:**
```bash
sudo systemctl status adamant-backend
```

- **View backend logs:**
```bash
sudo journalctl -u adamant-backend
```
This will show the output of the Flask API as managed by Gunicorn and systemd.

#### **Flask Backend (Docker (If Used for Deployment))**

- **List running containers:**
```bash
docker ps
```

- **Check logs for a specific container:**
```bash
docker logs <container_name_or_id>
```
Useful for diagnosing issues in the API, frontend if Docker is being used.

#### **Cron Jobs**

- **Verify that cron jobs are being triggered:**

```bash
cat /var/log/syslog | grep CRON
```

This log will show when scheduled tasks are executed and can help verify if your scripts (e.g., insert_data2db.sh, syncscript.sh, or data_preprocessing.sh) are running as expected.


#### **Nginx (Frontend and SSL)**

- **Check Nginx service status:**

```bash
sudo systemctl status nginx
```

- **Check Nginx error log:**

```bash
sudo tail -n 50 /var/log/nginx/error.log
```

- **Check access log:**

```bash
sudo tail -n 50 /var/log/nginx/access.log
```

These logs help diagnose frontend issues, misconfigured SSL, or unreachable services.

#### **MariaDB**

- **Check MariaDB service status:**

```bash
sudo systemctl status mariadb
```

- **View MariaDB error log:**

```bash
sudo less /var/log/mysql/error.log
```

### **Helpful Tools for Service and Network Monitoring**
Use systemd or tools like `htop`, `docker stats`, `netstat`


---

## **11. Access Points**

- Frontend UI: `https://example.empi-rf.test`
- API: `http://example.empi-rf.test:5000`
- Database: `example.empi-rf.test:3006`

---

## **12. Conclusion**

With this guide, Adamant should now be deployed and fully operational across two separate machines. Automation via shell scripts or Docker simplifies re-deployment. Always validate services post-install and monitor logs for ongoing health.
