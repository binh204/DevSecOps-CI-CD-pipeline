pipeline {
    agent any

    environment {
        // Tên server phải đúng với tên bạn đặt trong:
        // Manage Jenkins → Configure System → SonarQube servers
        SONARQUBE_SERVER = 'SonarQube'

        // ID của Secret Text chứa token SonarQube (đã thêm trong Jenkins Credentials)
        SONARQUBE_TOKEN = credentials('sonar-token')
    }

    stages {

        stage('Checkout Code') {
            steps {
                echo '🌀 Cloning source code from GitHub...'
                git(
                    branch: 'main',
                    credentialsId: 'github-credentials',
                    url: 'https://github.com/binh204/DevSecOps'
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
                // Dùng đúng tên server bạn đã cấu hình
                withSonarQubeEnv("${SONARQUBE_SERVER}") {
                    sh '''
                        echo "Running SonarScanner..."
                        sonar-scanner \
                            -Dsonar.projectKey=DevSecOps \
                            -Dsonar.projectName=DevSecOps \
                            -Dsonar.projectVersion=1.0 \
                            -Dsonar.sources=. \
                            -Dsonar.login=$SONARQUBE_TOKEN
                    '''
                    // Nếu muốn debug thêm, có thể thêm dòng dưới:
                    // sonar-scanner -X ...
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
