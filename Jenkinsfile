pipeline {
  agent any
   stages {
    stage ('Build') {
      steps {
        sh '''#!/bin/bash
        python3.9 -m venv venv
        source venv/bin/activate
        pip install --upgrade pip
        pip install -r backend/requirements.txt
        
        # Check if Node.js and npm are installed, otherwise install them
        if ! command -v node &> /dev/null; then
          curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
          sudo apt-get install -y nodejs
        fi

        # Installing Frontend
        cd frontend
        export NODE_OPTIONS=--openssl-legacy-provider
        export CI=false
        npm ci
        '''
     }
   }
    stage ('Test') {
      steps {
        sh '''#!/bin/bash
        source venv/bin/activate
        pip install pytest-django
        python backend/manage.py makemigrations
        python backend/manage.py migrate
        pytest backend/account/tests.py --verbose --junit-xml test-reports/results.xml
        ''' 
      }
    }
   
     stage('Init') {
       steps {
          dir('Terraform') {
            sh 'terraform init'
            }
        }
      } 

     stage('Terraform Destroy') {
         steps {
           withCredentials([string(credentialsId: 'AWS_ACCESS_KEY', variable: 'aws_access_key'), 
                        string(credentialsId: 'AWS_SECRET_KEY', variable: 'aws_secret_key'),
                        string(credentialsId: 'db_password', variable: 'db_password')]) {
                            dir('Terraform') {
                              sh 'terraform destroy -auto-approve -var="aws_access_key=${aws_access_key}" -var="aws_secret_key=${aws_secret_key}" -var="db_password=${db_password}"' 
                            }
          }
        }
      }
     
      stage('Plan') {
        steps {
          withCredentials([string(credentialsId: 'AWS_ACCESS_KEY', variable: 'aws_access_key'), 
                        string(credentialsId: 'AWS_SECRET_KEY', variable: 'aws_secret_key'),
                        string(credentialsId: 'db_password', variable: 'db_password')]) {
                            dir('Terraform') {
                              sh 'terraform plan -out plan.tfplan -var="aws_access_key=${aws_access_key}" -var="aws_secret_key=${aws_secret_key}" -var="db_password=${db_password}"' 
                            }
          }
        }     
      }
      stage('Apply') {
        steps {
            dir('Terraform') {
                sh 'terraform apply plan.tfplan' 
                }
        }  
      }       
    }
  }
