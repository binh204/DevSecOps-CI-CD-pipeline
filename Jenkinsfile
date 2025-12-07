pipeline {
    agent any
    environment {
        SONARQUBE_SERVER = 'SonarQube'
        SONAR_HOST = 'http://192.168.73.36:9000'
        PROJECT_KEY = 'DevSecOps'

        SONARQUBE_TOKEN = credentials('sonar-token')
        DEFECTDOJO_API_KEY = credentials('defectdojo-api')

        DEFECTDOJO_URL = 'http://192.168.73.36:8080'
        DEFECTDOJO_ENGAGEMENT_ID = '2'
    }
    
    stages {
    /*
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
                                -Dsonar.sources=./juice-shop\
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
      */
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
                    echo "🧹 Cleaning up previous Docker image..."
                        // Tính build trước đó
                        def previousBuild = env.BUILD_NUMBER.toInteger() - 1
                        if (previousBuild > 0) {
                        sh "docker rmi -f juice-shop:${previousBuild} || true"
                        }
 
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
        stage('ZAP Crawl & Active Scan - Fixed') {
    steps {
        script {
            sh '''
            TARGET="http://localhost:3000"
            ZAP_API_KEY="binh204"
            ZAP_HOST="localhost"
            ZAP_PORT="8080"
            REPORT_DIR="$WORKSPACE/zap-reports"
            
            echo "🛡 Starting OWASP ZAP Daemon"
            
            # Clean up và tạo thư mục
            mkdir -p $REPORT_DIR
            docker rm -f zap-daemon || true
            
            # Khởi động ZAP với đúng cấu hình
            docker run -d --name zap-daemon \
                --network host \
                -v $REPORT_DIR:/zap/wrk \
                zaproxy/zap-stable zap.sh -daemon \
                -port $ZAP_PORT -host 0.0.0.0 \
                -config api.disablekey=false \
                -config api.key=$ZAP_API_KEY \
                -config api.addrs.addr.name=.* \
                -config api.addrs.addr.regex=true \
                -config connection.timeoutInSecs=120
            
            echo "⏳ Waiting for ZAP to fully start..."
            sleep 45
            
            # Test connection với API key đúng format
            echo "🔍 Testing ZAP API with proper authentication..."
            
            # Cách 1: Sử dụng X-ZAP-API-Key header
            API_TEST=$(curl -s -H "X-ZAP-API-Key: $ZAP_API_KEY" \
                "http://$ZAP_HOST:$ZAP_PORT/JSON/core/view/version/")
            echo "API Test Response: $API_TEST"
            
            # Cách 2: Thêm target vào ZAP context trước
            echo "🌐 Adding target to ZAP..."
            curl -s -H "X-ZAP-API-Key: $ZAP_API_KEY" \
                "http://$ZAP_HOST:$ZAP_PORT/JSON/core/action/accessUrl/?url=$TARGET"
            
            sleep 10
            
            # 1. SPIDER SCAN - Sử dụng GET request để tránh CSRF
            echo "🕷 Starting Spider Scan (GET method)..."
            SPIDER_ID=$(curl -s -H "X-ZAP-API-Key: $ZAP_API_KEY" \
                "http://$ZAP_HOST:$ZAP_PORT/JSON/spider/action/scan/?url=$TARGET&maxChildren=5&recurse=true&contextName=" | \
                grep -o '"scan":"[0-9]*"' | cut -d'"' -f4)
            
            echo "Spider Scan ID: $SPIDER_ID"
            echo "⏳ Waiting for spider to complete (120 seconds)..."
            
            # Theo dõi tiến trình spider
            for i in {1..12}; do
                sleep 10
                STATUS=$(curl -s -H "X-ZAP-API-Key: $ZAP_API_KEY" \
                    "http://$ZAP_HOST:$ZAP_PORT/JSON/spider/view/status/?scanId=$SPIDER_ID" 2>/dev/null || echo "0")
                echo "Spider progress: $STATUS%"
            done
            
            # 2. ACTIVE SCAN - Sử dụng GET request
            echo "⚡ Starting Active Scan (GET method)..."
            ASCAN_ID=$(curl -s -H "X-ZAP-API-Key: $ZAP_API_KEY" \
                "http://$ZAP_HOST:$ZAP_PORT/JSON/ascan/action/scan/?url=$TARGET&recurse=true&inScopeOnly=true&scanPolicyName=Default Policy" | \
                grep -o '"scan":"[0-9]*"' | cut -d'"' -f4)
            
            echo "Active Scan ID: $ASCAN_ID"
            echo "⏳ Waiting for active scan (300 seconds)..."
            
            # Theo dõi tiến trình active scan
            for i in {1..30}; do
                sleep 10
                STATUS=$(curl -s -H "X-ZAP-API-Key: $ZAP_API_KEY" \
                    "http://$ZAP_HOST:$ZAP_PORT/JSON/ascan/view/status/?scanId=$ASCAN_ID" 2>/dev/null || echo "0")
                echo "Active scan progress: $STATUS%"
            done
            
            # 3. TẠO REPORTS
            echo "📄 Generating reports..."
            
            # Kiểm tra alerts trước
            echo "🔍 Checking for alerts..."
            curl -s -H "X-ZAP-API-Key: $ZAP_API_KEY" \
                "http://$ZAP_HOST:$ZAP_PORT/JSON/core/view/alerts/?baseurl=$TARGET" > $REPORT_DIR/alerts.json
            
            # HTML Report - ĐÚNG CÚ PHÁP
            echo "Generating HTML report..."
            curl -s "http://$ZAP_HOST:$ZAP_PORT/OTHER/core/other/htmlreport/" \
                -H "X-ZAP-API-Key: $ZAP_API_KEY" \
                -o $REPORT_DIR/zap-report.html
            
            # XML Report cho DefectDojo - ĐÚNG CÚ PHÁP
            echo "Generating XML report..."
            curl -s "http://$ZAP_HOST:$ZAP_PORT/OTHER/core/other/xmlreport/" \
                -H "X-ZAP-API-Key: $ZAP_API_KEY" \
                -o $REPORT_DIR/zap-report.xml
            
            # Cleanup
            docker stop zap-daemon || true
            docker rm zap-daemon || true
            
            echo "✅ Scan completed!"
            echo "📁 Reports in $REPORT_DIR:"
            ls -la $REPORT_DIR/
            
            # Check report sizes
            echo "📊 Report sizes:"
            du -h $REPORT_DIR/*.html $REPORT_DIR/*.xml 2>/dev/null || true
            '''
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
                 -F 'file=@${WORKSPACE}/zap-reports/zap-report.xml'
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
