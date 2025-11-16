pipeline {
    agent any // Agent mặc định cho các stage không chỉ định agent riêng

    // Tùy chọn: Tắt checkout SCM tự động. 
    // Bằng cách này, stage 'Checkout Code' của bạn sẽ là bước checkout duy nhất.
    options {
        skipDefaultCheckout()
    }

    // Không cần block 'environment' nữa, vì 'withSonarQubeEnv' 
    // sẽ tự lấy thông tin (URL và token) từ tên server bạn cung cấp.

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
            // *** ĐÂY LÀ SỬA LỖI CHÍNH ***
            // Chỉ định stage này chạy trên một agent Docker riêng biệt
            // Image này đã có sẵn 'sonar-scanner'
            agent {
                docker { 
                    image 'sonarsource/sonar-scanner-cli:latest' 
                    // Tùy chọn: cache các plugin của Sonar để chạy nhanh hơn ở lần sau
                    args '-v $HOME/.sonar/cache:/root/.sonar/cache' 
                }
            }
            steps {
                echo '🔍 Starting SonarQube code analysis...'
                
                // Tên 'SonarQube' phải khớp với tên bạn đặt trong:
                // Manage Jenkins → Configure System → SonarQube servers
                withSonarQubeEnv('SonarQube') {
                    sh '''
                        echo "Running SonarScanner..."
                        # Lệnh 'sonar-scanner' giờ sẽ được tìm thấy vì nó nằm trong Docker image
                        #
                        # Chúng ta đã XÓA -Dsonar.login=... vì 'withSonarQubeEnv'
                        # đã tự động cung cấp token cho scanner một cách an toàn.
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
