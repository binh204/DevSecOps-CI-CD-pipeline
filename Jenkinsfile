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
            # Download script với curl
            echo "Downloading ZAP baseline script..."
            curl -s -o zap-baseline.py \
                https://raw.githubusercontent.com/zaproxy/zaproxy/main/docker/zap-baseline.py
            chmod +x zap-baseline.py
            
            # Kiểm tra dependencies
            echo "Checking dependencies..."
            python3 --version || { echo "❌ Python3 not found"; exit 1; }
            curl --version || { echo "❌ curl not found"; exit 1; }
            
            # Kiểm tra ZAP
            echo "Checking ZAP container..."
            curl -f http://192.168.73.36:8082/ || { echo "❌ ZAP not accessible"; exit 1; }
            
            # Kiểm tra ứng dụng - thử cả localhost và container name
            echo "Checking application..."
            if ! curl -f http://localhost:3000 >/dev/null 2>&1; then
                echo "⚠️ localhost:3000 not accessible, trying to start app..."
                docker run -d --name juice-shop-temp -p 3000:3000 bkimminich/juice-shop
                sleep 30
                curl -f http://localhost:3000 || { echo "❌ Failed to start application"; exit 1; }
            fi
            
            # Chạy ZAP scan - sử dụng localhost để đơn giản
            echo "Starting ZAP security scan..."
            python3 zap-baseline.py \
                -t http://localhost:3000 \
                -r zap-report.html \
                -d http://192.168.73.36:8082 \
                -I -j -a \
                -m 10
            
            echo "✅ ZAP scan completed"
        '''
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
