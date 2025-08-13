pipeline {
    agent {
        docker {
            image 'python:3.11-slim'
            args '-u root'  // run as root so pip installs work
        }
    }

    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
        DOCKER_IMAGE = "marywam/digital_product"
    }

    stages {
        stage('Checkout Code') {
            steps {
                git branch: "${env.BRANCH_NAME}", url: 'https://github.com/marywam/digital_product.git'
            }
        }

        stage('Install Dependencies') {
            steps {
                sh '''
                    set -e  # stop on first error
                    apt-get update && apt-get install -y --no-install-recommends gcc libpq-dev
                    pip install --upgrade pip
                    pip install -r requirements.txt
                '''
            }
        }

        stage('Run Tests') {
            steps {
                sh '''
                    set -e
                    python manage.py test
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                sh """
                    docker build -t ${DOCKER_IMAGE}:${env.BRANCH_NAME}-${env.BUILD_NUMBER} .
                """
            }
        }

        stage('Push to DockerHub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'DOCKERHUB_USERNAME', passwordVariable: 'DOCKERHUB_PASSWORD')]) {
                    sh """
                        echo "$DOCKERHUB_PASSWORD" | docker login -u "$DOCKERHUB_USERNAME" --password-stdin
                        docker push ${DOCKER_IMAGE}:${env.BRANCH_NAME}-${env.BUILD_NUMBER}
                    """
                }
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline for branch ${env.BRANCH_NAME} completed successfully!"
        }
        failure {
            echo "❌ Pipeline failed for branch ${env.BRANCH_NAME}."
        }
    }
}
