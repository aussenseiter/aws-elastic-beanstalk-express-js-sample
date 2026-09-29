pipeline {
    // Default agent: the Jenkins controller, which has the Docker CLI (talks to DinD).
    // Image build/push stages will run here later.
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
                sh 'npm test'
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
    }

    post {
        always {
            // Keep the audit report downloadable from the build page, even when the build fails
            archiveArtifacts artifacts: 'reports/**', allowEmptyArchive: true
            deleteDir()
        }
    }
}
