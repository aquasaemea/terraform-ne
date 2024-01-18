# Deploying and Testing Aqua Nano Enforcer on AWS Lambda Using Terraform and GitHub Actions

The purpose of this pipeline is to deploy an AWS Lambda Function, Layer and S3 Bucket with the required IAM roles, and finally an Aqua Nano Enforcer.

There were three key criteria that also need to be met:

1. It must all be deployed using Terraform and using GitHub Actions.
2. It must also have the ability to be destroyed using terraform
3. It must also provide a test to demonstrate the Nano Enforcer’s capabilities

**N.B.**
1. You will need to have the correct Secrets and Variables configured for this tor work and
2. You will need to have required AWS CLI configuration already in place.

**Secrets required:**

AQUA_KEY,

AQUA_SECRET,

AWS_ACCESS_KEY_ID,

AWS_REGION,

AWS_SECRET_ACCESS_KEY,

GH_TOKEN,



## Prerequities Deployment
To Deploy the pipeline for demo purposes you must deploy the prerequisites pipeline first as this iwll deploy the S3 Bucket for the terraform state to be saved into and also set up the DynamoDB lock.

To Deploy the Prerequisites pipeline:

This workflow has a workflow_dispatch event trigger.

1. Actions > Demo-prerequisites > Run Workflow = true > run workflow

## Aqua and Terraform Deployment
Once this has been deployed you may proceed onto the main deployment: Aqua and Terraform Pipeline

This workflow has a workflow_dispatch event trigger.

1. Actions > Aqua and Terraform Pipeline > Run Workflow = true > run workflow
2. This will require a Manual Approval to complete

### Manual Approval Process:
1. Issues > select issue > 'Approve or Deny pipline'  > Comment

## Testing:
Once everything is setup, within the function you will have a test file called index.py

This test is set up to be as easy to test as possible and makes use of an environment variable which is set up during the build process

the Environment variable is called 'LAMBDA_BEHAVIOR' is by default set to block. This is not providing any blocking it is telling the test which test to run. The index.py file contains two tests: 

1. Demonstrates the configured blocking configuration set in the NanoEnforcer Runtime Policy and
2. Demonstrates events allowed by the NanoEnforcer Runtime Policy configuration.

A. Set the desired state for the 'LAMBDA_BEHAVIOR' environment variable to either "block" or "detect"
AWS Function > Configuration > Environment Variables > LAMBDA_BEHAVIOR = "block" / "detect"

1. Select 'index.py' click Test
2. Configure Test: use the contents of the file 'test_event.json'
3. Invoke the test (no need to save it)

Repeat the test with other 'LAMBDA_BEHAVIOR' configuration option

## Destroy Deployment
Finally when all testing is complete you will need to destroy the environment.

This workflow has a workflow_dispatch event trigger.

1. Actions > Aqua and Terraform Destroy pipeline > Run Workflow = true > run workflow
2. This will require a Manual Approval to complete

**N.B. This will not destroy the configuration added as part of the prerequisites and so this will have to be removed manually.**
