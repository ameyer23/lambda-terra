# Code defining function
# note that lambda_handler is the function name within this code, which is user defined and can be different than this
def lambda_handler(event, context):
   message = 'Hello {} !'.format(event['key1'])
   return {
       'message' : message
   }
