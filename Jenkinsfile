pipeline {
    agent any

    environment {
        // Đặt tên giống với cấu hình trong Jenkins → Manage Jenkins → Configure System
        SONARQUBE_SERVER = 'SonarQube'

        // Nếu bạn đã tạo token trong Jenkins Credentials (loại Secret Text)
        // ID của token đó là "sonar-token"
        SONARQUBE_TOKEN = credentials('sonar-token')
    }

    stages {

        stage('Checkout Code') {
            steps {
                echo '🌀 Cloning source code from GitHub...'
                git branch: 'main',
                    credentialsId: 'github-credentials',
                    url: 'https://github.com/binh204/DevSecOps'
            }
        }

        stage('Build') {
            steps {
                echo '⚙️ Building the project...'
                sh 'echo "Build process simulation - no errors."'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                echo '🔍 Starting SonarQube code analysis...'
                withSonarQubeEnv('SonarQube') {
                    sh '''
                        sonar-scanner \
                        -Dsonar.projectKey=DevSecOps \
                        -Dsonar.projectName=DevSecOps \
                        -Dsonar.projectVersion=1.0 \
                        -Dsonar.sources=. \
                        -Dsonar.host.url=http://192.168.73.36:9000 \
                        -Dsonar.login=$SONARQUBE_TOKEN
                    '''
                }
            }
        }

        stage('Post Build') {
            steps {
                echo '✅ Pipeline completed successfully!'
            }
        }
    }
}
