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

        // 3️⃣ Wait for SonarQube
        stage('Wait for Processing') {
            steps {
                sleep time: 2, unit: 'MINUTES'
            }
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

        // 5️⃣ Trivy SCAN using Docker container (ephemeral)
        stage('Trivy FS Scan (via Docker)') {
            steps {
                script {
                    sh """
                        docker run --rm \
                            -v \$(pwd):/app \
                            aquasec/trivy:latest fs /app/juice-shop \
                            --format json \
                            --output /app/trivy-report.json || true
                     """
               echo "📄 Trivy report generated: trivy-report.json"
                }
            }
        }


        // 6️⃣ Export Sonar → DefectDojo
        stage('Upload Sonar Report to DefectDojo') {
            steps {
                script {
                    sh """
                        curl -u ${SONARQUBE_TOKEN}: \
                        "${SONAR_HOST}/api/issues/search?projectKeys=${PROJECT_KEY}&ps=500" \
                        -o sonar-report.json
                    """

                    sh """
                        curl -X POST "${DEFECTDOJO_URL}/api/v2/import-scan/" \
                            -H "Authorization: Token ${DEFECTDOJO_API_KEY}" \
                            -F "scan_type=SonarQube Scan" \
                            -F "engagement=${DEFECTDOJO_ENGAGEMENT_ID}" \
                            -F "file=@sonar-report.json"
                    """
                }
            }
        }

        // 7️⃣ Upload Trivy → DefectDojo
        stage('Upload Trivy Report to DefectDojo') {
            steps {
                script {
                    sh """
                        curl -X POST "${DEFECTDOJO_URL}/api/v2/import-scan/" \
                            -H "Authorization: Token ${DEFECTDOJO_API_KEY}" \
                            -F "scan_type=Trivy Scan" \
                            -F "engagement=${DEFECTDOJO_ENGAGEMENT_ID}" \
                            -F "file=@trivy-report.json"
                    """
                }
            }
        }

        // 8️⃣ Build Docker image
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

        // 9️⃣ Run container
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

    } // end stages

    post {
        success { echo '✅ Pipeline completed successfully!' }
        failure { echo '❌ Pipeline failed!' }
    }
}
