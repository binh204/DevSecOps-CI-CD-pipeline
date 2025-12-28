pipeline {
    agent any
    environment {
        SONARQUBE_SERVER = 'SonarQube'
        SONAR_HOST = 'http://192.168.73.36:9000'
        PROJECT_KEY = 'DevSecOps'

        SONARQUBE_TOKEN = credentials('sonar-token')
        DEFECTDOJO_API_KEY = credentials('defectdojo-api')

        DEFECTDOJO_URL = 'http://192.168.73.36:8090'
        DEFECTDOJO_ENGAGEMENT_ID = '2'

        DOCKER_REGISTRY = 'docker.io'
        DOCKER_IMAGE = 'binh204/juice-shop'

        DOCKER_CREDS = credentials('dockerhub-credential')

    }
    
    stages {  
        // 2️⃣ CODE -----------------------------------------------------------------------------------------------
        stage('Checkout code') {
            steps {
                git branch: 'main', credentialsId: 'github-credentials',
                    url: 'https://github.com/binh204/DevSecOps'
            }
        }

        // 3️⃣ BUILD ------------------------------------------------------------------------------------------        
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
/*
        // 4️⃣ TEST -----------------------------------------------------------------------------------------------    
        stage('SonarQube Stactic Code Analysis') {
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

        // Wait for SonarQube processing
        stage('Wait for Processing') {
            steps { sleep time: 2, unit: 'MINUTES' }
        }

        // Quality Gate
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

        // Upload Sonar report to DefectDojo
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
        
        //Trivy Image SBOM & SCA Scan
        stage('Trivy Image SBOM & SCA Scan') {
            steps {
                script {
                    sh """
                        echo "📦 Generating SBOM from Docker image..."
        
                        docker run --rm \
                          -v /var/run/docker.sock:/var/run/docker.sock \
                          -v jenkins_home:/var/jenkins_home \
                          aquasec/trivy:latest image \
                          juice-shop:${BUILD_NUMBER} \
                          --format cyclonedx \
                          --output /var/jenkins_home/workspace/DevSecOps/sbom-juice-shop.json \
                          --debug
        
                        if [ -f "${WORKSPACE}/sbom-juice-shop.json" ]; then
                            echo "✅ SBOM generated successfully!"
                        else
                            echo "❌ SBOM generation failed!"
                            exit 1
                        fi
        
                        echo "🔍 Running SCA scan using SBOM as input..."
        
                        docker run --rm \
                          -v jenkins_home:/var/jenkins_home \
                          aquasec/trivy:latest sbom \
                          /var/jenkins_home/workspace/DevSecOps/sbom-juice-shop.json \
                          --format json \
                          --output /var/jenkins_home/workspace/DevSecOps/trivy-report.json \
                          --severity HIGH,CRITICAL \
                          --debug || true
        
                        if [ -f "${WORKSPACE}/trivy-report.json" ]; then
                            echo "✅ Trivy SCA report created successfully!"
                        else
                            echo "❌ Trivy SCA report NOT created!"
                        fi
                    """
                }
            }
        }

       //Upload Trivy report to DefectDojo
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

        //Run container
        stage('Run Juice Shop Container') {
            steps {
                script {
                    echo "🧹 Cleaning up previous Docker image..."
                        // Tính build trước đó
                        def previousBuild = env.BUILD_NUMBER.toInteger() - 1
                        if (previousBuild > 0) {
                        sh "docker rmi -f juice-shop:${previousBuild} || true"
                        sh "docker rmi -f binh204/juice-shop:${previousBuild} || true"
                        }
 
                    echo "🏃 Running container from image..."
                    sh '''
                        docker stop juice-app || true
                        docker rm juice-app || true
                    '''
            
                    sh "docker run -d --name juice-app --network devsecops -p 3000:3000 juice-shop:${BUILD_NUMBER}"
                    sleep 25
                    }
                }
            }
          */
        // 5️⃣ RELEASE -----------------------------------------------------------------------------------------------
        // Image Supply Chain: Tag, Attach SBOM, Sign & Push
        stage('Tag, SBOM, Sign & Push Image') {
            steps {
                script {
                    withCredentials([file(credentialsId: 'Cosign-private-key', variable: 'COSIGN_KEY_FILE')]) {
                        withEnv(['COSIGN_PASSWORD=']) {
                            sh """
                                set -e
        
                                FULL_IMAGE=${DOCKER_REGISTRY}/${DOCKER_IMAGE}:${BUILD_NUMBER}
        
                                echo "🏷 Tagging image..."
                                docker tag juice-shop:${BUILD_NUMBER} \$FULL_IMAGE
        
                                echo "🔐 Login to Docker Registry..."
                                echo "$DOCKER_CREDS_PSW" | docker login ${DOCKER_REGISTRY} \
                                    -u "$DOCKER_CREDS_USR" --password-stdin
        
                                echo "🚀 Pushing image to registry..."
                                docker push \$FULL_IMAGE
        
                                echo "🔍 Getting image digest..."
                                DIGEST=\$(docker inspect --format='{{index .RepoDigests 0}}' \$FULL_IMAGE)
                                echo "Image digest: \$DIGEST"
        
                                echo "📎 Attaching SBOM (artifact)..."
                                cosign attach sbom \
                                  --sbom ${WORKSPACE}/sbom-juice-shop.json \
                                  \$DIGEST
        
                                echo "📦 Attesting SBOM (SPDX predicate)..."
                                COSIGN_PASSWORD="" cosign attest \
                                  --predicate ${WORKSPACE}/sbom-juice-shop.json \
                                  --type spdxjson \
                                  --key \$COSIGN_KEY_FILE \
                                  \$DIGEST
        
                                echo "✍️ Signing image digest..."
                                COSIGN_PASSWORD="" cosign sign --key \$COSIGN_KEY_FILE \$DIGEST
        
                                echo "✅ Image pushed, SBOM attached & attested, image signed successfully!"
                            """
                        }
                    }
                }
            }
        }
      
        // 6️⃣ DEPLOY -----------------------------------------------------------------------------------------------
        stage('Run Juice Shop Container on Staging Environment') {
            steps {
                script {
                    withCredentials([file(credentialsId: 'Cosign-public-key', variable: 'COSIGN_PUB_KEY')]) {
                    echo "🏃 Pulling & verifying signed image for Staging..."
        
                    sh """
                        set -e
                        IMAGE=${DOCKER_REGISTRY}/${DOCKER_IMAGE}:${BUILD_NUMBER}
        
                        # Stop & remove old container 
                        docker stop juice-app || true
                        docker rm juice-app || true
        
                        echo "📥 Pulling image \$IMAGE"
                        docker pull \$IMAGE
        
                        echo "🔍 Getting image digest"
                        DIGEST=\$(docker inspect --format='{{index .RepoDigests 0}}' \$IMAGE)

                        unset COSIGN_KEY
                        echo "🔎 Debug public key used for verify:"
                        head -n 3 $COSIGN_PUB_KEY
                        
                        echo "🔐 Verifying IMAGE SIGNATURE"
                        cosign verify \
                          --key \$COSIGN_PUB_KEY \
                          \$DIGEST

                        echo "📦 Verifying SBOM ATTESTATION"
                        cosign verify-attestation \
                          --key \$COSIGN_PUB_KEY \
                          --type spdxjson \
                         \$DIGEST
        
                        echo "🚀 Running container on Staging"
                        docker run -d \
                          --name juice-app \
                          --network devsecops \
                          -p 9050:3000 \
                          -e NODE_ENV=staging \
                          --restart unless-stopped \
                          \$IMAGE
                    """
                    sleep 25
                }
            }
        }
    }
       // ---------------------------------------------------------------------------------------------------------------------------------
 }
    post {
        success { echo '✅ Pipeline completed successfully!' }
        failure { echo '❌ Pipeline failed!' }
    }
 }
