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
                // Dùng đúng tên server bạn đã cấu hình
                withSonarQubeEnv("SonarQube") {
                    sh '''
                        echo "Running SonarScanner..."
                        sonar-scanner \
                            -Dsonar.projectKey=DevSecOps \
                            -Dsonar.projectName=DevSecOps \
                            -Dsonar.projectVersion=1.0 \
                            -Dsonar.sources=. \
                            -Dsonar.host.url=http://192.168.73.36:9000 \
                            -Dsonar.login=sqa_c888b2c71a9edc4adafc33783560fa7cae646248
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
