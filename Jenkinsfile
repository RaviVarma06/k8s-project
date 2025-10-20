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
                    sh '''$SCANNER_HOME/bin/sonar-scanner \
                        -Dsonar.projectKey=tetris \
                        -Dsonar.projectName=tetris \
                        -Dsonar.login=sqa_e21535590f30ae302e122fecaf582e6c007fe355
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
                    sh "docker build -t mygame/tetris:v2 Tetris-V2"
                    sh "docker tag mygame/tetris $TETRIS_APP"
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
