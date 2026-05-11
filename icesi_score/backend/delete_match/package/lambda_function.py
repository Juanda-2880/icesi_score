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

    match_id = (event.get("pathParameters") or {}).get("id")
    if not match_id:
        return _response(400, {"error": "Falta el parámetro id en la ruta."})

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
            return _response(403, {"error": "No tienes permisos para eliminar partidos."})

        # --- Delete dependent rows in FK order, then the match itself ---
        # All in one transaction so a partial teardown never commits.
        with conn.cursor() as cur:
            # volleyball_event references volleyball_set
            cur.execute(
                "DELETE FROM volleyball_event WHERE set_id IN "
                "(SELECT id FROM volleyball_set WHERE match_id = %s)",
                (match_id,),
            )
            cur.execute("DELETE FROM volleyball_set WHERE match_id = %s", (match_id,))
            cur.execute("DELETE FROM soccer_event WHERE match_id = %s", (match_id,))
            cur.execute("DELETE FROM match_period WHERE id_match = %s", (match_id,))
            cur.execute("DELETE FROM match_lineup WHERE match_id = %s", (match_id,))

            # Delete only if SCHEDULED — returns 0 rows otherwise
            cur.execute(
                "DELETE FROM match WHERE id = %s AND status = 'SCHEDULED' RETURNING id",
                (match_id,),
            )
            deleted = cur.fetchone()

            if deleted is None:
                conn.rollback()
                return _response(409, {"error": "El partido no existe o no está en estado SCHEDULED."})

            conn.commit()

        return _response(200, {"id": match_id})

    except psycopg2.OperationalError as exc:
        print(f"[delete_match] ERROR de conexión: {exc}")
        return _response(500, {"error": "Error de conexión a la base de datos"})
    except psycopg2.Error as exc:
        print(f"[delete_match] ERROR SQL [{exc.pgcode}]: {exc.pgerror or exc}")
        return _response(500, {"error": "Error en la base de datos"})
    finally:
        if conn:
            conn.close()
