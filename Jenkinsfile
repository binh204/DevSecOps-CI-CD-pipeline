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

        stage('Build') {
            steps {
                echo '⚙️ Building the project...'
                sh 'echo "Build process simulation - no errors."'
            }
        }

        stage('SonarQube Analysis with Webhook') {
    steps {
        script {
            def scannerHome = tool name: 'SonarQube', type: 'hudson.plugins.sonar.SonarRunnerInstallation'
            withSonarQubeEnv("${SONARQUBE_SERVER}") {
                sh """
                    ${scannerHome}/bin/sonar-scanner \
                        -Dsonar.projectKey=DevSecOps \
                        -Dsonar.projectName=DevSecOps \
                        -Dsonar.projectVersion=1.0 \
                        -Dsonar.sources=juice-shop \
                        -Dsonar.login=${SONARQUBE_TOKEN} \
                        -Dsonar.qualitygate.wait=false
                """
            }
        }
    }
}

stage('Manual Quality Gate Check') {
    steps {
        echo '⏳ Waiting for analysis completion (manual check)...'
        sleep time: 3, unit: 'MINUTES'
        
        script {
            // Lấy task ID và kiểm tra thủ công
            def taskId = sh(
                script: 'cat .scannerwork/report-task.txt | grep ceTaskId | cut -d\\= -f2',
                returnStdout: true
            ).trim()
            
            echo "📊 Check SonarQube dashboard manually: http://192.168.73.36:9000/dashboard?id=DevSecOps"
            echo "📋 Task ID: ${taskId}"
            
            // Hoặc sử dụng API để kiểm tra
            sh """
                echo "Checking analysis status via API..."
                curl -s -u ${SONARQUBE_TOKEN}: "http://192.168.73.36:9000/api/qualitygates/project_status?projectKey=DevSecOps" | jq .
            """
        }
    }
}
        stage('Quality Gate') {
            steps {
                script {
                    timeout(time: 15, unit: 'MINUTES') {  // timeout 15 phút
                    timeout(time: 1, unit: 'MINUTES') {  // timeout 15 phút
                        def qg = waitForQualityGate()
                        echo "Quality Gate status: ${qg.status}"
                        if (qg.status != 'OK') {
                            error "Pipeline failed due to Quality Gate: ${qg.status}"
                        }
                    }
                }
            }
        }

        stage('OWASP ZAP Baseline Scan') {
            steps {
                echo '🛡️ Running OWASP ZAP Baseline Scan...'
                sh '''
                    docker run --rm --network host -v $(pwd):/zap/wrk/ \
                        owasp/zap2docker-stable zap-baseline.py \
                        -t http://localhost:3000 \
                        -r zap-report.html
                '''
            }
        }

        stage('Publish ZAP Report') {
            steps {
                echo '📄 Publishing OWASP ZAP Report...'
                archiveArtifacts artifacts: 'zap-report.html', fingerprint: true
            }
        }

        stage('Upload ZAP Report to DefectDojo') {
            steps {
                echo '🚀 Uploading ZAP scan results to DefectDojo...'
                sh '''
                    curl -X POST "http://192.168.73.36:8080/api/v2/import-scan/" \
                        -H "Authorization: Token ${DEFECTDOJO_API_KEY}" \
                        -F "file=@zap-report.html" \
                        -F "scan_type=ZAP Scan" \
                        -F "product=1" \
                        -F "engagement=1" \
                        -F "active=true" \
                        -F "verified=false"
                '''
            }
        }
    }

    post {
        success {
            echo '✅ Pipeline completed successfully with SonarQube + ZAP + DefectDojo!'
        }
        failure {
            echo '❌ Pipeline failed! Check console logs for details.'
        }
        always {
            echo '🏁 Pipeline finished.'
        }
    }
}
