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
    return {"statusCode": status, "headers": CORS_HEADERS, "body": json.dumps(body)}


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
            cur.execute("SELECT 1 FROM match WHERE id = %s", (match_id,))
            if cur.fetchone() is None:
                return _response(404, {"error": "Partido no encontrado"})

            cur.execute(
                """
                SELECT ml.id,
                       ml.player_id,
                       p.full_name,
                       p.jersey_number,
                       p.team_id,
                       t.name            AS team_name,
                       ml.status,
                       ml.position_coordinate
                FROM match_lineup ml
                JOIN player p ON ml.player_id = p.id
                JOIN team   t ON p.team_id    = t.id
                WHERE ml.match_id = %s
                  AND ml.status != 'SUBSTITUTE'
                ORDER BY p.jersey_number ASC
                """,
                (match_id,),
            )
            rows = cur.fetchall()

        players = [
            {
                "id":                 str(row[0]),
                "playerId":           str(row[1]),
                "playerName":         row[2],
                "jerseyNumber":       row[3],
                "teamId":             str(row[4]),
                "teamName":           row[5],
                "status":             row[6],
                "positionCoordinate": row[7],
            }
            for row in rows
        ]
        return _response(200, players)

    except psycopg2.OperationalError as exc:
        print(f"[get_match_lineup] ERROR conexión: {exc}")
        return _response(500, {"error": "Error de conexión a la base de datos"})
    except psycopg2.Error as exc:
        print(f"[get_match_lineup] ERROR SQL [{exc.pgcode}]: {exc.pgerror or exc}")
        return _response(500, {"error": "Error en la base de datos"})
    finally:
        if conn:
            conn.close()
