
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
0 0 * * * export MAILJET_API_KEY="MAILJET_API_KEY" && export MAILJET_SECRET_KEY="MAILJET_SECRET_KEY" && export SENDER_EMAIL="SENDER_EMAIL" && export RECEIVER_EMAIL="RECEIVER_EMAIL" && /usr/bin/docker system prune -af --volumes > /root/logs/docker_prune.log 2>&1 && /root/arpansahu-one-scripts/docker_cleanup_mail.sh
```

# Integrating Jenkins

* Now Create a file named Jenkinsfile at the root of Git Repo and add following lines to file

```bash
pipeline {
    agent { label 'local' }
    environment {
        ENV_PROJECT_NAME = "arpansahu_one_scripts"
    }
    stages {
        stage('Initialize') {
            steps {
                script {
                    echo "Current workspace path is: ${env.WORKSPACE}"
                }
            }
        }
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
    }
    post {
        success {
            script {
                // Retrieve the latest commit message
                def commitMessage = sh(script: "git log -1 --pretty=%B", returnStdout: true).trim()
                if (currentBuild.description == 'DEPLOYMENT_EXECUTED') {
                    sh """curl -s \
                    -X POST \
                    --user $MAIL_JET_API_KEY:$MAIL_JET_API_SECRET \
                    https://api.mailjet.com/v3.1/send \
                    -H "Content-Type:application/json" \
                    -d '{
                        "Messages":[
                                {
                                        "From": {
                                                "Email": "$MAIL_JET_EMAIL_ADDRESS",
                                                "Name": "ArpanSahuOne Jenkins Notification"
                                        },
                                        "To": [
                                                {
                                                        "Email": "$MY_EMAIL_ADDRESS",
                                                        "Name": "Development Team"
                                                }
                                        ],
                                        "Subject": "Jenkins Build Pipeline your project ${currentBuild.fullDisplayName} Ran Successfully",
                                        "TextPart": "Hola Development Team, your project ${currentBuild.fullDisplayName} is now deployed",
                                        "HTMLPart": "<h3>Hola Development Team, your project ${currentBuild.fullDisplayName} is now deployed </h3> <br> <p> Build Url: ${env.BUILD_URL}  </p>"
                                }
                        ]
                    }'"""
                }
                // Trigger the common_readme job for all repositories"
                build job: 'common_readme', parameters: [string(name: 'environment', value: 'prod')], wait: false
               
            }
        }
        failure {
            sh """curl -s \
            -X POST \
            --user $MAIL_JET_API_KEY:$MAIL_JET_API_SECRET \
            https://api.mailjet.com/v3.1/send \
            -H "Content-Type:application/json" \
            -d '{
                "Messages":[
                        {
                                "From": {
                                        "Email": "$MAIL_JET_EMAIL_ADDRESS",
                                        "Name": "ArpanSahuOne Jenkins Notification"
                                },
                                "To": [
                                        {
                                                "Email": "$MY_EMAIL_ADDRESS",
                                                "Name": "Developer Team"
                                        }
                                ],
                            "Subject": "Jenkins Build Pipeline your project ${currentBuild.fullDisplayName} Ran Failed",
                            "TextPart": "Hola Development Team, your project ${currentBuild.fullDisplayName} deployment failed",
                            "HTMLPart": "<h3>Hola Development Team, your project ${currentBuild.fullDisplayName} is not deployed, Build Failed </h3> <br> <p> Build Url: ${env.BUILD_URL}  </p>"
                        }
                ]
            }'"""
        }
    }
}
```

Note: agent {label 'local'} is used to specify which node will execute the jenkins job deployment. So local linux server is labelled with 'local' are the project with this label will be executed in local machine node.

* Configure a Jenkins project from jenkins ui located at https://jenkins.arpansahu.me

Make sure to use Pipeline project and name it whatever you want I have named it as per great_chat

![Jenkins Pipeline Configuration](https://github.com/arpansahu/arpansahu-one-scripts/raw/main/Jenkinsfile.png)

In this above picture you can see credentials right? you can add your github credentials and harbor credentials use harbor-credentials as id for harbor credentials.
from Manage Jenkins on home Page --> Manage Credentials

and add your GitHub credentials from there

* Add a .env file to you project using following command (This step is no more required stage('Dependencies'))

    ```bash
    sudo vi  /var/lib/jenkins/workspace/arpansahu_one_script/.env
    ```

    Your workspace name may be different.

    Add all the env variables as required and mentioned in the Readme File.

* Add Global Jenkins Variables from Dashboard --> Manage --> Jenkins
  Configure System
 
  * MAIL_JET_API_KEY
  * MAIL_JET_API_SECRET
  * MAIL_JET_EMAIL_ADDRESS
  * MY_EMAIL_ADDRESS

Now you are good to go.


## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
