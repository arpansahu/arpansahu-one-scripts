#!/bin/bash

# Define the base directory where the .env file is located
BASE_DIR="/root/arpansahu-one-scripts"
ENV_FILE="$BASE_DIR/.env"

# Load environment variables from .env file
if [ -f "$ENV_FILE" ]; then
    echo "Loading environment variables from .env file..."
    export $(grep -v '^#' "$ENV_FILE" | xargs)
    echo "MAILJET_API_KEY: $MAILJET_API_KEY"
    echo "MAILJET_SECRET_KEY: $MAILJET_SECRET_KEY"
    echo "SENDER_EMAIL: $SENDER_EMAIL"
    echo "RECEIVER_EMAIL: $RECEIVER_EMAIL"
else
    echo ".env file not found!"
    exit 1
fi

# Check if required environment variables are set
if [ -z "$MAILJET_API_KEY" ] || [ -z "$MAILJET_SECRET_KEY" ] || [ -z "$SENDER_EMAIL" ] || [ -z "$RECEIVER_EMAIL" ]; then
    echo "One or more required environment variables (MAILJET_API_KEY, MAILJET_SECRET_KEY, SENDER_EMAIL, RECEIVER_EMAIL) are not set in the .env file"
    exit 1
fi

# Email details
LOG_FILE="/root/logs/docker_prune.log"

# Check if the log file exists
if [ ! -f "$LOG_FILE" ]; then
    echo "Log file not found: $LOG_FILE"
    exit 1
fi

# Read the log file contents
BODY=$(cat "$LOG_FILE")

# Send email using Mailjet API
RESPONSE=$(curl -s \
  -X POST \
  --user "$MAILJET_API_KEY:$MAILJET_SECRET_KEY" \
  https://api.mailjet.com/v3.1/send \
  -H 'Content-Type: application/json' \
  -d '{
    "Messages":[
      {
        "From": {
          "Email": "'"$SENDER_EMAIL"'",
          "Name": "Your Name"
        },
        "To": [
          {
            "Email": "'"$RECEIVER_EMAIL"'",
            "Name": "Arpan"
          }
        ],
        "Subject": "Docker Prune Completed",
        "TextPart": "'"$BODY"'"
      }
    ]
  }')

echo "Mailjet API Response: $RESPONSE"