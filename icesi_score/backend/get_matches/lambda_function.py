import datetime
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

_VALID_SPORTS = {"FOOTBALL", "VOLLEYBALL"}


def _response(status: int, body) -> dict:
    return {
        "statusCode": status,
        "headers": CORS_HEADERS,
        "body": json.dumps(body),
    }


def _fmt_time(t) -> str | None:
    if t is None:
        return None
    if isinstance(t, datetime.timedelta):
        total = int(t.total_seconds())
        return f"{total // 3600:02d}:{(total % 3600) // 60:02d}"
    return str(t)[:5]


def handler(event, _context):
    try:
        event["requestContext"]["authorizer"]["jwt"]["claims"]["sub"]
    except KeyError:
        return _response(401, {"error": "Token inválido o expirado"})

    sport = ((event.get("queryStringParameters") or {}).get("sport") or "").upper()
    if sport not in _VALID_SPORTS:
        return _response(400, {"error": "El parámetro sport debe ser FOOTBALL o VOLLEYBALL"})

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
                """
                SELECT m.id, m.sport, m.status,
                       m.match_date, m.match_time, m.venue,
                       CASE WHEN m.status IN ('IN_PROGRESS','FINISHED')
                            THEN m.home_score ELSE NULL END AS home_score,
                       CASE WHEN m.status IN ('IN_PROGRESS','FINISHED')
                            THEN m.away_score ELSE NULL END AS away_score,
                       ht.id   AS home_team_id,   ht.name AS home_team_name,
                       at.id   AS away_team_id,   at.name AS away_team_name,
                       l.id    AS league_id,       l.name  AS league_name,
                       m.notes
                FROM match m
                JOIN team ht ON m.home_team_id = ht.id
                JOIN team at ON m.away_team_id = at.id
                JOIN league l ON m.league_id   = l.id
                WHERE m.sport = %s
                ORDER BY m.match_date, m.match_time
                """,
                (sport,),
            )
            rows = cur.fetchall()

        matches = [
            {
                "id":           str(row[0]),
                "sport":        row[1],
                "status":       row[2],
                "matchDate":    str(row[3]) if row[3] else None,
                "matchTime":    _fmt_time(row[4]),
                "venue":        row[5],
                "homeScore":    row[6],
                "awayScore":    row[7],
                "homeTeamId":   str(row[8]),
                "homeTeamName": row[9],
                "awayTeamId":   str(row[10]),
                "awayTeamName": row[11],
                "leagueId":     str(row[12]),
                "leagueName":   row[13],
                "notes":        row[14],
            }
            for row in rows
        ]
        return _response(200, matches)

    except psycopg2.OperationalError as exc:
        print(f"[get_matches] ERROR de conexión: {exc}")
        return _response(500, {"error": "Error de conexión a la base de datos"})
    except psycopg2.Error as exc:
        print(f"[get_matches] ERROR SQL [{exc.pgcode}]: {exc.pgerror or exc}")
        return _response(500, {"error": "Error en la base de datos"})
    finally:
        if conn:
            conn.close()
