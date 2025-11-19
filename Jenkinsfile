pipeline {
    agent any
    environment {
        SONARQUBE_SERVER = 'SonarQube'
        SONARQUBE_TOKEN = credentials('sonar-token')
        DEFECTDOJO_API_KEY = credentials('defectdojo-api')
    }

    stages {
        // 1️⃣ Checkout code
        stage('Checkout') {
            steps {
                git branch: 'main', credentialsId: 'github-credentials', 
                    url: 'https://github.com/binh204/DevSecOps'
            }
        }

        // 2️⃣ SonarQube static analysis
        stage('SonarQube Analysis') {
            steps {
                script {
                    def scannerHome = tool name: 'SonarQube', type: 'hudson.plugins.sonar.SonarRunnerInstallation'
                    withSonarQubeEnv("${SONARQUBE_SERVER}") {
                        sh """
                            ${scannerHome}/bin/sonar-scanner \
                                -Dsonar.projectKey=DevSecOps \
                                -Dsonar.sources=juice-shop \
                                -Dsonar.login=${SONARQUBE_TOKEN}
                        """
                    }
                }
            }
        }

        // 3️⃣ Wait for SonarQube processing
        stage('Wait for Processing') {
            steps { sleep time: 2, unit: 'MINUTES' }
        }

        // 4️⃣ Build Docker image từ source code
        stage('Build Docker Image') {
    steps {
        script {
            echo "🚀 Building Docker image from Juice Shop source..."

            dockerImage = docker.build(
                "juice-shop:${env.BUILD_NUMBER}",
                "./juice-shop"   // <-- Build đúng thư mục chứa Dockerfile
            )
        }
    }
}
        // 5️⃣ Run container từ image vừa build
        stage('Run Juice Shop Container') {
            steps {
                script {
                    echo "🏃 Running container from image..."
                    sh '''
                        docker stop juice-app || true
                        docker rm juice-app || true
                    '''
                    sh "docker run -d --name juice-app -p 3000:3000 juice-shop:${BUILD_NUMBER}"
                    sleep 25 // đợi container sẵn sàng
                }
            }
        }

/*
        // 6️⃣ ZAP Security Scan
        stage('ZAP Security Scan') {
            steps {
                sh '''
                    python3 zap-baseline.py \
                        -t http://localhost:3000 \
                        -r zap-report.html \
                        -d http://192.168.73.36:8082 \
                        -I -j
                '''
            }
        }

        // 7️⃣ Publish ZAP report
        stage('Publish Reports') {
            steps {
                archiveArtifacts artifacts: 'zap-report.html', fingerprint: true
                publishHTML([
                    allowMissing: false, reportDir: '.', 
                    reportFiles: 'zap-report.html', reportName: 'ZAP Security Report'
                ])
            }
        }

        // 8️⃣ Upload to DefectDojo
        stage('Upload to DefectDojo') {
            steps {
                sh '''
                    if [ -f "zap-report.html" ]; then
                        curl -X POST "http://192.168.73.36:8080/api/v2/import-scan/" \
                            -H "Authorization: Token ${DEFECTDOJO_API_KEY}" \
                            -F "file=@zap-report.html" \
                            -F "scan_type=ZAP Scan" \
                            -F "product=1" -F "engagement=1" \
                            -F "active=true" -F "verified=false"
                    fi
                '''
            }
        }
*/
    }

    post {
        success { echo '✅ Pipeline completed successfully!' }
        failure { echo '❌ Pipeline failed!' }
        always {
            echo "🧹 Cleaning up container..."
            sh '''
                docker stop juice-app || true
                docker rm juice-app || true
            '''
        }
    }
}

