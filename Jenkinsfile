pipeline {
    agent any
    tools {
        jdk 'jdk17'
        nodejs 'node16'
    }
    environment {
        SCANNER_HOME = tool 'mysonar'
        AWS_REGION = 'us-east-1'
        TETRIS_APP = '585768179486.dkr.ecr.us-east-1.amazonaws.com/mytetris/app'
        ECR_REPO = '585768179486.dkr.ecr.us-east-1.amazonaws.com/mytetris/app'
    }
    stages {
        stage("CleanWs") {
            steps {
                cleanWs()
            }
        }
        stage("Code") {
            steps {
                git "https://github.com/RaviVarma06/k8s-project.git"
            }
        }
        stage("CQA") {
            steps {
                withSonarQubeEnv('mysonar') {
                    sh '''mvn clean verify sonar:sonar \
                        -Dsonar.projectKey=mytetris_app \
                        -Dsonar.projectName='mytetris_app' \
                        -Dsonar.login=sqa_238d74f0b897f183ce0dadb824acddc2d54fe27b
                    '''
                }
            }
        }
        stage("Build") {
            steps {
                sh 'mvn clean package'
                sh 'cp -r target mytetris_app'
            }
        }
        stage("Docker Build") {
            steps {
                script {
                    sh "docker build -t mygame/game ."
                    sh "docker tag mygame/game $TETRIS_APP"
                }
            }
        }
        stage("Push to ECR") {
            steps {
                withCredentials([usernamePassword(credentialsId: 'AWS-ECR-CREDS', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    sh '''
                        export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                        export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                        export AWS_DEFAULT_REGION=$AWS_REGION
                        aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO
                        docker push $TETRIS_APP
                    '''
                }
            }
        }
        stage("TrivyScan") {
            steps {
                sh 'trivy fs . > trivyfs.txt'
                sh "trivy image $TETRIS_APP"
            }
        }
        stage("Deploy to container") {
            steps {
                sh 'docker-compose up -d'
            }
        }
    }
}
