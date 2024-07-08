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
            else:
                print(f"Everything went fine for {website}")
                logging.info(f"Everything went fine for {website}")

        except HTTPError as e:
            if e.response.status_code == 401 or e.response.status_code == 403:
                logging.info(f"The website {website} returned a {e.response.status_code} status code. This is allowed.")
            else:
                logging.info(f"The website {website} returned a {e.response.status_code} status code. This is not allowed. Sending Mail")
                send_email("Website Alert", f"An error occurred while checking the website {website}. Error: {str(e)}")
        except RequestException as e:
            send_email("Website Alert", f"An error occurred while checking the website {website}. Error: {str(e)}")

if __name__ == "__main__":
    check_websites()