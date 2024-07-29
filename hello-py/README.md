# Basic Lambda Function using Terraform


This terraform configuration (main.tf) containts an AWS Lambda function. The function code itself is found within python directory. 

Note that within the Terraform configuration, there is code that creates a zip file of the function's python code. 


## Things I learned
* The name of the lambda handler within the function's python code is user-defined and must be referenced correctly within the Terrafom configuration's lambda function block. 
