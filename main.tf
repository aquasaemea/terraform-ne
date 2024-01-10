# Store Terraform state file in S3 bucket
terraform {
  backend "s3" {
    bucket         = "ne-tf-s3-state"  # Replace with your desired S3 bucket name
    key            = "terraform.tfstate"
    region         = "eu-west-2"  # Replace with your desired AWS region
    encrypt        = true
    dynamodb_table = "terraform_locks"  # Replace with your desired DynamoDB table name
  }
}

# Create an S3 bucket for NanoEnforcer
resource "aws_s3_bucket" "my_bucket" {
  bucket = "ne-tf-s3"  # Replace with your desired bucket name
}

# Upload a file to the S3 bucket
resource "aws_s3_object" "aqua_runtime_object" {
  bucket = aws_s3_bucket.my_bucket.id
  key    = "aqua_runtime_23_08_2023-12_32.zip"  # Replace with your desired file name
  source = "./zipfiles/aqua_runtime_23_08_2023-12_32.zip"  # Replace with the local path to your zip file
}

# Upload a file to the S3 bucket
resource "aws_s3_object" "test_script_object" {
  bucket = aws_s3_bucket.my_bucket.id
  key    = "testscript.sh"  # Replace with your desired file name
  source = "./testscript.sh"  # Replace with the local path to your zip file
}

# Create an AWS Lambda layer resource
resource "aws_lambda_layer_version" "my_lambda_layer" {
  layer_name          = "ne-layer-example-01"
  description         = "Aqua Nano Enforcer for Lambda Functions"
  compatible_runtimes = ["python3.8"]

# Generate file hash from the uploaded zip file in the S3 bucket
  source_code_hash = filebase64sha256(aws_s3_object.aqua_runtime_object.source)
  s3_bucket        = aws_s3_bucket.my_bucket.bucket
  s3_key = aws_s3_object.aqua_runtime_object.key
}

# Create an AWS Lambda function
resource "aws_lambda_function" "my_lambda_function" {
  function_name = "ne-function-example-01"
  description   = "Function designed to test the NanoEnforcer"
  runtime       = "python3.8" # Set the appropriate runtime for your Lambda function
  handler       = "index.handler" # Set the appropriate handler for your Lambda function

  # Add other desired function configuration here
  # For example, uncomment the following lines to specify the runtime and handler:
  # runtime = "nodejs14.x"
  # handler = "index.handler"

  # Add other desired function properties here

  # Attach the Lambda layer to the function
  layers = [aws_lambda_layer_version.my_lambda_layer.arn]

  # Environment variables
  environment {
    variables = {
      AQUA_GATEWAY = "225fccbcb7-gw.cloud.aquasec.com:443"
      AQUA_SQS_URL = "https://sqs.eu-west-2.amazonaws.com/470823723635/aquaaudit",
      LAMBDA_BEHAVIOUR = "block" # Set to 'block' or 'detect' when demonstrating the NanoEnforcer capabilities
      # Add more variables as needed
    }
  }

  # Create a new IAM role with basic Lambda permissions if it doesn't exist
  count = var.create_lambda_execution_role ? 1 : 0

  role             = aws_iam_role.lambda_execution_role[count.index].arn
  filename         = "${path.module}/index.zip"
  source_code_hash = filebase64sha256("${path.module}/index.zip")
}

# Create an IAM role for the Lambda function
resource "aws_iam_role" "lambda_execution_role" {
  count = var.create_lambda_execution_role ? 1 : 0

  name = "ne-s3-lambda-execution-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Create a custom IAM policy for Lambda permissions
resource "aws_iam_policy" "lambda_custom_policy" {
  name = "lambda-custom-policy"

  # Define policy document with necessary permissions
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        "Effect": "Allow",
        "Action": [
          "s3:GetObject",
          "s3:ListBucket"
        ],
        "Resource": [
          "arn:aws:s3:::ne-tf-s3",
          "arn:aws:s3:::ne-tf-s3/*"
        ]
      },
      {
        "Effect": "Allow",
        "Action": [
          "lambda:InvokeFunction"
        ],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "sqs:SendMessage"
        ],
        "Resource": "arn:aws:sqs:eu-west-2:470823723635:aquaaudit"  # Replace with your SQS queue ARN
      },
      {
        "Effect": "Allow",
        "Action": [
            "iam:GenerateServiceLastAccessedDetails",
            "iam:GetGroupPolicy",
            "iam:GetPolicy",
            "iam:GetPolicyVersion",
            "iam:GetRolePolicy",
            "iam:GetServiceLastAccessedDetails",
            "iam:GetServiceLastAccessedDetailsWithEntities",
            "iam:GetUser",
            "iam:GetUserPolicy",
            "iam:ListAttachedGroupPolicies",
            "iam:ListAttachedRolePolicies",
            "iam:ListAttachedUserPolicies",
            "iam:ListGroupPolicies",
            "iam:ListGroupsForUser",
            "iam:ListRolePolicies",
            "iam:ListUserPolicies"
        ],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": [
            "cloudwatch:GetMetricData",
            "cloudwatch:ListMetrics"
        ],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": [
            "lambda:DeleteFunctionConcurrency",
            "lambda:DeleteLayerVersion",
            "lambda:GetFunction",
            "lambda:GetFunctionConfiguration",
            "lambda:GetLayerVersion",
            "lambda:GetPolicy",
            "lambda:ListAliases",
            "lambda:ListEventSourceMappings",
            "lambda:ListFunctions",
            "lambda:ListTags",
            "lambda:PublishLayerVersion",
            "lambda:PutFunctionConcurrency",
            "lambda:TagResource",
            "lambda:UntagResource",
            "lambda:UpdateFunctionConfiguration"
        ],
        "Resource": "*"
      }
    ]
  })
}

# Attach the custom IAM policy to the Lambda execution role
resource "aws_iam_role_policy_attachment" "lambda_execution_role_custom_attachment" {
  policy_arn = aws_iam_policy.lambda_custom_policy.arn
  role       = aws_iam_role.lambda_execution_role[0].name
}

# Attach basic Lambda execution policy to the IAM role
resource "aws_iam_role_policy_attachment" "lambda_execution_role_attachment" {
  count = var.create_lambda_execution_role ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_execution_role[count.index].name
}

# Declare the create_lambda_execution_role variable
variable "create_lambda_execution_role" {
  description = "Flag to create the IAM role for Lambda execution"
  type        = bool
  default     = true
}
