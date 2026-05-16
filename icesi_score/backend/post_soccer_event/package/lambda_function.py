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

VALID_TYPES = {"GOAL", "ASSIST", "YELLOW_CARD", "RED_CARD", "SUBSTITUTION", "NOTE"}


def _response(status: int, body) -> dict:
    return {"statusCode": status, "headers": CORS_HEADERS, "body": json.dumps(body)}


def lambda_handler(event, context):
    claims = event["requestContext"]["authorizer"]["jwt"]["claims"]
    cognito_sub = claims.get("sub", "")

    if not cognito_sub:
        return _response(401, {"error": "Token inválido"})

    match_id = (event.get("pathParameters") or {}).get("id", "").strip()
    if not match_id:
        return _response(400, {"error": "Falta el parámetro id"})

    try:
        body = json.loads(event.get("body") or "{}")
    except json.JSONDecodeError:
        return _response(400, {"error": "Body inválido"})

    event_type       = (body.get("eventType") or "").strip().upper()
    main_player_id   = (body.get("mainPlayerId") or "").strip()
    event_minute     = body.get("eventMinute")
    secondary_id     = (body.get("secondaryPlayerId") or "").strip() or None
    parent_event_id  = (body.get("parentEventId") or "").strip() or None
    assist_player_id = (body.get("assistPlayerId") or "").strip() or None
    note             = (body.get("note") or "").strip() or None

    if event_type not in VALID_TYPES:
        return _response(400, {"error": f"Tipo de evento inválido: {event_type}"})
    if not main_player_id:
        return _response(400, {"error": "Falta mainPlayerId"})
    if not isinstance(event_minute, int):
        return _response(400, {"error": "eventMinute debe ser un entero"})
    if event_type == "SUBSTITUTION" and not secondary_id:
        return _response(400, {"error": "SUBSTITUTION requiere secondaryPlayerId"})
    if event_type == "ASSIST" and not parent_event_id:
        return _response(400, {"error": "ASSIST requiere parentEventId"})

    conn = None
    try:
        conn = psycopg2.connect(
            host=DB_HOST,
            port=DB_PORT,
            dbname=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD,
            sslmode="require",
            connect_timeout=5,
        )
        with conn.cursor() as cur:
            cur.execute(
                "SELECT role FROM app_users WHERE id = %s",
                (cognito_sub,)
            )
            row = cur.fetchone()
        if not row:
            return _response(403, {"error": "Usuario no encontrado"})
        role = row[0]
        if role not in ("ADMIN", "SUPERADMIN"):
            return _response(403, {"error": f"Acceso denegado. Role: {role}"})

        with conn.cursor() as cur:
            cur.execute(
                "SELECT status, home_score, away_score, home_team_id, away_team_id FROM match WHERE id = %s",
                (match_id,),
            )
            match_row = cur.fetchone()
            if match_row is None:
                return _response(404, {"error": "Partido no encontrado"})
            if match_row[0] != "IN_PROGRESS":
                return _response(409, {"error": "El partido no está en progreso"})

            home_team_id = str(match_row[3])
            away_team_id = str(match_row[4])

            cur.execute("SELECT team_id FROM player WHERE id = %s", (main_player_id,))
            player_row = cur.fetchone()
            if player_row is None:
                return _response(404, {"error": "Jugador principal no encontrado"})
            player_team_id = str(player_row[0])
            if player_team_id not in (home_team_id, away_team_id):
                return _response(400, {"error": "El jugador no pertenece a este partido"})

            event_id = str(uuid.uuid4())
            cur.execute(
                """
                INSERT INTO soccer_event
                  (id, match_id, id_admin_registry, event_type, main_player_id,
                   secondary_player_id, event_minute, id_parent_event, note)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                """,
                (event_id, match_id, cognito_sub, event_type, main_player_id,
                 secondary_id, event_minute, parent_event_id, note),
            )

            if event_type == "GOAL":
                if player_team_id == home_team_id:
                    cur.execute("UPDATE match SET home_score = home_score + 1 WHERE id = %s", (match_id,))
                else:
                    cur.execute("UPDATE match SET away_score = away_score + 1 WHERE id = %s", (match_id,))

                if assist_player_id:
                    cur.execute(
                        """
                        INSERT INTO soccer_event
                          (id, match_id, id_admin_registry, event_type, main_player_id,
                           secondary_player_id, event_minute, id_parent_event, note)
                        VALUES (%s, %s, %s, 'ASSIST', %s, NULL, %s, %s, NULL)
                        """,
                        (str(uuid.uuid4()), match_id, cognito_sub,
                         assist_player_id, event_minute, event_id),
                    )

            elif event_type == "RED_CARD":
                cur.execute(
                    "UPDATE match_lineup SET status = 'EXPELLED' WHERE match_id = %s AND player_id = %s",
                    (match_id, main_player_id),
                )

            elif event_type == "SUBSTITUTION":
                cur.execute(
                    "UPDATE match_lineup SET status = 'ON_BENCH' WHERE match_id = %s AND player_id = %s",
                    (match_id, main_player_id),
                )
                cur.execute(
                    "UPDATE match_lineup SET status = 'ON_FIELD' WHERE match_id = %s AND player_id = %s",
                    (match_id, secondary_id),
                )

        conn.commit()

        with conn.cursor() as cur:
            cur.execute("SELECT full_name FROM player WHERE id = %s", (main_player_id,))
            name_row = cur.fetchone()
            player_name = name_row[0] if name_row else None

            player_in_name = None
            if event_type == "SUBSTITUTION" and secondary_id:
                cur.execute("SELECT full_name FROM player WHERE id = %s", (secondary_id,))
                pin_row = cur.fetchone()
                player_in_name = pin_row[0] if pin_row else None

            cur.execute("SELECT home_score, away_score FROM match WHERE id = %s", (match_id,))
            score_row = cur.fetchone()
            home_score = score_row[0]
            away_score = score_row[1]

        event_payload = {
            "id":                event_id,
            "eventType":         event_type,
            "minute":            event_minute,
            "mainPlayerId":      main_player_id,
            "playerName":        player_name,
            "teamId":            player_team_id,
            "scoreAtMoment":     f"{home_score}-{away_score}",
            "parentEventId":     parent_event_id,
            "secondaryPlayerName": player_in_name,
            "note":              note,
        }

        if SNS_BROADCAST_ARN:
            try:
                _sns_client.publish(
                    TopicArn=SNS_BROADCAST_ARN,
                    Message=json.dumps({
                        "match_id": match_id,
                        "message": {
                            "type": "SOCCER_EVENT",
                            "event": event_payload,
                            "newScore": {
                                "homeScore": home_score,
                                "awayScore": away_score,
                            },
                        },
                    }),
                )
            except Exception as e:
                print(f"WARNING SNS publish failed (non-fatal): {e}")

        return _response(201, {"event": event_payload, "newScore": {"homeScore": home_score, "awayScore": away_score}})

    except psycopg2.OperationalError as exc:
        print(f"[post_soccer_event] ERROR conexión: {exc}")
        return _response(500, {"error": "Error de conexión a la base de datos"})
    except psycopg2.Error as exc:
        if conn:
            conn.rollback()
        print(f"[post_soccer_event] ERROR SQL [{exc.pgcode}]: {exc.pgerror or exc}")
        return _response(500, {"error": "Error en la base de datos"})
    finally:
        if conn:
            conn.close()
