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

UPDATE_SQL = """
UPDATE app_users
SET full_name=%s, phone=%s, university=%s
WHERE id=%s
RETURNING id, full_name, email, phone, university, role
"""


def _response(status: int, body: dict) -> dict:
    return {
        "statusCode": status,
        "headers": CORS_HEADERS,
        "body": json.dumps(body),
    }


def handler(event, _context):
    try:
        user_sub = event["requestContext"]["authorizer"]["jwt"]["claims"]["sub"]
    except KeyError:
        return _response(401, {"error": "Token inválido o expirado"})

    try:
        body = json.loads(event.get("body") or "{}")
    except (json.JSONDecodeError, TypeError):
        return _response(400, {"error": "Body inválido"})

    full_name = (body.get("fullName") or "").strip()
    phone = (body.get("phone") or "").strip() or None
    university = (body.get("university") or "").strip() or None

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
            cur.execute(UPDATE_SQL, (full_name, phone, university, user_sub))
            row = cur.fetchone()
        conn.commit()

        if row is None:
            return _response(404, {"error": "Usuario no encontrado"})

        uid, fn, email, ph, uni, role = row
        return _response(200, {
            "id": str(uid),
            "fullName": fn,
            "email": email,
            "phone": ph,
            "university": uni,
            "role": role,
        })

    except psycopg2.OperationalError as exc:
        print(f"[update_user_profile] ERROR de conexión: {exc}")
        return _response(500, {"error": "Error de conexión a la base de datos"})
    except psycopg2.Error as exc:
        print(f"[update_user_profile] ERROR SQL [{exc.pgcode}]: {exc.pgerror or exc}")
        return _response(500, {"error": "Error en la base de datos"})
    finally:
        if conn:
            conn.close()
