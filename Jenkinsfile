pipeline {
    agent any

    environment {
        SONARQUBE_SERVER = 'SonarQube'
        SONAR_HOST = 'http://192.168.73.36:9000'
        PROJECT_KEY = 'DevSecOps'

        SONARQUBE_TOKEN = credentials('sonar-token')
        DEFECTDOJO_API_KEY = credentials('defectdojo-api')

        DEFECTDOJO_URL = 'http://192.168.73.36:8080'
        DEFECTDOJO_ENGAGEMENT_ID = '1'
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
                                -Dsonar.projectKey=${PROJECT_KEY} \
                                -Dsonar.sources=. \
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

        // 4️⃣ Quality Gate
        stage('Quality Gate') {
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                    script {
                        timeout(time: 8, unit: 'MINUTES') {
                            def qg = waitForQualityGate()
                            echo "✅ Quality Gate: ${qg.status}"
                            if (qg.status != 'OK') {
                                error "❌ Quality Gate failed!"
                            }
                        }
                    }
                }
            }
        }

        // 5️⃣ Trivy scan (ephemeral container)
        stage('Trivy FS Scan & Upload') {
            steps {
                script {
                    sh """
                        echo "🛡 Running Trivy scan using Jenkins volume..."
    
                        docker run --rm \
                            -v jenkins_home:/var/jenkins_home \
                            aquasec/trivy:latest fs /var/jenkins_home/workspace/DevSecOps/juice-shop \
                            --format json \
                            --output /var/jenkins_home/workspace/DevSecOps/trivy-report.json \
                            --debug || true

                            if [ -f "${WORKSPACE}/trivy-report.json" ]; then
                                echo "✅ Trivy report created successfully!"
                            else
                                echo "❌ Trivy report NOT created!"
                            fi
                            """
                }
            }
        }

        // 6️⃣ Upload Sonar report to DefectDojo
         stage('Upload Sonar Report to DefectDojo') {
            steps {
                script {
                    sh """
                        curl -s -u '${SONARQUBE_TOKEN}:' \
                        '${SONAR_HOST}/api/issues/search?projectKeys=${PROJECT_KEY}&ps=500' \
                        -o ${WORKSPACE}/sonar-report.json
                    """

                    sh """
                        curl -s -X POST '${DEFECTDOJO_URL}/api/v2/import-scan/' \
                        -H 'Authorization: Token ${DEFECTDOJO_API_KEY}' \
                        -F 'scan_type=SonarQube Scan' \
                        -F 'engagement=${DEFECTDOJO_ENGAGEMENT_ID}' \
                        -F 'file=@${WORKSPACE}/sonar-report.json'
                    """
                }
            }
        }


        // 7️⃣ Upload Trivy report to DefectDojo
        stage('Upload Trivy Report to DefectDojo') {
            steps {
                script {
                    sh """
                        curl -s -X POST '${DEFECTDOJO_URL}/api/v2/import-scan/' \
                        -H 'Authorization: Token ${DEFECTDOJO_API_KEY}' \
                        -F 'scan_type=Trivy Scan' \
                        -F 'engagement=${DEFECTDOJO_ENGAGEMENT_ID}' \
                        -F 'file=@${WORKSPACE}/trivy-report.json'
                    """
                }
            }
        }

        // 8️⃣ Build Docker Image
        stage('Build Docker Image') {
            steps {
                script {
                    echo "🚀 Building Docker image from Juice Shop source..."
                    dockerImage = docker.build(
                        "juice-shop:${env.BUILD_NUMBER}",
                        "./juice-shop"
                    )
                }
            }
        }

        // 9️⃣ Run Docker container
        stage('Run Juice Shop Container') {
            steps {
                script {
                    echo "🏃 Running container from image..."
                    sh '''
                        docker stop juice-app || true
                        docker rm juice-app || true
                    '''
                    sh "docker run -d --name juice-app -p 3000:3000 juice-shop:${BUILD_NUMBER}"
                    sleep 25
                    }
                }
            }
        }

        // 1️⃣ Stage: ZAP Scan
stage('ZAP Scan & Generate Report') {
    steps {
        script {
            sh """
            echo "🛡 Running OWASP ZAP scan..."

            # Chạy ZAP container tạm thời (daemon)
            docker run --rm -u zap -v ${WORKSPACE}:${WORKSPACE} \
                owasp/zap2docker-stable zap.sh -daemon -host 0.0.0.0 -port 8080 -config api.disablekey=true

            # Đợi ZAP sẵn sàng (hoặc dùng zap-cli / API check)
            sleep 10

            # Crawl Juice Shop
            docker run --rm -v ${WORKSPACE}:${WORKSPACE} owasp/zap2docker-stable zap-cli --zap-url http://host.docker.internal -p 8080 spider http://host.docker.internal:3000

            # Active scan
            docker run --rm -v ${WORKSPACE}:${WORKSPACE} owasp/zap2docker-stable zap-cli --zap-url http://host.docker.internal -p 8080 active-scan http://host.docker.internal:3000

            # Xuất report JSON
            docker run --rm -v ${WORKSPACE}:${WORKSPACE} owasp/zap2docker-stable zap-cli --zap-url http://host.docker.internal -p 8080 report -o ${WORKSPACE}/zap-report.json -f json

            # Kiểm tra file
            if [ -f "${WORKSPACE}/zap-report.json" ]; then
                echo "✅ ZAP report created successfully!"
            else
                echo "❌ ZAP report NOT created!"
            fi
            """
        }
    }
}

// 2️⃣ Stage: Upload ZAP report to DefectDojo
stage('Upload ZAP Report to DefectDojo') {
    steps {
        script {
            sh """
            curl -s -X POST '${DEFECTDOJO_URL}/api/v2/import-scan/' \
                 -H 'Authorization: Token ${DEFECTDOJO_API_KEY}' \
                 -F 'scan_type=ZAP Scan' \
                 -F 'engagement=${DEFECTDOJO_ENGAGEMENT_ID}' \
                 -F 'file=@${WORKSPACE}/zap-report.json'
            """
        }
    }
}



    post {
        success { echo '✅ Pipeline completed successfully!' }
        failure { echo '❌ Pipeline failed!' }
    }
}
