pipeline {
    agent any // Chạy trên agent mặc định (chính là container Jenkins của bạn)

    // Tùy chọn: Tắt checkout SCM tự động.
    options {
        skipDefaultCheckout()
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
            // *** ĐÂY LÀ PHẦN ĐÃ SỬA ***
            // Đã XÓA BỎ "agent { docker { ... } }"
            // Jenkins sẽ chạy ngay trên agent mặc định (agent any)
            steps {
                echo '🔍 Starting SonarQube code analysis...'
                
                // Tên 'SonarQube' phải khớp với tên bạn đặt trong:
                // Manage Jenkins → Configure System → SonarQube servers
                withSonarQubeEnv('SonarQube') {
                    sh '''
                        echo "Running SonarScanner..."
                        #
                        # Lệnh 'sonar-scanner' này sẽ chạy được NẾU BẠN
                        # đã làm bước cấu hình tool trong Jenkins.
                        #
                        sonar-scanner \
                            -Dsonar.projectKey=DevSecOps \
                            -Dsonar.projectName=DevSecOps \
                            -Dsonar.projectVersion=1.0 \
                            -Dsonar.sources=.
                    '''
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
