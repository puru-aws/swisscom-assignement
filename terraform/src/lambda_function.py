import json
import boto3
import os

STATE_MACHINE = os.environ['STATE_MACHINE']


def lambda_handler(event, context):
    # TODO implement
    data_response = serialize_event_data(event)
    print(data_response)
    input_dict = {"item": {"FileName": {"S": str(data_response)}}}
    startStepFunction(input_dict)


def serialize_event_data(json_data):
    s3_key = json_data["Records"][0]["s3"]["object"]["key"]
    return s3_key


def startStepFunction(input_dict):
    sf = boto3.client('stepfunctions', region_name='ap-south-1')
    response = sf.start_execution(
        stateMachineArn=STATE_MACHINE,
        input=json.dumps(input_dict))
