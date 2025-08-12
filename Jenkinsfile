pipeline {
    agent any

    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials') // Set in Jenkins
        DOCKERHUB_USERNAME = "${DOCKERHUB_CREDENTIALS_USR}"
        DOCKERHUB_PASSWORD = "${DOCKERHUB_CREDENTIALS_PSW}"
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
                python3 -m venv virtual
                source virtual/bin/activate
                pip install --upgrade pip
                pip install -r requirements.txt
                '''
            }
        }

        stage('Run Tests') {
            steps {
                sh '''
                source virtual/bin/activate
                python manage.py test
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh "docker build -t ${DOCKER_IMAGE}:${env.BRANCH_NAME}-${env.BUILD_NUMBER} ."
                }
            }
        }

        stage('Push to DockerHub') {
            steps {
                script {
                    sh """
                    echo "${DOCKERHUB_PASSWORD}" | docker login -u "${DOCKERHUB_USERNAME}" --password-stdin
                    docker push ${DOCKER_IMAGE}:${env.BRANCH_NAME}-${env.BUILD_NUMBER}
                    """
                }
            }
        }
    }

    post {
        success {
            echo "Pipeline for branch ${env.BRANCH_NAME} completed successfully!"
        }
        failure {
            echo "Pipeline failed for branch ${env.BRANCH_NAME}."
        }
    }
}
