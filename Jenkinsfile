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