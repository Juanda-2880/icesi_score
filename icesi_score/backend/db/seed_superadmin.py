#!/usr/bin/env python3
"""
Crea (o reutiliza) el SUPERADMIN en Cognito y lo inserta/actualiza en app_users.
Idempotente: puede ejecutarse múltiples veces sin duplicar datos.

Variables de entorno requeridas:
  DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD
  COGNITO_USER_POOL_ID
  SUPERADMIN_EMAIL
  SUPERADMIN_PASSWORD

Variables opcionales (con defaults):
  SUPERADMIN_FULL_NAME   (default: "Super Administrador")
  SUPERADMIN_PHONE       (default: "+57000000000")
  SUPERADMIN_UNIVERSITY  (default: "Icesi")
  AWS_DEFAULT_REGION     (default: "us-east-2")
"""
import os
import sys

try:
    import psycopg2
except ImportError:
    print("❌ psycopg2-binary no instalado. Ejecuta: make venv")
    sys.exit(1)

try:
    import boto3
    from botocore.exceptions import ClientError
except ImportError:
    print("❌ boto3 no instalado. Ejecuta: make venv")
    sys.exit(1)


def get_config():
    required = [
        "DB_HOST", "DB_PORT", "DB_NAME", "DB_USER", "DB_PASSWORD",
        "COGNITO_USER_POOL_ID", "SUPERADMIN_EMAIL", "SUPERADMIN_PASSWORD",
    ]
    missing = [v for v in required if not os.environ.get(v)]
    if missing:
        print(f"❌ Variables de entorno faltantes: {', '.join(missing)}")
        sys.exit(1)

    return {
        "db": {
            "host":            os.environ["DB_HOST"],
            "port":            int(os.environ["DB_PORT"]),
            "dbname":          os.environ["DB_NAME"],
            "user":            os.environ["DB_USER"],
            "password":        os.environ["DB_PASSWORD"],
            "sslmode":         "require",
            "connect_timeout": 10,
        },
        "pool_id":    os.environ["COGNITO_USER_POOL_ID"],
        "email":      os.environ["SUPERADMIN_EMAIL"],
        "password":   os.environ["SUPERADMIN_PASSWORD"],
        "full_name":  os.environ.get("SUPERADMIN_FULL_NAME",  "Super Administrador"),
        "phone":      os.environ.get("SUPERADMIN_PHONE",      "+57000000000"),
        "university": os.environ.get("SUPERADMIN_UNIVERSITY", "Icesi"),
        "region":     os.environ.get("AWS_DEFAULT_REGION",    "us-east-2"),
    }


def get_or_create_cognito_user(cfg):
    """Devuelve el sub del SUPERADMIN, creándolo si no existe."""
    idp = boto3.client("cognito-idp", region_name=cfg["region"])

    # Intentar obtener usuario existente
    try:
        resp = idp.admin_get_user(
            UserPoolId=cfg["pool_id"],
            Username=cfg["email"],
        )
        sub = next(
            a["Value"] for a in resp["UserAttributes"] if a["Name"] == "sub"
        )
        print(f"  → Usuario Cognito ya existe (sub={sub[:8]}…)")
    except idp.exceptions.UserNotFoundException:
        # Crear usuario sin enviar correo de invitación
        resp = idp.admin_create_user(
            UserPoolId=cfg["pool_id"],
            Username=cfg["email"],
            UserAttributes=[
                {"Name": "email",             "Value": cfg["email"]},
                {"Name": "email_verified",    "Value": "true"},
                {"Name": "name",              "Value": cfg["full_name"]},
                {"Name": "phone_number",      "Value": cfg["phone"]},
                {"Name": "custom:university", "Value": cfg["university"]},
            ],
            MessageAction="SUPPRESS",
        )
        sub = next(
            a["Value"]
            for a in resp["User"]["Attributes"]
            if a["Name"] == "sub"
        )
        print(f"  → Usuario Cognito creado (sub={sub[:8]}…)")

    # Siempre establecer contraseña permanente (evita FORCE_CHANGE_PASSWORD)
    idp.admin_set_user_password(
        UserPoolId=cfg["pool_id"],
        Username=cfg["email"],
        Password=cfg["password"],
        Permanent=True,
    )
    print("  → Contraseña establecida como permanente.")
    return sub


def upsert_superadmin_db(cfg, sub):
    """Inserta o actualiza el SUPERADMIN en app_users."""
    conn = None
    try:
        conn = psycopg2.connect(**cfg["db"])
        with conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO app_users (id, full_name, email, phone, university, role)
                VALUES (%s, %s, %s, %s, %s, 'SUPERADMIN')
                ON CONFLICT (id) DO UPDATE
                    SET role        = 'SUPERADMIN',
                        full_name   = EXCLUDED.full_name,
                        email       = EXCLUDED.email,
                        phone       = EXCLUDED.phone,
                        university  = EXCLUDED.university
                """,
                (sub, cfg["full_name"], cfg["email"], cfg["phone"], cfg["university"]),
            )
        conn.commit()
        print("  → Registro en app_users actualizado.")
    except psycopg2.Error as exc:
        print(f"❌ Error en la BD [{exc.pgcode}]: {exc.pgerror or exc}")
        sys.exit(1)
    finally:
        if conn:
            conn.close()


if __name__ == "__main__":
    print("▶  Configurando SUPERADMIN…")
    cfg = get_config()

    print("▶  Cognito…")
    sub = get_or_create_cognito_user(cfg)

    print("▶  Base de datos…")
    upsert_superadmin_db(cfg, sub)

    print(f"\n✓ SUPERADMIN listo → {cfg['email']}")
