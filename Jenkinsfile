pipeline {
    agent any

    environment {
        // CHANGE THIS if your EC2 user is different (e.g., "ec2-user" for Amazon Linux)
        EC2_USER      = 'ubuntu'

        // TODO: PUT YOUR EC2 PUBLIC IP OR PUBLIC DNS HERE (NOT PRIVATE 172.x.x.x)
        EC2_HOST      = '172.31.5.16'

        AWS_REGION    = 'eu-north-1'
        AWS_ACCOUNT_ID = '426811254002'

        APP_NAME      = 'aws-cicd-clean'
        ECR_REPO      = 'aws-cicd-clean'
        BRANCH        = 'main'
        GIT_URL       = 'https://github.com/Shreeya0704/aws-cicd-clean.git'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('CI + Build + Push + Deploy (remote on EC2)') {
            steps {
                // "ec2-ssh" must be an SSH private key credential in Jenkins
                sshagent(credentials: ['ec2-ssh']) {
                    bat '''
                    echo ===== Starting remote CI/CD on %EC2_HOST% =====

                    ssh -o StrictHostKeyChecking=no %EC2_USER%@%EC2_HOST% "sudo apt-get update -y && sudo apt-get install -y curl && curl -fsSL https://raw.githubusercontent.com/Shreeya0704/aws-cicd-clean/main/deploy-remote.sh -o /home/%EC2_USER%/deploy-remote.sh && chmod +x /home/%EC2_USER%/deploy-remote.sh && APP_NAME=%APP_NAME% AWS_REGION=%AWS_REGION% AWS_ACCOUNT_ID=%AWS_ACCOUNT_ID% ECR_REPO=%ECR_REPO% BRANCH=%BRANCH% GIT_URL=%GIT_URL% BUILD_NUMBER=%BUILD_NUMBER% /home/%EC2_USER%/deploy-remote.sh"
                    '''
                }
            }
        }
    }
}