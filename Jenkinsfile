pipeline {
    // Default agent: the Jenkins controller, which has the Docker CLI (talks to DinD).
    // Image build/push stages will run here later.
    agent any

    options {
        skipDefaultCheckout(true)                       // we checkout explicitly in a stage below
        buildDiscarder(logRotator(numToKeepStr: '10'))  // keep only the last 10 builds
        timeout(time: 30, unit: 'MINUTES')              // don't let a stuck build hang forever
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
    }

    post {
        always {
            deleteDir()   // clean the workspace after every run
        }
    }
}
