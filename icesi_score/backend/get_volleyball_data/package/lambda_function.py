import json
import os

import psycopg2

DB_HOST = os.environ["DB_HOST"]
DB_PORT = os.environ.get("DB_PORT", "5432")
DB_NAME = os.environ["DB_NAME"]
DB_USER = os.environ["DB_USER"]
DB_PASSWORD = os.environ["DB_PASSWORD"]

CORS_HEADERS = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Content-Type,Authorization",
    "Content-Type": "application/json",
}


def _response(status: int, body) -> dict:
    return {
        "statusCode": status,
        "headers": CORS_HEADERS,
        "body": json.dumps(body),
    }


def handler(event, _context):
    try:
        event["requestContext"]["authorizer"]["jwt"]["claims"]["sub"]
    except KeyError:
        return _response(401, {"error": "Token inválido o expirado"})

    match_id = (event.get("pathParameters") or {}).get("id", "").strip()
    if not match_id:
        return _response(400, {"error": "Falta el parámetro id"})

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
            cur.execute("SELECT id FROM match WHERE id = %s", (match_id,))
            if cur.fetchone() is None:
                return _response(404, {"error": "Partido no encontrado"})

            cur.execute(
                """
                SELECT id, set_number, current_home_score, current_away_score,
                       start_time, end_time
                FROM volleyball_set
                WHERE match_id = %s
                ORDER BY set_number ASC
                """,
                (match_id,),
            )
            set_rows = cur.fetchall()

            sets = []
            set_number_map = {}
            for row in set_rows:
                set_id = str(row[0])
                set_number = row[1]
                set_number_map[set_id] = set_number
                sets.append({
                    "id": set_id,
                    "setNumber": set_number,
                    "homeScore": row[2],
                    "awayScore": row[3],
                    "isActive": row[5] is None,
                    "startTime": row[4].isoformat() if row[4] else None,
                    "endTime": row[5].isoformat() if row[5] else None,
                })

            cur.execute(
                """
                SELECT ve.id,
                       ve.set_id,
                       ve.event_type,
                       p.full_name   AS player_name,
                       p2.full_name  AS secondary_player_name,
                       ve.id_team,
                       t.name        AS team_name,
                       ve.score_moment,
                       ve.note
                FROM volleyball_event ve
                LEFT JOIN player p  ON ve.main_player_id      = p.id
                LEFT JOIN player p2 ON ve.secondary_player_id = p2.id
                LEFT JOIN team   t  ON ve.id_team = t.id
                WHERE ve.set_id IN (
                    SELECT id FROM volleyball_set WHERE match_id = %s
                )
                ORDER BY ve.event_timestamp DESC
                """,
                (match_id,),
            )
            event_rows = cur.fetchall()

            events = []
            for row in event_rows:
                set_id = str(row[1])
                events.append({
                    "id": str(row[0]),
                    "setId": set_id,
                    "setNumber": set_number_map.get(set_id, 0),
                    "eventType": row[2],
                    "playerName": row[3],
                    "secondaryPlayerName": row[4],
                    "teamId": str(row[5]) if row[5] else None,
                    "teamName": row[6],
                    "scoreMoment": row[7],
                    "note": row[8],
                })

        return _response(200, {"sets": sets, "events": events})

    except psycopg2.OperationalError as exc:
        print(f"[get_volleyball_data] ERROR de conexión: {exc}")
        return _response(500, {"error": "Error de conexión a la base de datos"})
    except psycopg2.Error as exc:
        print(f"[get_volleyball_data] ERROR SQL [{exc.pgcode}]: {exc.pgerror or exc}")
        return _response(500, {"error": "Error en la base de datos"})
    finally:
        if conn:
            conn.close()
