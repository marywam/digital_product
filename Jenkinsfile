pipeline {
    agent none
    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
        DOCKER_IMAGE = "marywam/digital_product"
        PROD_TAG = "prod-${env.BUILD_NUMBER}"
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
                git branch: "${env.BRANCH_NAME}", 
                     url: 'https://github.com/marywam/digital_product.git',
                     credentialsId: 'github-credentials'
                stash name: 'source', includes: '**'
            }
        }

        stage('Install Dependencies and Run Tests') {
            agent {
                docker {
                    image 'python:3.11-slim'
                    args '-u root'
                }
            }
            steps {
                unstash 'source'
                sh '''
                    apt-get update
                    apt-get install -y --no-install-recommends gcc libpq-dev
                    pip install --upgrade pip
                    pip install -r requirements.txt
                    
                    if [ "${env.BRANCH_NAME}" = "master" ]; then
                        pip install coverage
                    fi
                    
                    python manage.py test
                    
                    if [ "${env.BRANCH_NAME}" = "master" ]; then
                        coverage run --source='.' manage.py test
                        coverage xml
                    fi
                '''
                junit '**/test-reports/*.xml' 
                
                script {
                    if (env.BRANCH_NAME == 'master') {
                        cobertura coberturaReportFile: 'coverage.xml'
                    }
                }
            }
        }

        stage('Build Docker Image') {
            agent {
                docker {
                    image 'docker:24.0-cli'
                    args '-v /var/run/docker.sock:/var/run/docker.sock -u root'
                }
            }
            steps {
                unstash 'source'
                script {
                    if (env.BRANCH_NAME == 'master') {
                        sh "docker build -t ${DOCKER_IMAGE}:${PROD_TAG} -t ${DOCKER_IMAGE}:latest ."
                    } else {
                        sh "docker build -t ${DOCKER_IMAGE}:${env.BRANCH_NAME}-${env.BUILD_NUMBER} ."
                    }
                }
            }
        }

        stage('Security Scan') {
            when { branch 'master' }
            agent {
                docker {
                    image 'aquasec/trivy:latest'
                    args '-u root -v /var/run/docker.sock:/var/run/docker.sock'
                }
            }
            steps {
                script {
                    sh "trivy image --exit-code 0 --severity HIGH,CRITICAL ${DOCKER_IMAGE}:${PROD_TAG}"
                }
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
                    sh '''
                        echo "$DOCKERHUB_PASSWORD" | docker login -u "$DOCKERHUB_USERNAME" --password-stdin
                    '''
                    script {
                        if (env.BRANCH_NAME == 'master') {
                            sh """
                                docker push ${DOCKER_IMAGE}:${PROD_TAG}
                                docker push ${DOCKER_IMAGE}:latest
                            """
                        } else {
                            sh "docker push ${DOCKER_IMAGE}:${env.BRANCH_NAME}-${env.BUILD_NUMBER}"
                        }
                    }
                }
            }
        }

        stage('Deploy to Production') {
            when { branch 'master' }
            agent any
            steps {
                script {
                    echo "🚀 Deploying ${DOCKER_IMAGE}:${PROD_TAG} to production environment"
                }
            }
        }
    }

    post {
        always {
            sh 'docker system prune -f || true'
        }
        success {
            script {  // FIXED: Added script block
                echo "✅ Pipeline for ${env.BRANCH_NAME} succeeded!"
                if (env.BRANCH_NAME == 'master') {
                    emailext (
                        subject: "🚀 Production Deployment Successful - Build #${env.BUILD_NUMBER}",
                        body: "Production deployment completed successfully.\n\n" +
                              "Docker Image: ${DOCKER_IMAGE}:${PROD_TAG}\n" +
                              "Build URL: ${env.BUILD_URL}",
                        to: 'your-email@example.com'  // ADD YOUR EMAIL
                    )
                }
            }
        }
        failure {
            script {  // FIXED: Added script block
                echo "❌ Pipeline failed for ${env.BRANCH_NAME}!"
                if (env.BRANCH_NAME == 'master') {
                    emailext (
                        subject: "⛔ PRODUCTION DEPLOYMENT FAILED - Build #${env.BUILD_NUMBER}",
                        body: "Production deployment failed. Immediate attention required!\n\n" +
                              "Build URL: ${env.BUILD_URL}\n" +
                              "Logs: ${env.BUILD_URL}console",
                        to: 'your-email@example.com'  // ADD YOUR EMAIL
                    )
                }
            }
        }
    }
}