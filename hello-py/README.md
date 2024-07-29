# Basic Lambda Function using Terraform


This terraform configuration (main.tf) contains:
* AWS IAM role
* policy for that role
* attachment for the policy to the role
* data block that will create a zip file of the Lambda code

The function's Python code contains Lambda handler, which will process events when invoked.

 

## Things I learned
* The name of the lambda handler within the function's python code is user-defined and must be referenced correctly within the Terrafom configuration's lambda function block. 
* Configure test event from within the console and modifiying the function code. 

