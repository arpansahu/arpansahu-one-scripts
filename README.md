
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

## Running the Script

To run the script manually, give permissions and execute:

```sh
chmod +x ./setup_and_run.sh
./setup_and_run.sh
```

```sh
chmod +x ./docker_cleanup_mail.sh
./docker_cleanup_mail.sh
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
0 0 * * * /usr/bin/docker system prune -af --volumes > /root/logs/docker_prune.log 2>&1 && /root/arpansahu-one-scripts/docker_cleanup_mail.sh
```


## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
