pipeline {
    agent any

    environment {
        SONARQUBE = credentials('sonar-token')  // ID của token SonarQube bạn lưu trong Jenkins Credentials
    }

    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'main', credentialsId: 'github-credentials', url: 'https://github.com/binh204/DevSecOps'
            }
        }

        stage('Build') {
            steps {
                echo 'Building project...'
            }
        }

        stage('Code Analysis - SonarQube') {
            steps {
                withSonarQubeEnv('SonarQube') { // Tên server bạn thêm trong Jenkins → Manage Jenkins → Configure System
                    sh 'sonar-scanner -Dproject.settings=sonar-project.properties'
                }
            }
        }

        stage('Post Build') {
            steps {
                echo 'Pipeline completed successfully!'
            }
        }
    }
}
