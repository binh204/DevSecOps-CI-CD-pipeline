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
        ZAP_API_KEY = 'binh204'
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
        stage('ZAP Crawl & Active Scan') {
    steps {
        script {
            sh '''
            echo "🛡 Start OWASP ZAP Daemon MODE (host network)"

            mkdir -p $WORKSPACE/zap-reports
            docker rm -f zap-daemon || true

            docker run -d --name zap-daemon \
                --network host \
                -v $WORKSPACE/zap-reports:/zap/wrk \
                zaproxy/zap-stable zap.sh -daemon -port 8080 -host 0.0.0.0 \
                -config api.addrs.addr.name=.* \
                -config api.addrs.addr.regex=true \
                -config api.disablekey=false \
                -config api.key=$ZAP_API_KEY \

            echo "⏳ Wait ZAP REST API ready..."
            for i in $(seq 1 60); do
                if curl -s http://localhost:8080/JSON/core/view/version/ > /dev/null; then
                    echo "🔥 ZAP API Ready!"
                    break
                fi
                sleep 2
            done

            echo "🕷 Spidering..."
            curl "http://localhost:8080/JSON/spider/action/scan/?apikey=$ZAP_API_KEY&url=http://localhost:3000&recurse=true"

            echo "⚡ Active Scan..."
            curl "http://localhost:8080/JSON/ascan/action/scan/?apikey=$ZAP_API_KEY&url=http://localhost:3000"

            echo "📄 Generating HTML report via API (không spawn ZAP lần 2)"
            curl "http://localhost:8080/OTHER/core/other/htmlreport/?apikey=$ZAP_API_KEY&" \
                --output $WORKSPACE/zap-reports/zap-report.xml

            docker stop zap-daemon && docker rm zap-daemon
            echo "📁 Report saved to workspace/zap-reports"
            ls -lh $WORKSPACE/zap-reports
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
