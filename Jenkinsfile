pipeline {
    agent any

    options {
        skipDefaultCheckout()
    }

    // *** THAY ĐỔI 1: KHAI BÁO TOOL ***
    // Báo cho Jenkins biết pipeline này cần tool tên là 'SonarQube'.
    // Tên 'SonarQube' này PHẢI KHỚP với tên bạn đặt trong ảnh chụp màn hình.
    tools {
        org.sonarsource.scanner.jenkins.SonarQubeScannerInstallation 'SonarQube'
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
                    
                    // *** THAY ĐỔI 2: LẤY ĐƯỜNG DẪN ĐẦY ĐỦ ***
                    
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
