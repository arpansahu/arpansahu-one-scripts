import requests
import smtplib
from email.mime.text import MIMEText
from requests.exceptions import HTTPError

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
mailjet_api_key = "0792ed4148e32da9b6e3a7d9d61a8f5b"
mailjet_secret_key = "923fd6a3ad7e83a7af1105083de5ae1c"
sender_email = "admin@arpansahu.me"
receiver_email = "arpanrocks95@gmail.com"

def send_email(subject, body):
    msg = MIMEText(body)
    msg["Subject"] = subject
    msg["From"] = sender_email
    msg["To"] = receiver_email

    # Connect to the SMTP server
    with smtplib.SMTP("smtp.mailjet.com", 587) as server:
        server.starttls()
        server.login(mailjet_api_key, mailjet_secret_key)

        # Send email
        server.sendmail(sender_email, [receiver_email], msg.as_string())

def check_website():
    for website in website_urls:
        try:
            response = requests.get(website, timeout=10)  # Set a timeout for the request
            response.raise_for_status()  # Raise an HTTPError for bad responses (4xx or 5xx)

            # Check if the status code is not 2xx
            if response.status_code // 100 != 2:
                send_email("Website Alert", f"The website {website} returned a non-2xx status code: {response.status_code}")
        except HTTPError as e:
            # Check if the status code is 401 or 403
            if e.response.status_code == 401 or e.response.status_code == 403:
                print(f"The website {website} returned a {e.response.status_code} status code. This is allowed.")
            else:
                send_email("Website Alert", f"An error occurred while checking the website {website}. Error: {str(e)}")
        except requests.exceptions.RequestException as e:
            send_email("Website Alert", f"An error occurred while checking the website {website}. Error: {str(e)}")

if __name__ == "__main__":
    check_website()
