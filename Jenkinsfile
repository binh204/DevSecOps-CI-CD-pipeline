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

             // 1️⃣ Stage: ZAP Scan
    stage('ZAP Crawl & Active Scan') {
    steps {
        script {
            sh """
            echo "🛡 Starting OWASP ZAP daemon..."

            mkdir -p ${WORKSPACE}/zap-reports

            # Xóa container cũ nếu tồn tại
            docker rm -f zap-daemon || true

            # Start ZAP daemon với network host
            # Khởi động ZAP (daemon mode)
            docker run -d --name zap-daemon \
                -u zap \
                -p 8082:8082 \
                -v ${WORKSPACE}/zap-reports:/zap/wrk \
                zaproxy/zap-stable \
                zap.sh -daemon -host 0.0.0.0 -port 8082 -config api.disablekey=true
            echo "⏳ Waiting for ZAP to be ready..."

            # 🔥 Chờ ZAP khởi động hoàn tất thay vì sleep cứng
            for i in {1..100}; do
                if curl -s http://localhost:8082/JSON/core/view/version/ > /dev/null; then
                    echo "🚀 ZAP is ready!"
                    break
                fi
                echo "⏳ Still starting... retrying in 5sec"
                sleep 5
            done

            echo "🕷 Running Spider scan..."
            curl "http://localhost:8082/JSON/spider/action/scan/?url=http://localhost:3000"

            echo "⚡ Running Active scan..."
            curl "http://localhost:8082/JSON/ascan/action/scan/?url=http://localhost:3000"
            
            echo "📄 Generating ZAP HTML report..."
            docker exec zap-daemon zap.sh \
                -cmd -quickurl http://localhost:3000 \
                -quickout /zap/wrk/zap-report.html

            echo "🛑 Stopping ZAP daemon..."
            docker stop zap-daemon
            docker rm zap-daemon

            echo "📁 Report saved at: ${WORKSPACE}/zap-reports/"
            ls -lh ${WORKSPACE}/zap-reports
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
        }

    post {
        success { echo '✅ Pipeline completed successfully!' }
        failure { echo '❌ Pipeline failed!' }
    }
 }
