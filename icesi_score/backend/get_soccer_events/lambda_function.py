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
            # Verify the match exists
            cur.execute("SELECT home_team_id, away_team_id FROM match WHERE id = %s", (match_id,))
            match_row = cur.fetchone()
            if match_row is None:
                return _response(404, {"error": "Partido no encontrado"})
            home_team_id = str(match_row[0])
            away_team_id = str(match_row[1])

            cur.execute(
                """
                SELECT se.id,
                       se.event_type,
                       se.event_minute,
                       se.main_player_id,
                       p_main.full_name  AS player_name,
                       p_main.team_id    AS team_id,
                       t.name            AS team_name,
                       se.id_parent_event,
                       p_sec.full_name   AS secondary_player_name
                FROM soccer_event se
                LEFT JOIN player p_main ON se.main_player_id   = p_main.id
                LEFT JOIN team   t      ON p_main.team_id       = t.id
                LEFT JOIN player p_sec  ON se.secondary_player_id = p_sec.id
                WHERE se.match_id = %s
                ORDER BY se.created_at ASC
                """,
                (match_id,),
            )
            rows = cur.fetchall()

        # Compute score_at_moment by walking events chronologically
        home_score = 0
        away_score = 0
        events = []
        for row in rows:
            event_type = row[1]
            team_id = str(row[5]) if row[5] else None

            if event_type == "GOAL" and team_id:
                if team_id == home_team_id:
                    home_score += 1
                elif team_id == away_team_id:
                    away_score += 1

            events.append({
                "id":                    str(row[0]),
                "eventType":             event_type,
                "minute":                row[2],
                "mainPlayerId":          str(row[3]) if row[3] else None,
                "playerName":            row[4],
                "teamId":                team_id,
                "teamName":              row[6],
                "scoreAtMoment":         f"{home_score}-{away_score}",
                "parentEventId":         str(row[7]) if row[7] else None,
                "secondaryPlayerName":   row[8],
            })

        # Return most recent first
        events.reverse()
        return _response(200, events)

    except psycopg2.OperationalError as exc:
        print(f"[get_soccer_events] ERROR de conexión: {exc}")
        return _response(500, {"error": "Error de conexión a la base de datos"})
    except psycopg2.Error as exc:
        print(f"[get_soccer_events] ERROR SQL [{exc.pgcode}]: {exc.pgerror or exc}")
        return _response(500, {"error": "Error en la base de datos"})
    finally:
        if conn:
            conn.close()
