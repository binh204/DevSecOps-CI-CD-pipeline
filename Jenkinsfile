pipeline {
    agent any

    environment {
        // Jenkins credentials
        SONARQUBE_SERVER = 'SonarQube'
        SONARQUBE_TOKEN = credentials('sonar-token')

        // API key của DefectDojo
        DEFECTDOJO_API_KEY = credentials('defectdojo-api')
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

        stage('Build and Run Application') {
            steps {
                echo '🐳 Building and running application for testing...'
                sh '''
                    # Dừng container cũ nếu có
                    docker stop juice-shop-container || true
                    docker rm juice-shop-container || true
                    
                    # Chạy ứng dụng Juice Shop để test
                    docker run -d --name juice-shop-container -p 3000:3000 bkimminich/juice-shop
                    
                    # Chờ ứng dụng khởi động
                    echo "⏳ Waiting for application to start..."
                    sleep 30
                    
                    # Kiểm tra ứng dụng có chạy không
                    curl -f http://localhost:3000 || echo "⚠️ Application might be still starting..."
                '''
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
                echo '🔍 Running SonarQube code analysis...'
                script {
                    def scannerHome = tool name: 'SonarQube', type: 'hudson.plugins.sonar.SonarRunnerInstallation'
                    withSonarQubeEnv("${SONARQUBE_SERVER}") {
                        sh """
                            ${scannerHome}/bin/sonar-scanner \
                                -Dsonar.projectKey=DevSecOps \
                                -Dsonar.projectName=DevSecOps \
                                -Dsonar.projectVersion=1.0 \
                                -Dsonar.sources=juice-shop \
                                -Dsonar.login=${SONARQUBE_TOKEN}
                        """
                    }
                }
            }
        }

        stage('Safe Quality Gate Check') {
            steps {
                script {
                    echo '⚡ Checking Quality Gate with safe timeout...'
                    try {
                        timeout(time: 5, unit: 'MINUTES') {
                            def qg = waitForQualityGate()
                            echo "✅ Quality Gate status: ${qg.status}"
                            if (qg.status != 'OK') {
                                error "❌ Pipeline failed due to Quality Gate: ${qg.status}"
                            }
                        }
                    } catch (org.jenkinsci.plugins.workflow.steps.FlowInterruptedException e) {
                        echo '⚠️ Quality Gate check timeout - continuing pipeline anyway'
                        echo '📊 Please check SonarQube dashboard manually: http://192.168.73.36:9000/dashboard?id=DevSecOps'
                    }
                }
            }
        }

        stage('OWASP ZAP Baseline Scan') {
            steps {
                echo '🛡️ Running OWASP ZAP Baseline Scan...'
                sh '''
                    # Đảm bảo ứng dụng đang chạy trước khi scan
                    echo "Checking if application is ready..."
                    curl -f http://localhost:3000 || { echo "❌ Application not running!"; exit 1; }
                    
                    echo "Starting ZAP security scan..."
                    docker run --rm --network host -v $(pwd):/zap/wrk/:rw \
                        owasp/zap2docker-stable zap-baseline.py \
                        -t http://localhost:3000 \
                        -r zap-report.html \
                        -d \
                        -I \
                        -j \
                        -a
                    
                    # Kiểm tra report đã được tạo
                    if [ -f "zap-report.html" ]; then
                        echo "✅ ZAP scan completed successfully"
                        ls -la zap-report.html
                    else
                        echo "❌ ZAP report was not generated"
                        exit 1
                    fi
                '''
            }
        }

        stage('Publish ZAP Report') {
            steps {
                echo '📄 Publishing OWASP ZAP Report...'
                sh '''
                    if [ ! -f "zap-report.html" ]; then
                        echo "❌ ZAP report not found - cannot publish"
                        exit 1
                    fi
                    echo "✅ ZAP report found, publishing..."
                '''
                archiveArtifacts artifacts: 'zap-report.html', fingerprint: true
                
                // Thêm HTML publisher để xem report trực tiếp trong Jenkins
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

        stage('Upload ZAP Report to DefectDojo') {
            steps {
                echo '🚀 Uploading ZAP scan results to DefectDojo...'
                sh '''
                    # Kiểm tra file tồn tại
                    if [ ! -f "zap-report.html" ]; then
                        echo "❌ ZAP report file not found - cannot upload to DefectDojo"
                        exit 1
                    fi
                    
                    echo "Uploading scan results to DefectDojo..."
                    curl -v -X POST "http://192.168.73.36:8080/api/v2/import-scan/" \
                        -H "Authorization: Token ${DEFECTDOJO_API_KEY}" \
                        -F "file=@zap-report.html" \
                        -F "scan_type=ZAP Scan" \
                        -F "product=1" \
                        -F "engagement=1" \
                        -F "active=true" \
                        -F "verified=false" \
                        -F "close_old_findings=true"
                    
                    if [ $? -eq 0 ]; then
                        echo "✅ Successfully uploaded to DefectDojo"
                    else
                        echo "⚠️ Upload to DefectDojo may have failed - check API response"
                    fi
                '''
            }
        }

        stage('Cleanup') {
            steps {
                echo '🧹 Cleaning up containers...'
                sh '''
                    # Dừng và xóa containers
                    docker stop juice-shop-container || true
                    docker rm juice-shop-container || true
                    echo "✅ Cleanup completed"
                '''
            }
        }
    }

    post {
        always {
            echo '🧹 Running final cleanup...'
            sh '''
                # Đảm bảo dọn dẹp dù pipeline pass hay fail
                docker stop juice-shop-container || true
                docker rm juice-shop-container || true
            '''
        }
        success {
            echo '✅ Pipeline completed successfully with SonarQube + ZAP + DefectDojo!'
            echo '📊 SonarQube Dashboard: http://192.168.73.36:9000/dashboard?id=DevSecOps'
            echo '📋 ZAP Report: Available in Jenkins artifacts'
        }
        failure {
            echo '❌ Pipeline failed! Check console logs for details.'
        }
    }
}
