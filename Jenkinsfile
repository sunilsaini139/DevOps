pipeline {
    agent any

    environment {
        IMAGE_NAME = "${JOB_NAME}"
        IMAGE_TAG = "${BUILD_ID}"
        DOCKER_HUB_USER = "${XGENPLUS}"
    }

    parameters {
        choice choices: ['jenkins', 'production'], name: 'select_server'
    }

    stages {

        stage('Clean Workspace') {
            steps {
                cleanWs()
            }
        }

        stage('Checkout SCM') {
            steps {
                git url: 'https://github.com/sunilsaini139/DevOps.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh """
                    docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
                    docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${DOCKER_HUB_USER}/${IMAGE_NAME}:${IMAGE_TAG}
                    docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${DOCKER_HUB_USER}/${IMAGE_NAME}:latest
                """
            }
        }

        stage('Push to DockerHub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhubs-credentials',
                                                 usernameVariable: 'DOCKER_HUB_USER',
                                                 passwordVariable: 'DOCKER_HUB_PASS')]) {
                    sh """
                        echo "${DOCKER_HUB_PASS}" | docker login -u ${DOCKER_HUB_USER} --password-stdin
                        docker push ${DOCKER_HUB_USER}/${IMAGE_NAME}:${IMAGE_TAG}
                        docker push ${DOCKER_HUB_USER}/${IMAGE_NAME}:latest
                        docker logout
                    """
                }
            }
        }

        stage('Delete Local Images') {
            steps {
                sh 'docker rmi -f $(docker  images -q ) || true'
            }
        }

        stage('Pull Latest Image') {
            parallel {

                stage('Pull on Jenkins Server') {
                    when { expression { return params.select_server == 'jenkins' } }
                    agent { label 'jenkins' }
                    steps {
                        withCredentials([usernamePassword(credentialsId: 'dockerhubs-credentials',
                                                          usernameVariable: 'DOCKER_HUB_USER',
                                                          passwordVariable: 'DOCKER_HUB_PASS')]) {
                            sh """
                                echo "${DOCKER_HUB_PASS}" | docker login -u ${DOCKER_HUB_USER} --password-stdin
                                docker pull ${DOCKER_HUB_USER}/${IMAGE_NAME}:latest
                                docker logout
                            """
                        }
                    }
                }

                stage('Pull on Production Server') {
                    when { expression { return params.select_server == 'production' } }
                    agent { label 'production' }
                    steps {
                        withCredentials([usernamePassword(credentialsId: 'dockerhubs-credentials',
                                                          usernameVariable: 'DOCKER_HUB_USER',
                                                          passwordVariable: 'DOCKER_HUB_PASS')]) {
                            sh """
                                echo "${DOCKER_HUB_PASS}" | docker login -u ${DOCKER_HUB_USER} --password-stdin
                                docker pull ${DOCKER_HUB_USER}/${IMAGE_NAME}:latest
                                docker logout
                            """
                        }
                    }
                }
            }
        }

        // 🧹 NEW STAGE: Pre-deployment cleanup
       // stage('Clean Old Containers') {
          //  when { anyOf { expression { return params.select_server == 'jenkins' }; expression { return params.select_server == 'production' } } }
          //  steps {
          //      script {
            //        def CONTAINER_NAME = "xgenplus-${BUILD_ID}"
//sh 'docker ps -a -q --filter "name=xgenplus" | xargs -r docker rm -f || true'
             //   }
         //   }
      //  }

        stage('Deploy on Jenkins Server') {
            when { expression { return params.select_server == 'jenkins' } }
            agent { label 'jenkins' }
            steps {
                script {
                    sh '''
                        docker stop  $(docker ps -aq --filter "publish=80") || true
                        docker run -d -p 80:80 --name xgenplus-${IMAGE_TAG} ${DOCKER_HUB_USER}/${IMAGE_NAME}:latest
                    '''
                }
            }
        }

        stage('Deploy on Production Server') {
            when { expression { return params.select_server == 'production' } }
            agent { label 'production' }
            steps {
                timeout(time: 1, unit: 'MINUTES') {
                    input message: 'Deployment approval for production?'
                }
                sh '''
                    docker stop $(docker ps -aq --filter "publish=80") || true
                    docker run -d -p 80:80 --name xgenplus-${IMAGE_TAG} ${DOCKER_HUB_USER}/${IMAGE_NAME}:latest
                '''
            }
        }
    }

    post {
        always {
            echo "Pipeline completed successfully for ${params.select_server} deployment."
        }
    }
}
