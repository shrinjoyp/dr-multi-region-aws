pipeline {
  agent any
  environment {
    TF_IN_AUTOMATION = 'true'
    AWS_DEFAULT_REGION = "${PRIMARY_REGION ?: 'us-east-1'}"
  }
  stages {
    stage('Checkout') { steps { checkout scm } }
    stage('Setup Terraform') {
      steps {
        sh 'terraform -version'
      }
    }
    stage('Fmt & Validate') {
      steps {
        sh 'terraform fmt -recursive -check'
        sh 'terraform init -input=false'
        sh 'terraform validate'
      }
    }
    stage('Plan') {
      steps {
        sh 'terraform plan -input=false -out=tfplan'
      }
    }
    stage('Approve') {
      steps {
        input message: 'Apply Terraform changes?', ok: 'Apply'
      }
    }
    stage('Apply') {
      steps {
        sh 'terraform apply -input=false tfplan'
      }
    }
  }
  post {
    always { archiveArtifacts artifacts: '**/terraform.tfstate*', fingerprint: true, onlyIfSuccessful: false }
  }
}
