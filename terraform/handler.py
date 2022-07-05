import os

import boto3

def handler(event, context):
    ec2 = boto3.resource('ec2')
    instances = ec2.instances.filter(
        Filters=[
          {
            'Name': 'tag:Name',
            'Values': [os.environ['INSTANCE_NAME']]
          }
        ]
    )
    instance_count = len(list(instances))
    print(instance_count)
