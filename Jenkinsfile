pipeline {
    agent none
    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
        DOCKER_IMAGE = "marywam/digital_product"
        // Add production-specific settings
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
                git branch: "${env.BRANCH_NAME}", url: 'https://github.com/marywam/digital_product.git'
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
                    
                    # Add test coverage reporting for production branch
                    if [ "${env.BRANCH_NAME}" = "master" ]; then
                        pip install coverage
                    fi
                    
                    python manage.py test
                    
                    # Generate coverage report for production
                    if [ "${env.BRANCH_NAME}" = "master" ]; then
                        coverage run --source='.' manage.py test
                        coverage xml
                    fi
                '''
                // Archive test results for all branches
                junit '**/test-reports/*.xml' 
                
                // Archive coverage report only for master
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
                    // Different tagging strategy for production
                    if (env.BRANCH_NAME == 'master') {
                        sh "docker build -t ${DOCKER_IMAGE}:${PROD_TAG} -t ${DOCKER_IMAGE}:latest ."
                    } else {
                        sh "docker build -t ${DOCKER_IMAGE}:${env.BRANCH_NAME}-${env.BUILD_NUMBER} ."
                    }
                }
            }
        }

        stage('Security Scan') {
            when { branch 'master' }  // Only for production
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
            when { branch 'master' }  // Only for production
            agent any
            steps {
                // Add your production deployment steps here
                echo "🚀 Deploying ${DOCKER_IMAGE}:${PROD_TAG} to production environment"
                // Example: 
                // sh "kubectl set image deployment/digital_product web=${DOCKER_IMAGE}:${PROD_TAG}"
            }
        }
    }

    post {
        always {
            // Clean up Docker images to save disk space
            sh 'docker system prune -f || true'
        }
        success {
            echo "✅ Pipeline for ${env.BRANCH_NAME} succeeded!"
            
            // Production success notification
            if (env.BRANCH_NAME == 'master') {
                emailext (
                    subject: "🚀 Production Deployment Successful - Build #${env.BUILD_NUMBER}",
                    body: "Production deployment completed successfully.\n\n" +
                          "Docker Image: ${DOCKER_IMAGE}:${PROD_TAG}\n" +
                          "Build URL: ${env.BUILD_URL}",
                
                )
            }
        }
        failure {
            echo "❌ Pipeline failed for ${env.BRANCH_NAME}!"
            
            // Different notifications for production failures
            if (env.BRANCH_NAME == 'master') {
                emailext (
                    subject: "⛔ PRODUCTION DEPLOYMENT FAILED - Build #${env.BUILD_NUMBER}",
                    body: "Production deployment failed. Immediate attention required!\n\n" +
                          "Build URL: ${env.BUILD_URL}\n" +
                          "Logs: ${env.BUILD_URL}console",
                   
                )
            }
        }
    }
}