#main.tf
#Initial simple setup


# Provider Configuration
# Specifies that Terraform will use the AWS provider and sets the region.
provider "aws" {
  region = var.region
}


# Retrieve the list of AZs in the current AWS region
# NOTE: Data blocks are used to query APIs (like AWS) of other workspaces
data "aws_availability_zones" "available" {}
data "aws_region" "current" {}


#Define the VPC 
resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr_block

  tags = {
    Name        = var.vpc_name
    Environment = "lambda-terra"
    Terraform   = "true"
    Region      = data.aws_region.current.name   #to deploy vpc in CURRENT region
  }
}

# Subnet Configuration
# Creates a private subnet within the VPC.
resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = cidrsubnet(var.vpc_cidr_block, 8, 0) # /20 subnet
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false    #to make it a PRIVATE subnet
}



# Subnet Configuration
# Deploy the public subnets
resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = cidrsubnet(var.vpc_cidr_block, 8, 1) # /20 subnet
  availability_zone       =  data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true 
}


# Security Group Configuration
# Defines a security group for the Lambda function with specific ingress and egress rules.
resource "aws_security_group" "lambda_sg" {
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# IAM Role Configuration
# Creates an IAM role for the Lambda function with a trust policy allowing Lambda to assume the role.
resource "aws_iam_role" "lambda_role" {
  name = "lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}
















# IAM Role Policy Attachment
# Attaches a policy to the IAM role allowing it to write logs and interact with DynamoDB.
resource "aws_iam_role_policy" "lambda_policy" {
  name = "lambda_policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:UpdateItem",
          "dynamodb:GetItem"
        ],
        Effect = "Allow",
        Resource = aws_dynamodb_table.visit_count.arn
      },
      {
        Action = [
          "ec2:DescribeNetworkInterfaces",
          "ec2:CreateNetworkInterface",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeInstances",
          "ec2:AttachNetworkInterface"
        ],
        Effect = "Allow",
        Resource = "*"
      }
    ]
  })
}

# DynamoDB Table Configuration
# Creates a DynamoDB table to store visit counts.
resource "aws_dynamodb_table" "visit_count" {
  name           = "visit_count"
  hash_key       = "id"
  billing_mode   = "PAY_PER_REQUEST"

  attribute {
    name = "id"
    type = "S"
  }
}

# Lambda Function Configuration
# Creates a Lambda function, specifying the ZIP file, handler, runtime, role, and VPC configuration.
resource "aws_lambda_function" "visit_counter" {
  filename         = "lambda.zip"
  function_name    = "visit_counter"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  timeout          = 15
  vpc_config {
    subnet_ids         = [aws_subnet.private.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }
}

# API Gateway REST API Configuration
# Creates an API Gateway REST API to expose the Lambda function.
resource "aws_api_gateway_rest_api" "visit_api" {
  name        = "VisitAPI"
  description = "API to trigger Lambda on LinkedIn visit"
}

# API Gateway Resource Configuration
# Creates a resource under the API for the visit path.
resource "aws_api_gateway_resource" "visit_resource" {
  rest_api_id = aws_api_gateway_rest_api.visit_api.id
  parent_id   = aws_api_gateway_rest_api.visit_api.root_resource_id
  path_part   = "visit"
}

# API Gateway Method Configuration
# Defines a POST method for the visit resource without authorization.
resource "aws_api_gateway_method" "visit_method" {
  rest_api_id   = aws_api_gateway_rest_api.visit_api.id
  resource_id   = aws_api_gateway_resource.visit_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

# Lambda Permission Configuration
# Grants API Gateway permission to invoke the Lambda function.
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.visit_counter.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.visit_api.execution_arn}/*/*"
}

# API Gateway Integration Configuration
# Integrates the API Gateway method with the Lambda function using AWS_PROXY integration.
resource "aws_api_gateway_integration" "visit_integration" {
  rest_api_id = aws_api_gateway_rest_api.visit_api.id
  resource_id = aws_api_gateway_resource.visit_resource.id
  http_method = aws_api_gateway_method.visit_method.http_method
  integration_http_method = "POST"
  type        = "AWS_PROXY"
  uri         = aws_lambda_function.visit_counter.invoke_arn
}

# Output API Endpoint
# Outputs the API endpoint URL.
output "api_endpoint" {
  value = "${aws_api_gateway_rest_api.visit_api.execution_arn}/visit"
}
