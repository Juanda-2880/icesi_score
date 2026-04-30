import json
import os

import boto3
import psycopg2
from botocore.exceptions import ClientError

DB_HOST = os.environ["DB_HOST"]
DB_PORT = os.environ.get("DB_PORT", "5432")
DB_NAME = os.environ["DB_NAME"]
DB_USER = os.environ["DB_USER"]
DB_PASSWORD = os.environ["DB_PASSWORD"]
COGNITO_USER_POOL_ID = os.environ["COGNITO_USER_POOL_ID"]

CORS_HEADERS = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Content-Type,Authorization",
    "Content-Type": "application/json",
}

cognito_idp = boto3.client("cognito-idp")


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

        with conn.cursor() as cur:
            cur.execute("SELECT role FROM app_users WHERE id = %s", (caller_sub,))
            row = cur.fetchone()

        if row is None or row[0] != "SUPERADMIN":
            return _response(403, {"error": "No tienes permisos para esta acción."})

        try:
            body = json.loads(event.get("body") or "{}")
        except json.JSONDecodeError:
            return _response(400, {"error": "Todos los campos son requeridos."})

        full_name  = (body.get("fullName")    or "").strip()
        email      = (body.get("email")       or "").strip()
        phone      = (body.get("phone")       or "").strip()
        university = (body.get("university")  or "").strip()

        if not all([full_name, email, phone, university]):
            return _response(400, {"error": "Todos los campos son requeridos."})

        try:
            cognito_response = cognito_idp.admin_create_user(
                UserPoolId=COGNITO_USER_POOL_ID,
                Username=email,
                UserAttributes=[
                    {"Name": "email",             "Value": email},
                    {"Name": "name",              "Value": full_name},
                    {"Name": "phone_number",      "Value": phone},
                    {"Name": "custom:university", "Value": university},
                    {"Name": "email_verified",    "Value": "true"},
                ],
                DesiredDeliveryMediums=["EMAIL"],
                ForceAliasCreation=False,
            )
        except ClientError as exc:
            if exc.response["Error"]["Code"] == "UsernameExistsException":
                return _response(409, {"error": "Ya existe un usuario con ese correo."})
            print(f"[create_admin_user] Cognito error: {exc}")
            return _response(500, {"error": "Error al crear el usuario en Cognito."})

        new_sub = next(
            attr["Value"]
            for attr in cognito_response["User"]["Attributes"]
            if attr["Name"] == "sub"
        )

        with conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO app_users (id, full_name, email, phone, university, role)
                VALUES (%s, %s, %s, %s, %s, 'ADMIN')
                """,
                (new_sub, full_name, email, phone, university),
            )
        conn.commit()

        return _response(201, {"message": "Administrador creado exitosamente"})

    except psycopg2.OperationalError as exc:
        print(f"[create_admin_user] ERROR de conexión: {exc}")
        return _response(500, {"error": "Error de conexión a la base de datos"})
    except psycopg2.Error as exc:
        print(f"[create_admin_user] ERROR SQL [{exc.pgcode}]: {exc.pgerror or exc}")
        return _response(500, {"error": "Error en la base de datos"})
    finally:
        if conn:
            conn.close()
