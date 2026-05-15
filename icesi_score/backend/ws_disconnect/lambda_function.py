import os

import boto3

DDB_TABLE = os.environ.get("DDB_TABLE", "icesi-score-ws-connections")


def handler(event, _context):
    connection_id = event["requestContext"]["connectionId"]
    dynamodb = boto3.resource("dynamodb")
    table = dynamodb.Table(DDB_TABLE)
    table.delete_item(Key={"connectionId": connection_id})
    return {"statusCode": 200, "body": "Disconnected"}
