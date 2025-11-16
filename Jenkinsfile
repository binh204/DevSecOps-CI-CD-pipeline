pipeline {
    agent any

    environment {
        // Tên server đã cấu hình trong Manage Jenkins → Configure System → SonarQube servers
        SONARQUBE_SERVER = 'SonarQube'

        // ID của Secret Text chứa token SonarQube (đã thêm trong Jenkins Credentials)
        SONARQUBE_TOKEN = credentials('sonar-token')
    }

    tools {
        // Tên tool SonarScanner đã khai báo trong Jenkins → Global Tool Configuration
        sonarScanner 'SonarScanner'
    }

    stages {

        stage('Checkout Code') {
            steps {
                echo '🌀 Cloning source code from GitHub...'
                git(
                    branch: 'main',
                    credentialsId: 'github-credentials',
                    url: 'https://github.com/binh204/DevSecOps.git'
                )
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
                // withSonarQubeEnv tự set biến môi trường để kết nối với server
                withSonarQubeEnv("${SONARQUBE_SERVER}") {
                    sh """
                        echo "Running SonarScanner..."
                        ${tool 'SonarScanner'}/bin/sonar-scanner \
                            -Dsonar.projectKey=DevSecOps \
                            -Dsonar.projectName=DevSecOps \
                            -Dsonar.projectVersion=1.0 \
                            -Dsonar.sources=. \
                            -Dsonar.login=$SONARQUBE_TOKEN
                    """
                }
            }
        }
    }

    post {
        success {
            echo '✅ SonarQube analysis completed successfully!'
        }
        failure {
            echo '❌ Pipeline failed! Check console output for details.'
        }
        always {
            echo '🏁 Pipeline finished.'
        }
    }
}

