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

VALID_TYPES = {"POINT", "SERVICE_ACE", "BLOCK", "ROTATION_FAULT", "SUBSTITUTION", "NOTE"}
SCORING_TYPES = {"POINT", "SERVICE_ACE", "BLOCK"}


def _response(status: int, body) -> dict:
    return {"statusCode": status, "headers": CORS_HEADERS, "body": json.dumps(body)}


def _check_set_win(set_number: int, home: int, away: int):
    """Returns ('home'|'away'|None) if a team has won the set."""
    target = 15 if set_number >= 5 else 25
    if home >= target and (home - away) >= 2:
        return "home"
    if away >= target and (away - home) >= 2:
        return "away"
    return None


def lambda_handler(event, context):
    claims = event["requestContext"]["authorizer"]["jwt"]["claims"]
    cognito_sub = claims.get("sub", "")
    if not cognito_sub:
        return _response(401, {"error": "Token inválido"})

    try:
        body = json.loads(event.get("body") or "{}")
    except json.JSONDecodeError:
        return _response(400, {"error": "Body inválido"})

    set_id          = (body.get("setId") or "").strip()
    event_type      = (body.get("eventType") or "").strip().upper()
    main_player_id  = (body.get("mainPlayerId") or "").strip() or None
    team_id         = (body.get("teamId") or "").strip()
    note            = (body.get("note") or "").strip() or None
    secondary_id    = (body.get("secondaryPlayerId") or "").strip() or None

    if not set_id:
        return _response(400, {"error": "Falta setId"})
    if event_type not in VALID_TYPES:
        return _response(400, {"error": f"Tipo de evento inválido: {event_type}"})
    if not team_id:
        return _response(400, {"error": "Falta teamId"})
    if event_type != "NOTE" and not main_player_id:
        return _response(400, {"error": "Falta mainPlayerId"})
    if event_type == "SUBSTITUTION" and not secondary_id:
        return _response(400, {"error": "SUBSTITUTION requiere secondaryPlayerId"})

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
            cur.execute(
                """
                SELECT vs.match_id, vs.set_number,
                       vs.current_home_score, vs.current_away_score,
                       m.home_team_id, m.away_team_id, m.home_score, m.away_score,
                       m.status
                FROM volleyball_set vs
                JOIN match m ON m.id = vs.match_id
                WHERE vs.id = %s AND vs.end_time IS NULL
                """,
                (set_id,),
            )
            set_row = cur.fetchone()

        if set_row is None:
            return _response(409, {"error": "Set no encontrado o ya finalizado"})

        match_id         = str(set_row[0])
        set_number       = set_row[1]
        home_set_score   = set_row[2]
        away_set_score   = set_row[3]
        home_team_id     = str(set_row[4])
        away_team_id     = str(set_row[5])
        home_sets        = set_row[6]
        away_sets        = set_row[7]
        match_status     = set_row[8]

        if match_status != "IN_PROGRESS":
            return _response(409, {"error": "El partido no está en progreso"})

        is_home_team = (team_id == home_team_id)
        is_away_team = (team_id == away_team_id)
        if not is_home_team and not is_away_team:
            return _response(400, {"error": "El equipo no pertenece a este partido"})

        set_complete = False
        match_finished = False
        new_home_set_score = home_set_score
        new_away_set_score = away_set_score
        new_home_sets = home_sets
        new_away_sets = away_sets

        with conn.cursor() as cur:
            # --- Score-changing events ---
            if event_type in SCORING_TYPES:
                # The scoring team gets the point
                if is_home_team:
                    new_home_set_score = home_set_score + 1
                    cur.execute(
                        "UPDATE volleyball_set SET current_home_score = current_home_score + 1 WHERE id = %s",
                        (set_id,),
                    )
                else:
                    new_away_set_score = away_set_score + 1
                    cur.execute(
                        "UPDATE volleyball_set SET current_away_score = current_away_score + 1 WHERE id = %s",
                        (set_id,),
                    )

                winner = _check_set_win(set_number, new_home_set_score, new_away_set_score)
                if winner:
                    set_complete = True
                    cur.execute(
                        "UPDATE volleyball_set SET end_time = NOW() WHERE id = %s",
                        (set_id,),
                    )
                    if winner == "home":
                        new_home_sets = home_sets + 1
                        cur.execute(
                            "UPDATE match SET home_score = home_score + 1 WHERE id = %s",
                            (match_id,),
                        )
                    else:
                        new_away_sets = away_sets + 1
                        cur.execute(
                            "UPDATE match SET away_score = away_score + 1 WHERE id = %s",
                            (match_id,),
                        )

                    if new_home_sets >= 3 or new_away_sets >= 3:
                        match_finished = True
                        cur.execute(
                            "UPDATE match SET status = 'FINISHED' WHERE id = %s",
                            (match_id,),
                        )

            elif event_type == "ROTATION_FAULT":
                # Opponent team gets the point
                if is_home_team:
                    new_away_set_score = away_set_score + 1
                    cur.execute(
                        "UPDATE volleyball_set SET current_away_score = current_away_score + 1 WHERE id = %s",
                        (set_id,),
                    )
                else:
                    new_home_set_score = home_set_score + 1
                    cur.execute(
                        "UPDATE volleyball_set SET current_home_score = current_home_score + 1 WHERE id = %s",
                        (set_id,),
                    )

                winner = _check_set_win(set_number, new_home_set_score, new_away_set_score)
                if winner:
                    set_complete = True
                    cur.execute(
                        "UPDATE volleyball_set SET end_time = NOW() WHERE id = %s",
                        (set_id,),
                    )
                    if winner == "home":
                        new_home_sets = home_sets + 1
                        cur.execute(
                            "UPDATE match SET home_score = home_score + 1 WHERE id = %s",
                            (match_id,),
                        )
                    else:
                        new_away_sets = away_sets + 1
                        cur.execute(
                            "UPDATE match SET away_score = away_score + 1 WHERE id = %s",
                            (match_id,),
                        )

                    if new_home_sets >= 3 or new_away_sets >= 3:
                        match_finished = True
                        cur.execute(
                            "UPDATE match SET status = 'FINISHED' WHERE id = %s",
                            (match_id,),
                        )

            elif event_type == "SUBSTITUTION":
                # Player out → ON_BENCH, player in → ON_FIELD inheriting position
                cur.execute(
                    """
                    SELECT position_coordinate FROM match_lineup
                    WHERE match_id = %s AND player_id = %s
                    """,
                    (match_id, main_player_id),
                )
                pos_row = cur.fetchone()
                out_position = pos_row[0] if pos_row else None

                cur.execute(
                    "UPDATE match_lineup SET status = 'ON_BENCH' WHERE match_id = %s AND player_id = %s",
                    (match_id, main_player_id),
                )
                cur.execute(
                    """
                    UPDATE match_lineup
                    SET status = 'ON_FIELD', position_coordinate = %s
                    WHERE match_id = %s AND player_id = %s
                    """,
                    (out_position, match_id, secondary_id),
                )

            score_moment = f"{new_home_set_score}-{new_away_set_score}"

            event_id = str(uuid.uuid4())
            cur.execute(
                """
                INSERT INTO volleyball_event
                  (id, set_id, id_admin_registry, event_type, main_player_id,
                   secondary_player_id, id_team, score_moment, note)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                """,
                (event_id, set_id, cognito_sub, event_type, main_player_id,
                 secondary_id, team_id, score_moment, note),
            )

        conn.commit()

        # Fetch main and secondary player names for the response
        player_name = None
        secondary_player_name = None
        with conn.cursor() as cur:
            if main_player_id:
                cur.execute("SELECT full_name FROM player WHERE id = %s", (main_player_id,))
                name_row = cur.fetchone()
                player_name = name_row[0] if name_row else None
            if secondary_id:
                cur.execute("SELECT full_name FROM player WHERE id = %s", (secondary_id,))
                sec_row = cur.fetchone()
                secondary_player_name = sec_row[0] if sec_row else None

        event_payload = {
            "id": event_id,
            "setId": set_id,
            "setNumber": set_number,
            "eventType": event_type,
            "mainPlayerId": main_player_id,
            "secondaryPlayerId": secondary_id,
            "playerName": player_name,
            "secondaryPlayerName": secondary_player_name,
            "teamId": team_id,
            "scoreMoment": score_moment,
            "note": note,
        }

        if SNS_BROADCAST_ARN:
            try:
                _sns_client.publish(
                    TopicArn=SNS_BROADCAST_ARN,
                    Message=json.dumps({
                        "match_id": match_id,
                        "message": {
                            "type": "VOLLEYBALL_EVENT",
                            "event": event_payload,
                            "setScore": {
                                "homeScore": new_home_set_score,
                                "awayScore": new_away_set_score,
                            },
                            "matchScore": {
                                "homeSets": new_home_sets,
                                "awaySets": new_away_sets,
                            },
                            "setComplete": set_complete,
                            "matchFinished": match_finished,
                        },
                    }),
                )
            except Exception as e:
                print(f"WARNING SNS publish failed (non-fatal): {e}")

        return _response(201, {
            "event": event_payload,
            "setScore": {"homeScore": new_home_set_score, "awayScore": new_away_set_score},
            "matchScore": {"homeSets": new_home_sets, "awaySets": new_away_sets},
            "setComplete": set_complete,
            "matchFinished": match_finished,
        })

    except psycopg2.OperationalError as exc:
        print(f"[post_volleyball_event] ERROR conexión: {exc}")
        return _response(500, {"error": "Error de conexión a la base de datos"})
    except psycopg2.Error as exc:
        if conn:
            conn.rollback()
        print(f"[post_volleyball_event] ERROR SQL [{exc.pgcode}]: {exc.pgerror or exc}")
        return _response(500, {"error": "Error en la base de datos"})
    finally:
        if conn:
            conn.close()
