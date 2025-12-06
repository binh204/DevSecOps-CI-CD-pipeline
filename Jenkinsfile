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
            apt-get update && apt-get install -y jq  
            echo "🛡 Starting OWASP ZAP daemon..."

            mkdir -p ${WORKSPACE}/zap-reports

            # Xóa container cũ nếu tồn tại
            docker rm -f zap-daemon || true

            # Khởi động ZAP với API mở cho Jenkins (fix unhealthy + empty reply)
            docker run -d --name zap-daemon \
                -u zap \
                -p 8082:8082 \
                -v ${WORKSPACE}/zap-reports:/zap/wrk \
                zaproxy/zap-stable zap.sh -daemon \
                -host 0.0.0.0 -port 8082 \
                -config api.disablekey=true \
                -config api.addrs.addr.name=.* \
                -config api.addrs.addr.regex=true

            echo "⏳ Waiting for ZAP to be ready..."
            for i in {1..30}; do
                if curl -s http://localhost:8082/JSON/core/view/version/ > /dev/null; then
                    echo "🚀 ZAP is running!"
                    break
                fi
                echo "⏳ ZAP not ready yet... retrying..."
                sleep 5
            done

            echo "🕷 Starting Spider Scan..."
            SCANID=\$(curl -s "http://localhost:8082/JSON/spider/action/scan/?url=http://juice-app:3000" | jq -r .scan)

            echo "⏳ Waiting Spider to complete..."
            while [ "\$(curl -s http://localhost:8082/JSON/spider/view/status/?scanId=\$SCANID | jq -r .status)" != "100" ]; do
                sleep 5
            done
            echo "🕸 Spider completed!"

            echo "⚡ Starting Active Scan..."
            ASCANID=\$(curl -s "http://localhost:8082/JSON/ascan/action/scan/?url=http://juice-app:3000" | jq -r .scan)

            echo "⏳ Waiting Active Scan to complete..."
            while [ "\$(curl -s http://localhost:8082/JSON/ascan/view/status/?scanId=\$ASCANID | jq -r .status)" != "100" ]; do
                sleep 10
            done
            echo "⚡ Active Scan completed!"

            echo "📄 Generating ZAP Reports..."
            curl "http://localhost:8082/OTHER/core/other/htmlreport/" -o ${WORKSPACE}/zap-reports/zap-report.html
            curl "http://localhost:8082/OTHER/core/other/xmlreport/" -o ${WORKSPACE}/zap-reports/zap-report.xml
            curl "http://localhost:8082/OTHER/core/other/jsonreport/" -o ${WORKSPACE}/zap-reports/zap-report.json

            echo "🛑 Cleaning ZAP container..."
            docker stop zap-daemon && docker rm zap-daemon

            echo "📁 Reports generated in workspace: ${WORKSPACE}/zap-reports"
            ls -lah ${WORKSPACE}/zap-reports
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
