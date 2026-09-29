pipeline {
    // Default agent: the Jenkins controller, which has the Docker CLI (talks to DinD).    
    agent any

    options {
        skipDefaultCheckout(true)                       // we checkout explicitly in a stage below
        buildDiscarder(logRotator(numToKeepStr: '10'))  // keep only the last 10 builds
        timeout(time: 30, unit: 'MINUTES')              // don't let a stuck build hang forever
        timestamps()                                    // add timestamps on every line
    }

    environment {
        // Keep npm's cache inside the workspace; the container user can't write to /.npm
        npm_config_cache = "${WORKSPACE}/.npm"
        IMAGE_NAME = 'aldenjunus/isec6000-a2-app'   // My Docker Hub repo
    }

    triggers {
        // Check GitHub for new commits on main roughly every 5 minutes
        pollSCM('H/5 * * * *')
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Install Dependencies') {
            // Brief requirement: Node 16 image as the build agent.
            // reuseNode keeps the same workspace, so the checked-out code is already there.
            agent {
                docker {
                    image 'node:16'
                    reuseNode true
                }
            }
            steps {
                sh 'node -v && npm -v'
                sh 'npm ci'
            }
        }

        stage('Unit Tests') {
            // Same Node 16 agent and same workspace, so node_modules from the
            // install stage is already here (no reinstall needed)
            agent {
                docker {
                    image 'node:16'
                    reuseNode true
                }
            }
            steps {
                sh 'npm test'           // readable output in the console log
                sh 'npm run test:ci'    // JUnit XML for Jenkins
            }
        }

        stage('Dependency Scan') {
            // Security gate: npm audit checks every dependency against known CVEs
            agent {
                docker {
                    image 'node:16'
                    reuseNode true
                }
            }
            steps {
                sh 'mkdir -p reports'
                // Save the full report for archiving; "|| true" so this line never fails the build
                sh 'npm audit --json > reports/npm-audit.json || true'
                // The actual gate: exits non-zero (fails the build) on High or Critical findings
                sh 'npm audit --audit-level=high'
            }
        }

        stage('Build Docker Image') {
            // No agent block: runs on the controller, which has the Docker CLI (talks to DinD over TLS)
            steps {
                sh '''
                    SHORT_SHA=$(git rev-parse --short HEAD)
                    # Tag with build number and commit SHA so every image traces back to a build and a commit
                    docker build -t "$IMAGE_NAME:$BUILD_NUMBER" -t "$IMAGE_NAME:$SHORT_SHA" .
                    docker image ls "$IMAGE_NAME"
                '''
            }
        }

        stage('Push to Docker Hub') {
            steps {
                // Inject Docker Hub credentials only for this block; Jenkins masks them as **** in the log
                withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials',
                                                  usernameVariable: 'DOCKER_USER',
                                                  passwordVariable: 'DOCKER_TOKEN')]) {
                    sh '''
                        SHORT_SHA=$(git rev-parse --short HEAD)
                        # --password-stdin keeps the token out of the process list and shell history
                        echo "$DOCKER_TOKEN" | docker login -u "$DOCKER_USER" --password-stdin
                        docker push "$IMAGE_NAME:$BUILD_NUMBER"
                        docker push "$IMAGE_NAME:$SHORT_SHA"
                        docker logout
                    '''
                }
            }
        }
    }

    post {
        always {
            junit testResults: 'reports/test-results.xml', allowEmptyResults: true
            // Keep the audit report downloadable from the build page, even when the build fails
            archiveArtifacts artifacts: 'reports/**', allowEmptyArchive: true
            deleteDir()
        }
    }
}
