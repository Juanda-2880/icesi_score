import json
import os
import time

import boto3

DDB_TABLE = os.environ.get("DDB_TABLE", "icesi-score-ws-connections")


def handler(event, _context):
    connection_id = event["requestContext"]["connectionId"]
    query_params = event.get("queryStringParameters") or {}
    match_id = query_params.get("match_id", "").strip()

    if not match_id:
        return {"statusCode": 400, "body": json.dumps({"error": "match_id requerido"})}

    dynamodb = boto3.resource("dynamodb")
    table = dynamodb.Table(DDB_TABLE)
    table.put_item(Item={
        "connectionId": connection_id,
        "match_id": match_id,
        "ttl": int(time.time()) + 86400,
    })
    return {"statusCode": 200, "body": "Connected"}
