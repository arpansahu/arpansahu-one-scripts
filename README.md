
# Website Uptime Monitor

This project monitors the uptime of specified websites and sends an email alert if any website is down or returns a non-2xx status code. The project uses a shell script to set up a virtual environment, install dependencies, run the monitoring script, and then clean up the virtual environment.

## Prerequisites

- Python 3
- Pip (Python package installer)
- Mailjet account for email alerts
- Cron for scheduling the script

## Setup

### 1. Clone the Repository

```sh
git clone https://github.com/yourusername/website-uptime-monitor.git
cd website-uptime-monitor
```

### 2. Create a `.env` File

Create a `.env` file in the root directory and add the following content:

```env
MAILJET_API_KEY=your_mailjet_api_key
MAILJET_SECRET_KEY=your_mailjet_secret_key
SENDER_EMAIL=your_sender_email@example.com
RECEIVER_EMAIL=your_receiver_email@example.com
```

### 3. Create `requirements.txt`

Create a `requirements.txt` file in the root directory with the following content:

```txt
requests
retrying
python-dotenv
```

### 4. Create the Shell Script

Create a shell script `setup_and_run.sh` in the root directory with the following content:

```sh
#!/bin/bash

# Define the virtual environment directory
VENV_DIR="venv"

# Define the requirements file
REQUIREMENTS_FILE="requirements.txt"

# Define the Python script to run
PYTHON_SCRIPT="website_monitor.py"

# Check if virtual environment directory exists
if [ -d "$VENV_DIR" ]; then
    echo "Virtual environment already exists."
else
    # Create a virtual environment
    echo "Creating virtual environment..."
    python3 -m venv "$VENV_DIR"
fi

# Activate the virtual environment
source "$VENV_DIR/bin/activate"

# Upgrade pip in the virtual environment
echo "Upgrading pip..."
pip install --upgrade pip

# Install requirements
if [ -f "$REQUIREMENTS_FILE" ]; then
    echo "Installing dependencies..."
    pip install -r "$REQUIREMENTS_FILE"
else
    echo "Requirements file not found. Skipping dependency installation."
fi

# Run the Python script
if [ -f "$PYTHON_SCRIPT" ]; then
    echo "Running the Python script..."
    python "$PYTHON_SCRIPT"
else
    echo "Python script not found. Exiting."
fi

# Deactivate the virtual environment
deactivate

# Remove the virtual environment directory
echo "Deleting virtual environment..."
rm -rf "$VENV_DIR"

echo "Done."
```

Make the script executable:

```sh
chmod +x setup_and_run.sh
```

### 5. Create the Python Script

Create a Python script `website_monitor.py` in the root directory with the following content:

```python
import requests
import smtplib
import logging
from email.mime.text import MIMEText
from requests.exceptions import HTTPError, RequestException
from time import sleep
from retrying import retry
from dotenv import load_dotenv
import os

# Load environment variables from .env file
load_dotenv()

# Website to monitor
website_urls = [
    "https://arpansahu.me",
    "https://prometheus.arpansahu.me/",
    "https://jenkins.arpansahu.me/",
    "https://pgadmin.arpansahu.me/",
    "https://grafana.arpansahu.me/",
    "https://redis.arpansahu.me/",
    "https://portainer.arpansahu.me/",
    "https://minioui.arpansahu.me/",
    "https://kube.arpansahu.me/",
    "https://harbor.arpansahu.me/",
]

# Mailjet API credentials
mailjet_api_key = os.getenv("MAILJET_API_KEY")
mailjet_secret_key = os.getenv("MAILJET_SECRET_KEY")
sender_email = os.getenv("SENDER_EMAIL")
receiver_email = os.getenv("RECEIVER_EMAIL")

# Set up logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

def send_email(subject, body):
    msg = MIMEText(body)
    msg["Subject"] = subject
    msg["From"] = sender_email
    msg["To"] = receiver_email

    try:
        # Connect to the SMTP server
        with smtplib.SMTP("smtp.mailjet.com", 587) as server:
            server.starttls()
            server.login(mailjet_api_key, mailjet_secret_key)
            # Send email
            server.sendmail(sender_email, [receiver_email], msg.as_string())
        logging.info(f"Email sent successfully: {subject}")
    except smtplib.SMTPException as e:
        logging.error(f"Failed to send email: {e}")

@retry(stop_max_attempt_number=3, wait_fixed=2000)
def check_website_status(website):
    response = requests.get(website, timeout=10)  # Set a timeout for the request
    response.raise_for_status()  # Raise an HTTPError for bad responses (4xx or 5xx)
    return response

def check_websites():
    for website in website_urls:
        try:
            response = check_website_status(website)
            if response.status_code // 100 != 2:
                send_email("Website Alert", f"The website {website} returned a non-2xx status code: {response.status_code}")
        except HTTPError as e:
            if e.response.status_code == 401 or e.response.status_code == 403:
                logging.info(f"The website {website} returned a {e.response.status_code} status code. This is allowed.")
            else:
                send_email("Website Alert", f"An error occurred while checking the website {website}. Error: {str(e)}")
        except RequestException as e:
            send_email("Website Alert", f"An error occurred while checking the website {website}. Error: {str(e)}")

if __name__ == "__main__":
    check_websites()
```

## Running the Script

To run the script manually, execute:

```sh
./setup_and_run.sh
```

## Setting Up a Cron Job

To run the script automatically at regular intervals, set up a cron job:

1. Edit the crontab:

```sh
crontab -e
```

2. Add the following line to run the script every 5 hours:

```sh
0 */5 * * * /bin/bash /root/arpansahu-one-scripts/setup_and_run.sh >> /root/logs/website_up_time.log 2>&1
```

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
