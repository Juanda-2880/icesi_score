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

    team_id = (body.get("teamId") or "").strip()
    if not team_id:
        return _response(400, {"error": "Falta teamId"})

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
        if match_row[0] != "IN_PROGRESS":
            return _response(409, {"error": "El partido no está en progreso"})

        with conn.cursor() as cur:
            cur.execute(
                "SELECT id FROM volleyball_set WHERE match_id = %s AND end_time IS NULL",
                (match_id,),
            )
            if not cur.fetchone():
                return _response(409, {"error": "No hay un set activo"})

        with conn.cursor() as cur:
            # Clockwise rotation: 1→6, 2→1, 3→2, 4→3, 5→4, 6→5
            cur.execute(
                """
                UPDATE match_lineup
                SET position_coordinate = CASE
                    WHEN position_coordinate = '1' THEN '6'
                    ELSE CAST(CAST(position_coordinate AS INTEGER) - 1 AS VARCHAR)
                END
                WHERE match_id = %s
                  AND status IN ('STARTER', 'ON_FIELD')
                  AND player_id IN (
                      SELECT id FROM player WHERE team_id = %s
                  )
                RETURNING player_id, position_coordinate
                """,
                (match_id, team_id),
            )
            updated_rows = cur.fetchall()

        if not updated_rows:
            return _response(404, {"error": "No se encontraron jugadores en campo para este equipo"})

        conn.commit()

        lineup = [
            {"playerId": str(r[0]), "positionCoordinate": r[1]}
            for r in updated_rows
        ]
        return _response(200, {"lineup": lineup})

    except psycopg2.OperationalError as exc:
        print(f"[post_rotate_team] ERROR conexión: {exc}")
        return _response(500, {"error": "Error de conexión a la base de datos"})
    except psycopg2.Error as exc:
        if conn:
            conn.rollback()
        print(f"[post_rotate_team] ERROR SQL [{exc.pgcode}]: {exc.pgerror or exc}")
        return _response(500, {"error": "Error en la base de datos"})
    finally:
        if conn:
            conn.close()
