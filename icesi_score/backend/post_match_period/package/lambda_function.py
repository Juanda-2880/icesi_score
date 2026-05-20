import json
import os
import uuid

import boto3
import psycopg2
from botocore.config import Config

DB_HOST = os.environ["DB_HOST"]
DB_PORT = os.environ.get("DB_PORT", "5432")
DB_NAME = os.environ["DB_NAME"]
DB_USER = os.environ["DB_USER"]
DB_PASSWORD = os.environ["DB_PASSWORD"]
SNS_BROADCAST_ARN = os.environ.get("SNS_BROADCAST_ARN", "")

_BOTO_CFG = Config(connect_timeout=3, read_timeout=3, retries={"max_attempts": 0})
_sns_client = boto3.client("sns", region_name="us-east-2", config=_BOTO_CFG)

CORS_HEADERS = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Content-Type,Authorization",
    "Content-Type": "application/json",
}


def _response(status: int, body) -> dict:
    return {"statusCode": status, "headers": CORS_HEADERS, "body": json.dumps(body)}


def lambda_handler(event, context):
    claims = event["requestContext"]["authorizer"]["jwt"]["claims"]
    cognito_sub = claims.get("sub", "")
    if not cognito_sub:
        return _response(401, {"error": "Token inválido"})

    try:
        body = json.loads(event.get("body") or "{}")
    except json.JSONDecodeError:
        return _response(400, {"error": "Body inválido"})

    match_id = (body.get("matchId") or "").strip()
    period_label = (body.get("periodLabel") or "").strip().upper()

    if not match_id:
        return _response(400, {"error": "Falta matchId"})
    if period_label not in ("1T", "2T"):
        return _response(400, {"error": "periodLabel debe ser '1T' o '2T'"})

    conn = None
    try:
        conn = psycopg2.connect(
            host=DB_HOST, port=DB_PORT, dbname=DB_NAME,
            user=DB_USER, password=DB_PASSWORD,
            sslmode="require", connect_timeout=5,
        )
        with conn.cursor() as cur:
            cur.execute("SELECT role FROM app_users WHERE id = %s", (cognito_sub,))
            row = cur.fetchone()
        if not row or row[0] not in ("ADMIN", "SUPERADMIN"):
            return _response(403, {"error": "Acceso denegado"})

        with conn.cursor() as cur:
            cur.execute("SELECT status FROM match WHERE id = %s", (match_id,))
            match_row = cur.fetchone()
        if match_row is None:
            return _response(404, {"error": "Partido no encontrado"})
        if match_row[0] == "FINISHED":
            return _response(409, {"error": "El partido ya está finalizado"})

        with conn.cursor() as cur:
            # Reject if another period is currently open
            cur.execute(
                "SELECT id FROM match_period WHERE id_match = %s AND end_time IS NULL",
                (match_id,),
            )
            if cur.fetchone():
                return _response(409, {"error": "Ya hay un período activo para este partido"})

            period_id = str(uuid.uuid4())
            cur.execute(
                """
                INSERT INTO match_period (id, id_match, period_label, start_time)
                VALUES (%s, %s, %s, NOW())
                RETURNING start_time
                """,
                (period_id, match_id, period_label),
            )
            start_time = cur.fetchone()[0]

            if match_row[0] == "SCHEDULED":
                cur.execute(
                    "UPDATE match SET status = 'IN_PROGRESS' WHERE id = %s",
                    (match_id,),
                )

        conn.commit()

        if SNS_BROADCAST_ARN:
            try:
                _sns_client.publish(
                    TopicArn=SNS_BROADCAST_ARN,
                    Message=json.dumps({
                        "match_id": match_id,
                        "message": {
                            "type": "CLOCK_UPDATE",
                            "action": "START",
                            "periodLabel": period_label,
                            "startTime": start_time.isoformat(),
                            "periodId": period_id,
                        },
                    }),
                )
            except Exception as e:
                print(f"WARNING SNS publish failed (non-fatal): {e}")

        return _response(201, {
            "id": period_id,
            "periodLabel": period_label,
            "startTime": start_time.isoformat(),
        })

    except psycopg2.OperationalError as exc:
        print(f"[post_match_period] ERROR conexión: {exc}")
        return _response(500, {"error": "Error de conexión a la base de datos"})
    except psycopg2.Error as exc:
        if conn:
            conn.rollback()
        print(f"[post_match_period] ERROR SQL [{exc.pgcode}]: {exc.pgerror or exc}")
        return _response(500, {"error": "Error en la base de datos"})
    finally:
        if conn:
            conn.close()
