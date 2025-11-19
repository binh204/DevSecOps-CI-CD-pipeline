pipeline {
    agent any
    environment {
        SONARQUBE_SERVER = 'SonarQube'
        SONARQUBE_TOKEN = credentials('sonar-token')
        DEFECTDOJO_API_KEY = credentials('defectdojo-api')
    }
    
    stages {
        stage('Checkout') {
            steps { 
                git branch: 'main', credentialsId: 'github-credentials', 
                url: 'https://github.com/binh204/DevSecOps' 
            }
        }
        
        stage('SonarQube Analysis') {
            steps {
                script {
                    def scannerHome = tool name: 'SonarQube', type: 'hudson.plugins.sonar.SonarRunnerInstallation'
                    withSonarQubeEnv("${SONARQUBE_SERVER}") {
                        sh """
                            ${scannerHome}/bin/sonar-scanner \\
                                -Dsonar.projectKey=DevSecOps \\
                                -Dsonar.sources=juice-shop \\
                                -Dsonar.login=${SONARQUBE_TOKEN}
                        """
                    }
                }
            }
        }
        
        stage('Wait for Processing') {
            steps { sleep time: 2, unit: 'MINUTES' }
        }
        
        stage('ZAP Security Scan') {
            steps {
                echo '🛡️ Using EXISTING ZAP Container...'
                sh '''
                    # SỬ DỤNG ZAP CONTAINER CÓ SẴN
                    echo "ZAP Container: http://192.168.73.36:8082/"
                    
                    # Test ZAP
                    if curl -f --max-time 15 http://192.168.73.36:8082/; then
                        echo "✅ ZAP ready - starting scan..."
                        
                        # Start application if not running
                        if ! curl -f http://localhost:3000/ 2>/dev/null; then
                            docker run -d --name juice-app -p 3000:3000 bkimminich/juice-shop
                            sleep 25
                        fi
                        
                        # Download and run ZAP
                        curl -s -o zap-baseline.py https://raw.githubusercontent.com/zaproxy/zaproxy/main/docker/zap-baseline.py
                        chmod +x zap-baseline.py
                        
                        python3 zap-baseline.py \\
                            -t http://localhost:3000 \\
                            -r zap-report.html \\
                            -d http://192.168.73.36:8082 \\
                            -I -j
                        
                        echo "✅ ZAP scan completed"
                    else
                        echo "❌ ZAP unavailable - creating placeholder"
                        echo "<html><body><h1>ZAP Scan</h1><p>Existing container at 192.168.73.36:8082 is unresponsive</p></body></html>" > zap-report.html
                    fi
                    
                    # Cleanup
                    docker stop juice-app || true
                    docker rm juice-app || true
                '''
            }
        }
        
        stage('Publish Reports') {
            steps {
                archiveArtifacts artifacts: 'zap-report.html', fingerprint: true
                publishHTML([
                    allowMissing: false, reportDir: '.', 
                    reportFiles: 'zap-report.html', reportName: 'ZAP Security Report'
                ])
            }
        }
        
        stage('Upload to DefectDojo') {
            steps {
                sh '''
                    if [ -f "zap-report.html" ]; then
                        curl -X POST "http://192.168.73.36:8080/api/v2/import-scan/" \\
                            -H "Authorization: Token ${DEFECTDOJO_API_KEY}" \\
                            -F "file=@zap-report.html" \\
                            -F "scan_type=ZAP Scan" \\
                            -F "product=1" -F "engagement=1" \\
                            -F "active=true" -F "verified=false"
                    fi
                '''
            }
        }
    }
    
    post { 
        success { echo '✅ Pipeline completed!' }
        failure { echo '❌ Pipeline failed!' }
    }
}
