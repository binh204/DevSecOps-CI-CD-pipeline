pipeline {
    agent any
    environment {
        GIT_CREDENTIALS = credentials('github-token') // dùng ID ở bước trên
    }
    stages {
        stage('Clone Code') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/binh204/DevSecOps',
                    credentialsId: 'github-token'
            }
        }
        stage('Build') {
            steps {
                echo "Building project..."
                // Thêm lệnh build nếu cần
            }
        }
    }
}
