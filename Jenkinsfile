pipeline {
    agent any

    environment {
        APP_NAME       = 'aws-cicd-clean'
        AWS_REGION     = 'ap-south-1'
        AWS_ACCOUNT_ID = '426811254002'
        ECR_REPO       = 'aws-cicd-clean'
        EC2_HOST       = '52.66.82.191'   // your EC2 public IP
    }

    options {
        timestamps()
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('CI + Build + Push + Deploy (remote on EC2))') {
            steps {
                bat '''
echo ===== Starting remote CI/CD on %EC2_HOST% =====

rem Path to your SSH key on the Jenkins Windows host
set KEY=C:/Users/VShreeya/Downloads/jenkins-ec2.pem
echo Using key at %KEY%

scp -i "%KEY%" -o StrictHostKeyChecking=no deploy-remote.sh ubuntu@%EC2_HOST%:/home/ubuntu/deploy-remote.sh

ssh -i "%KEY%" -o StrictHostKeyChecking=no ubuntu@%EC2_HOST% "chmod +x /home/ubuntu/deploy-remote.sh && /home/ubuntu/deploy-remote.sh"
'''
            }
        }
    }

    post {
        success {
            mail to: 'shreezzz0704@gmail.com',
                 subject: "SUCCESS: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                 body: """Hi Shreeya,

The Jenkins pipeline for job ${env.JOB_NAME} (build #${env.BUILD_NUMBER}) completed SUCCESSFULLY.

App is deployed on EC2 and Docker container is running.

Console log: ${env.BUILD_URL}

– Jenkins
"""
        }
        failure {
            mail to: 'shreezzz0704@gmail.com',
                 subject: "FAILURE: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                 body: """Hi Shreeya,

The Jenkins pipeline for job ${env.JOB_NAME} (build #${env.BUILD_NUMBER}) FAILED.

Please check the console log: ${env.BUILD_URL}

– Jenkins
"""
        }
    }
}