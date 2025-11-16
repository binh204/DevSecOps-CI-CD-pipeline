pipeline {
    agent any

    options {
        skipDefaultCheckout()
    }

    // Không cần khối 'tools'

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
                
                // *** ĐÂY LÀ SỬA LỖI MỚI NHẤT ***
                // Tham số cho SERVER (từ Configure System)
                // Tham số cho TOOL (từ Global Tools)
                withSonarQubeEnv(configurationName: 'SonarQube', installationName: 'SonarQube') {
                    
                    // Jenkins sẽ tự động thêm scanner vào PATH
                    sh """
                        echo "Running SonarScanner..."
                        sonar-scanner \
                            -Dsonar.projectKey=DevSecOps \
                            -Dsonar.projectName=DevSecOps \
                            -Dsonar.projectVersion=1.0 \
                            -Dsonar.sources=.
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
