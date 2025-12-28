pipeline { 
    agent any 
    tools {
        jdk 'jdk17' 
        nodejs 'node16'
    }
    environment { 
        SCANNER_HOME = tool 'mysonar' 
        AWS_REGION = 'ap-south-1'
        ACCOUNT_ID = '904923506382'
        IMAGE_TAG = 'v1'
        TETRIS_APP = "904923506382.dkr.ecr.ap-south-1.amazonaws.com/mytetris/app:${IMAGE_TAG}"
        ECR_REPO = '904923506382.dkr.ecr.ap-south-1.amazonaws.com/mytetris/app'
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
                    sh '''$SCANNER_HOME/bin/sonar-scanner \
                        -Dsonar.projectKey=tetris \
                        -Dsonar.projectName=tetris \
                        -Dsonar.login=sqa_6b3358daad601391683c983526a57cce0b8d4a91
                    '''
                }
            }
        }
        stage("Build") {
            steps {
                sh 'npm install'
            }
        }
        stage("Docker Build") {
            steps {
                script {
                    sh "docker build -t mygame/tetris:${IMAGE_TAG} ."
                    sh "docker tag mygame/tetris:${IMAGE_TAG} $TETRIS_APP"
                }
            }
        }
         stage("TrivyScan") {
            steps {
                sh 'trivy fs . > trivyfs.txt'
                sh "trivy image $TETRIS_APP"
            }
        }
        stage("Push to ECR") {
            steps {
                withCredentials([usernamePassword(credentialsId: 'AWS-ECR-CRED', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    sh '''
                            export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                            export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                            export AWS_DEFAULT_REGION=$AWS_REGION

                    # Create repo if it doesn't exist
                    aws ecr describe-repositories --repository-names mytetris/app || \
                    aws ecr create-repository --repository-name mytetris/app --region $AWS_REGION

                    # Login and push image
                    aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO
                    docker push $TETRIS_APP
                    '''
                }
            }
        }
       
       
    }
}
