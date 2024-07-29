#lambda_function.py

import json
import boto3
from botocore.exceptions import ClientError

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('visit_count')

def lambda_handler(event, context):
    try:
        response = table.get_item(Key={'id': 'visit_count'})
        if 'Item' in response:
            count = response['Item']['count']
        else:
            count = 0

        count += 1

        table.put_item(Item={'id': 'visit_count', 'count': count})

        return {
            'statusCode': 200,
            'body': json.dumps({'visit_count': count})
        }
    except ClientError as e:
        print(e.response['Error']['Message'])
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Failed to update visit count'})
        }
