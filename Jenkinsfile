pipeline {
    agent none // Define agent per stage

    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
        DOCKER_IMAGE = "marywam/digital_product"
    }

    stages {
        stage('Checkout Code') {
            agent {
                docker {
                    image 'python:3.11-slim'
                    args '-u root'
                }
            }
            steps {
                git branch: "${env.BRANCH_NAME}", url: 'https://github.com/marywam/digital_product.git'
                stash name: 'source', includes: '**' // Save workspace
            }
        }

        stage('Install Dependencies') {
            agent {
                docker {
                    image 'python:3.11-slim'
                    args '-u root'
                }
            }
            steps {
                unstash 'source' // Retrieve workspace
                sh '''
                    apt-get update
                    apt-get install -y --no-install-recommends gcc libpq-dev
                    pip install --upgrade pip
                    pip install -r requirements.txt
                '''
            }
        }

        stage('Run Tests') {
            agent {
                docker {
                    image 'python:3.11-slim'
                    args '-u root'
                }
            }
            steps {
                unstash 'source'
                sh 'python manage.py test'
            }
        }

        // Use Docker agent for image building
        stage('Build Docker Image') {
            agent {
                docker {
                    image 'docker:24.0-cli' // Official Docker CLI image
                    args '-v /var/run/docker.sock:/var/run/docker.sock -u root'
                }
            }
            steps {
                unstash 'source'
                sh "docker build -t ${DOCKER_IMAGE}:${env.BRANCH_NAME}-${env.BUILD_NUMBER} ."
            }
        }

        stage('Push to DockerHub') {
            agent {
                docker {
                    image 'docker:24.0-cli'
                    args '-v /var/run/docker.sock:/var/run/docker.sock -u root'
                }
            }
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-credentials',
                    usernameVariable: 'DOCKERHUB_USERNAME',
                    passwordVariable: 'DOCKERHUB_PASSWORD'
                )]) {
                    sh """
                        docker login -u "$DOCKERHUB_USERNAME" -p "$DOCKERHUB_PASSWORD"
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