#!/bin/bash

# Define the base directory where the .env file is located
BASE_DIR="/root"

# Load environment variables from .env file if it exists
if [ -f "$BASE_DIR/.env" ]; then
    echo "Loading environment variables from .env file..."
    source "$BASE_DIR/.env"
    echo "MAILJET_API_KEY: $MAILJET_API_KEY"
    echo "MAILJET_SECRET_KEY: $MAILJET_SECRET_KEY"
    echo "SENDER_EMAIL: $SENDER_EMAIL"
    echo "RECEIVER_EMAIL: $RECEIVER_EMAIL"
fi

# Email details
LOG_FILE="/root/logs/docker_prune.log"

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