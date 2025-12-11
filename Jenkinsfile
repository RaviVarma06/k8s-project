pipeline {
    agent any
    tools {
        jdk 'jdk17'
        nodejs 'node16'
    }
    environment {
        SCANNER_HOME = tool 'mysonar'
        AWS_REGION = 'ap-south-1'
    }
    stages {
        stage("Clean Workspace") {
            steps {
                cleanWs()
            }
        }
        stage("Clone Repositories") {
            steps {
                script {
                    // Clone application repo
                    git url: 'https://github.com/RaviVarma06/k8s-project.git', branch: 'master'

                    // Clone Argo CD repo into subfolder
                    dir('argo-cd') {
                        git url: 'https://github.com/RaviVarma06/argo-cd.git', branch: 'main'
                    }
                }
            }
        }
        stage("Determine Version from svc.yaml") {
            steps {
                script {
                    def selectorLine = sh(script: "grep 'app:' argo-cd/svc.yml | head -1", returnStdout: true).trim()
                    def appLabel = selectorLine.split(':')[1].trim()
                    def version = appLabel == 'swiggy-v2' ? 'v2' : 'v1'
                    env.IMAGE_TAG = version
                    env.TETRIS_APP = "585768179486.dkr.ecr.ap-south-1.amazonaws.com/mytetris/app:${version}"
                    env.ECR_REPO = "585768179486.dkr.ecr.ap-south-1.amazonaws.com/mytetris/app"
                }
            }
        }
        stage("CQA") {
            steps {
                withSonarQubeEnv('mysonar') {
                    sh '''$SCANNER_HOME/bin/sonar-scanner \
                        -Dsonar.projectKey=tetris \
                        -Dsonar.projectName=tetris \
                        -Dsonar.login=sqa_c9f1788017dc113a7a392d9cab81b2068d1d48ac
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
                    def buildContext = env.IMAGE_TAG == 'v2' ? 'TETRIS-V2' : '.'
                    sh "docker build -t mygame/tetris:${env.IMAGE_TAG} ${buildContext}"
                    sh "docker tag mygame/tetris:${env.IMAGE_TAG} $TETRIS_APP"
                }
            }
        }
        stage("Push to ECR") {
            steps {
                withCredentials([usernamePassword(credentialsId: 'AWS-ECR-CRED', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    sh '''
                        export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                        export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                        export AWS_DEFAULT_REGION=$AWS_REGION

                        aws ecr describe-repositories --repository-names mytetris/app || \
                        aws ecr create-repository --repository-name mytetris/app --region $AWS_REGION

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
        stage("Deploy to AWS ECS") {
            steps {
                withCredentials([usernamePassword(credentialsId: 'AWS-ECR-CRED', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    sh '''
                        export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                        export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                        export AWS_DEFAULT_REGION=$AWS_REGION

                        aws ecs update-service \
                            --cluster my-cluster-name \
                            --service my-service-name \
                            --force-new-deployment \
                            --region $AWS_REGION
                    '''
                }
            }
        }
    }
}
