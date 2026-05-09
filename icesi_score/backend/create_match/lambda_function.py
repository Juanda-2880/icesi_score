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

REQUIRED_FIELDS = ("sport", "homeTeamId", "awayTeamId", "leagueId", "matchDate", "matchTime", "venue")


def _response(status: int, body: dict) -> dict:
    return {
        "statusCode": status,
        "headers": CORS_HEADERS,
        "body": json.dumps(body),
    }


def handler(event, _context):
    try:
        caller_sub = event["requestContext"]["authorizer"]["jwt"]["claims"]["sub"]
    except KeyError:
        return _response(401, {"error": "Token inválido o expirado"})

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

        # --- Authorization: ADMIN or SUPERADMIN only ---
        with conn.cursor() as cur:
            cur.execute("SELECT role FROM app_users WHERE id = %s", (caller_sub,))
            row = cur.fetchone()

        if row is None or row[0] not in ("ADMIN", "SUPERADMIN"):
            return _response(403, {"error": "No tienes permisos para crear partidos."})

        # --- Parse body ---
        try:
            body = json.loads(event.get("body") or "{}")
        except json.JSONDecodeError:
            return _response(400, {"error": "Cuerpo de solicitud inválido."})

        missing = [f for f in REQUIRED_FIELDS if not body.get(f)]
        if missing:
            return _response(400, {"error": f"Campos requeridos faltantes: {', '.join(missing)}"})

        sport = body["sport"]
        home_team_id = body["homeTeamId"]
        away_team_id = body["awayTeamId"]
        league_id = body["leagueId"]
        match_date = body["matchDate"]
        match_time = body["matchTime"]
        venue = body["venue"]
        notes = body.get("notes") or None

        if home_team_id == away_team_id:
            return _response(400, {"error": "Los equipos local y visitante no pueden ser el mismo."})

        if sport not in ("FOOTBALL", "VOLLEYBALL"):
            return _response(400, {"error": "Deporte inválido. Usa FOOTBALL o VOLLEYBALL."})

        # --- Insert match ---
        with conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO match
                    (league_id, sport, home_team_id, away_team_id,
                     id_admin_creator, match_date, match_time, venue, notes)
                VALUES (%s, %s::sport_type, %s, %s, %s, %s, %s, %s, %s)
                RETURNING id
                """,
                (
                    league_id, sport, home_team_id, away_team_id,
                    caller_sub, match_date, match_time, venue, notes,
                ),
            )
            match_id = str(cur.fetchone()[0])
            conn.commit()

        return _response(201, {"id": match_id})

    except psycopg2.errors.ForeignKeyViolation:
        return _response(400, {"error": "Liga o equipo no encontrado. Verifica los datos."})
    except psycopg2.errors.InvalidTextRepresentation:
        return _response(400, {"error": "Valor de deporte o estado inválido."})
    except psycopg2.OperationalError as exc:
        print(f"[create_match] ERROR de conexión: {exc}")
        return _response(500, {"error": "Error de conexión a la base de datos"})
    except psycopg2.Error as exc:
        print(f"[create_match] ERROR SQL [{exc.pgcode}]: {exc.pgerror or exc}")
        return _response(500, {"error": "Error en la base de datos"})
    finally:
        if conn:
            conn.close()
