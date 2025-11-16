pipeline {
    agent any

    options {
        skipDefaultCheckout()
    }

    // *** THAY ĐỔI 1: SỬA LỖI TÊN TOOL TYPE ***
    // Tên class đã được đổi thành tên ĐÚNG mà log lỗi cung cấp.
    tools {
        hudson.plugins.sonar.SonarRunnerInstallation('SonarQube')
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
                
                // 'SonarQube' này là tên SERVER (từ Configure System)
                withSonarQubeEnv('SonarQube') {
                    
                    // *** THAY ĐỔI 2: SỬA LỖI CÚ PHÁP "def" ***
                    // Bọc toàn bộ logic Groovy vào trong một khối 'script'
                    script {
                        // 1. Lấy đường dẫn cài đặt của tool tên là 'SonarQube' (từ Global Tools)
                        def sqScanner = tool 'SonarQube'
                        
                        // 2. Chạy scanner bằng đường dẫn đầy đủ
                        sh """
                            echo "Running SonarScanner from path: ${sqScanner}/bin"
                            ${sqScanner}/bin/sonar-scanner \
                                -Dsonar.projectKey=DevSecOps \
                                -Dsonar.projectName=DevSecOps \
                                -Dsonar.projectVersion=1.0 \
                                -Dsonar.sources=.
                        """
                    } // Kết thúc khối script
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
