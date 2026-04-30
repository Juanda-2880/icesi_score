import os
import psycopg2

DB_HOST = os.environ["DB_HOST"]
DB_PORT = os.environ.get("DB_PORT", "5432")
DB_NAME = os.environ["DB_NAME"]
DB_USER = os.environ["DB_USER"]
DB_PASSWORD = os.environ["DB_PASSWORD"]

INSERT_SQL = """
INSERT INTO app_users (id, email, full_name, phone, university, role)
VALUES (%s, %s, %s, %s, %s, 'NORMAL')
ON CONFLICT (email) DO NOTHING;
"""


def handler(event, context):
    trigger_source = event.get("triggerSource", "")
    print(f"[post_confirmation] triggerSource={trigger_source}")

    # Solo actuar en confirmaciones reales, no en AdminConfirmUser
    if trigger_source not in ("PostConfirmation_ConfirmSignUp",):
        print("[post_confirmation] triggerSource ignorado, retornando event.")
        return event

    attrs = event.get("request", {}).get("userAttributes", {})
    sub        = attrs.get("sub")
    email      = attrs.get("email")
    full_name  = attrs.get("name", "")
    phone      = attrs.get("phone_number") or None
    university = attrs.get("custom:university") or None

    if not sub or not email:
        print(f"[post_confirmation] ERROR: atributos obligatorios ausentes. sub={sub} email={email}")
        return event

    print(f"[post_confirmation] Insertando usuario sub={sub} email={email}")

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
        with conn:
            with conn.cursor() as cur:
                cur.execute(INSERT_SQL, (sub, email, full_name, phone, university))
                print(f"[post_confirmation] INSERT ejecutado. rowcount={cur.rowcount}")
    except psycopg2.OperationalError as exc:
        print(f"[post_confirmation] ERROR de conexión a RDS: {exc}")
    except psycopg2.Error as exc:
        print(f"[post_confirmation] ERROR SQL [{exc.pgcode}]: {exc.pgerror or exc}")
    finally:
        if conn:
            conn.close()

    # Cognito requiere que se retorne el event original siempre
    return event
