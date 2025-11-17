pipeline {
    agent any

    environment {
        SONARQUBE_SERVER = 'SonarQube'
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

                script {
                    // Lấy đường dẫn SonarQube Scanner từ tool đã khai báo
                    def scannerHome = tool name: 'SonarQube', type: 'hudson.plugins.sonar.SonarRunnerInstallation'

                    withSonarQubeEnv("${SONARQUBE_SERVER}") {
                        sh """
                            echo "Running SonarScanner..."
                            ${scannerHome}/bin/sonar-scanner \
                                -Dsonar.projectKey=DevSecOps \
                                -Dsonar.projectName=DevSecOps \
                                -Dsonar.projectVersion=1.0 \
                                -Dsonar.sources=juice-shop \
                                -Dsonar.login=\$SONARQUBE_TOKEN
                        """
                    }
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 1, unit: 'MINUTES'){
                    waitForQualityGate abortPipeline: true
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

