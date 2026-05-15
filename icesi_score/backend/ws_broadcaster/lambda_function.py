import json
import os

import boto3
from boto3.dynamodb.conditions import Attr
from botocore.exceptions import ClientError

DYNAMODB_TABLE = os.environ.get("DYNAMODB_TABLE", "icesi-score-ws-connections")
WS_ENDPOINT = os.environ.get("WS_ENDPOINT", "")

_dynamodb = boto3.resource("dynamodb", region_name="us-east-2")
_table = _dynamodb.Table(DYNAMODB_TABLE)


def _broadcast(match_id: str, message: dict) -> None:
    if not match_id or not WS_ENDPOINT:
        print("WARNING: missing match_id or WS_ENDPOINT — skipping broadcast")
        return

    try:
        resp = _table.scan(FilterExpression=Attr("match_id").eq(match_id))
        items = resp.get("Items", [])
    except Exception as e:
        print(f"WARNING: DynamoDB scan failed: {e}")
        return

    api_gw = boto3.client(
        "apigatewaymanagementapi",
        endpoint_url=WS_ENDPOINT,
        region_name="us-east-2",
    )
    msg = json.dumps(message).encode("utf-8")

    for item in items:
        connection_id = item["connectionId"]
        try:
            api_gw.post_to_connection(ConnectionId=connection_id, Data=msg)
            print(f"Sent to {connection_id}")
        except ClientError as e:
            if e.response["Error"]["Code"] == "GoneException":
                try:
                    _table.delete_item(Key={"connectionId": connection_id})
                    print(f"Removed stale connection {connection_id}")
                except Exception as del_e:
                    print(f"WARNING: failed to delete stale connection {connection_id}: {del_e}")
            else:
                print(f"WARNING: failed to send to {connection_id}: {e}")
        except Exception as e:
            print(f"WARNING: unexpected error for {connection_id}: {e}")


def lambda_handler(event, context):
    for record in event.get("Records", []):
        try:
            payload = json.loads(record["Sns"]["Message"])
            match_id = payload["match_id"]
            message = payload["message"]
            _broadcast(match_id, message)
        except Exception as e:
            print(f"ERROR processing record: {e}")
