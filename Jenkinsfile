pipeline {
    agent any

    environment {
        // Your EC2 Linux user
        EC2_USER = 'ubuntu'

        // IMPORTANT: put your EC2 PUBLIC IPv4 address here (NOT 172.x.x.x)
        EC2_HOST = '52.66.82.191'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('CI + Build + Push + Deploy (remote on EC2)') {
            steps {
                bat '''
echo ===== Starting remote CI/CD on %EC2_HOST% =====

rem UPDATE THIS PATH TO YOUR REAL .PEM KEY FILE
set KEY=C:/Users/VShreeya/Downloads/jenkins-ec2.pem

echo Using key at %KEY%

scp -i "%KEY%" -o StrictHostKeyChecking=no deploy-remote.sh %EC2_USER%@%EC2_HOST%:/home/%EC2_USER%/deploy-remote.sh

ssh -i "%KEY%" -o StrictHostKeyChecking=no %EC2_USER%@%EC2_HOST% "chmod +x /home/%EC2_USER%/deploy-remote.sh && /home/%EC2_USER%/deploy-remote.sh"
'''
            }
        }
    post {
        success {
            emailext(
                subject: "SUCCESS: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                to: "shreezzz0704@gmail.com",
                body: """Build ${env.JOB_NAME} #${env.BUILD_NUMBER} succeeded.

Console output: ${env.BUILD_URL}
""",
                mimeType: 'text/plain'
            )
        }
        failure {
            emailext(
                subject: "FAILURE: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                to: "shreezzz0704@gmail.com",
                body: """Build ${env.JOB_NAME} #${env.BUILD_NUMBER} FAILED.

Console output: ${env.BUILD_URL}
""",
                mimeType: 'text/plain'
            )
        }
    }
}