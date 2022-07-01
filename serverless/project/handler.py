import json
import random


def hello(event, context):
    body = {
        "message": "Go Serverless v3.0! Your function executed successfully!",
        "input": event,
    }

    print(json.dumps({ 'type': "TEST", 'value': random.randint(0, 100) }))

    return {"statusCode": 200, "body": json.dumps(body)}
