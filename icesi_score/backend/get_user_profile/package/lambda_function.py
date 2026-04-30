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

SELECT_SQL = """
SELECT id, full_name, email, phone, university, role
FROM app_users
WHERE id = %s
LIMIT 1
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
            cur.execute(SELECT_SQL, (user_sub,))
            row = cur.fetchone()

        if row is None:
            return _response(404, {"error": "Usuario no encontrado"})

        user_id, full_name, email, phone, university, role = row
        return _response(200, {
            "id": str(user_id),
            "fullName": full_name,
            "email": email,
            "phone": phone,
            "university": university,
            "role": role,
        })

    except psycopg2.OperationalError as exc:
        print(f"[get_user_profile] ERROR de conexión: {exc}")
        return _response(500, {"error": "Error de conexión a la base de datos"})
    except psycopg2.Error as exc:
        print(f"[get_user_profile] ERROR SQL [{exc.pgcode}]: {exc.pgerror or exc}")
        return _response(500, {"error": "Error en la base de datos"})
    finally:
        if conn:
            conn.close()
