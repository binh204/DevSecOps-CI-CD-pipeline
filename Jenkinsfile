pipeline {
    agent any

    environment {
        SONARQUBE_SERVER = 'SonarQube'
        SONARQUBE_TOKEN = credentials('sonar-token')
        DEFECTDOJO_API_KEY = credentials('defectdojo-api')
        // Sử dụng ZAP container có sẵn
        ZAP_URL = "http://zap:8080"
        ZAP_HOST = "192.168.73.36:8082"  // Hoặc localhost:8082
    }

    stages {
        stage('Checkout Code') {
            steps {
                echo '🌀 Cloning source code...'
                git(
                    branch: 'main',
                    credentialsId: 'github-credentials',
                    url: 'https://github.com/binh204/DevSecOps'
                )
            }
        }

        stage('Build and Run Application') {
            steps {
                echo '🐳 Starting application for testing...'
                sh '''
                    # Chạy ứng dụng trong cùng network với ZAP
                    docker run -d --network devsecops-net \
                        --name juice-shop-app -p 3000:3000 \
                        bkimminich/juice-shop
                    
                    # Chờ ứng dụng khởi động
                    sleep 30
                    echo "✅ Application started"
                '''
            }
        }

        stage('SonarQube Analysis') {
            steps {
                echo '🔍 Running SonarQube analysis...'
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

        stage('Wait for Processing') {
            steps {
                echo '⏳ Waiting for SonarQube processing...'
                sleep time: 2, unit: 'MINUTES'
            }
        }

        stage('OWASP ZAP Baseline Scan') {
            steps {
                echo '🛡️ Running OWASP ZAP Baseline Scan...'
                sh '''
                    # Download ZAP baseline script
                    wget -q https://raw.githubusercontent.com/zaproxy/zaproxy/main/docker/zap-baseline.py \
                        -O zap-baseline.py
                    chmod +x zap-baseline.py
                    
                    # Kiểm tra ZAP container có hoạt động không
                    curl -f http://192.168.73.36:8082/ || { echo "❌ ZAP container not ready"; exit 1; }
                    
                    # Chạy scan sử dụng ZAP container có sẵn
                    python3 zap-baseline.py \
                        -t http://juice-shop-app:3000 \
                        -r zap-report.html \
                        -d http://zap:8080 \
                        -I -j -a
                    
                    # Hoặc sử dụng host network
                    # python3 zap-baseline.py \
                    #     -t http://localhost:3000 \
                    #     -r zap-report.html \ 
                    #     -d http://192.168.73.36:8082 \
                    #     -I -j -a
                '''
            }
        }

        stage('Publish ZAP Report') {
            steps {
                echo '📄 Publishing ZAP Report...'
                sh 'ls -la zap-report.html && echo "✅ ZAP report generated"'
                archiveArtifacts artifacts: 'zap-report.html', fingerprint: true
                publishHTML([
                    allowMissing: false,
                    alwaysLinkToLastBuild: true,
                    keepAll: true,
                    reportDir: '.',
                    reportFiles: 'zap-report.html',
                    reportName: 'ZAP Security Report'
                ])
            }
        }

        stage('Upload to DefectDojo') {
            steps {
                echo '🚀 Uploading to DefectDojo...'
                sh '''
                    if [ -f "zap-report.html" ]; then
                        curl -X POST "http://192.168.73.36:8080/api/v2/import-scan/" \
                            -H "Authorization: Token ${DEFECTDOJO_API_KEY}" \
                            -F "file=@zap-report.html" \
                            -F "scan_type=ZAP Scan" \
                            -F "product=1" \
                            -F "engagement=1" \
                            -F "active=true" \
                            -F "verified=false" \
                            -F "close_old_findings=true"
                        echo "✅ Uploaded to DefectDojo"
                    else
                        echo "❌ ZAP report not found"
                        exit 1
                    fi
                '''
            }
        }

        stage('Cleanup Application') {
            steps {
                echo '🧹 Cleaning up application container...'
                sh '''
                    docker stop juice-shop-app || true
                    docker rm juice-shop-app || true
                    echo "✅ Cleanup completed"
                '''
            }
        }
    }

    post {
        always {
            echo '🧹 Final cleanup...'
            sh '''
                docker stop juice-shop-app || true
                docker rm juice-shop-app || true
            '''
        }
        success {
            echo '✅ Pipeline completed successfully!'
        }
        failure {
            echo '❌ Pipeline failed! Check console logs.'
        }
    }
}
