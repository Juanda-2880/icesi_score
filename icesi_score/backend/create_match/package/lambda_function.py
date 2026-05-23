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

# Slot order determines visual position on the field (widget uses list index, not coordinate string).
FOOTBALL_SLOTS = [
    ("PO",      "50,88"),
    ("DF_DER",  "80,77"),
    ("DF_CEN",  "60,77"),
    ("DF_CEN",  "40,77"),
    ("DF_IZQ",  "20,77"),
    ("MED_DER", "80,66"),
    ("MED_CEN", "60,66"),
    ("MED_CEN", "40,66"),
    ("MED_IZQ", "20,66"),
    ("DEL",     "60,55"),
    ("DEL",     "40,55"),
]

# Coordinate '1'–'6' are dict keys used by VolleyballCourtWidget — must be exact.
VOLLEYBALL_SLOTS = [
    ("SETTER",  "1"),
    ("OUTSIDE", "2"),
    ("OUTSIDE", "3"),
    ("SETTER",  "4"),
    ("MIDDLE",  "5"),
    ("MIDDLE",  "6"),
]


def _build_lineup(players, slots):
    """Greedy slot assignment: match standard_position to slot, fallback to next available."""
    unassigned = list(players)
    result = []
    for (pos, coord) in slots:
        idx = next((i for i, (pid, sp) in enumerate(unassigned) if sp == pos), None)
        if idx is None:
            if not unassigned:
                break
            idx = 0
        pid, _ = unassigned.pop(idx)
        result.append((pid, "STARTER", coord))
    for (pid, _) in unassigned:
        result.append((pid, "ON_BENCH", None))
    return result


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

        slots = FOOTBALL_SLOTS if sport == "FOOTBALL" else VOLLEYBALL_SLOTS

        # --- Insert match + lineup atomically (single commit at the end) ---
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

            for team_id in (home_team_id, away_team_id):
                cur.execute(
                    """
                    SELECT id, standard_position FROM player
                    WHERE team_id = %s
                    ORDER BY standard_position, jersey_number
                    """,
                    (team_id,),
                )
                players = cur.fetchall()
                lineup_rows = _build_lineup(players, slots)
                for (player_id, status, coord) in lineup_rows:
                    cur.execute(
                        """
                        INSERT INTO match_lineup
                            (id, match_id, player_id, status, position_coordinate)
                        VALUES (gen_random_uuid(), %s, %s, %s::lineup_status, %s)
                        """,
                        (match_id, player_id, status, coord),
                    )

            conn.commit()

        return _response(201, {"id": match_id})

    except psycopg2.errors.ForeignKeyViolation:
        if conn:
            conn.rollback()
        return _response(400, {"error": "Liga o equipo no encontrado. Verifica los datos."})
    except psycopg2.errors.InvalidTextRepresentation:
        if conn:
            conn.rollback()
        return _response(400, {"error": "Valor de deporte o estado inválido."})
    except psycopg2.OperationalError as exc:
        if conn:
            conn.rollback()
        print(f"[create_match] ERROR de conexión: {exc}")
        return _response(500, {"error": "Error de conexión a la base de datos"})
    except psycopg2.Error as exc:
        if conn:
            conn.rollback()
        print(f"[create_match] ERROR SQL [{exc.pgcode}]: {exc.pgerror or exc}")
        return _response(500, {"error": "Error en la base de datos"})
    finally:
        if conn:
            conn.close()
