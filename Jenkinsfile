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
                                -Dsonar.login=\$SONARQUBE_TOKEN
                        """
                    }
                }
    steps {
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
stage('Wait for Processing') {
    steps {
        echo '⏳ Chờ SonarQube xử lý (2 phút)...'
        sleep time: 2, unit: 'MINUTES'
    }
}

stage('Quality Gate') {
    steps {
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

       stage('OWASP ZAP Baseline Scan') {
            steps {
                echo '🛡️ Running OWASP ZAP Baseline Scan...'
                sh '''
                    # Download ZAP baseline script
                    wget -q https://raw.githubusercontent.com/zaproxy/zaproxy/main/docker/zap-baseline.py -O zap-baseline.py
                    chmod +x zap-baseline.py
                    
                    # Kiểm tra ZAP container có hoạt động không
                    curl -f http://192.168.73.36:8082/ || { echo "❌ ZAP container not ready"; exit 1; }
                    
                    # Chạy scan sử dụng ZAP container có sẵn
                    python3 zap-baseline.py \
                        -t http://juice-shop-app:3000 \
                        -r zap-report.html \
                        -d http://zap:8080 \
                        -I -j -a
                    
                    # Alternative: sử dụng host network (comment không có backslash)
                    # python3 zap-baseline.py 
                    #     -t http://localhost:3000 
                    #     -r zap-report.html 
                    #     -d http://192.168.73.36:8082 
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
