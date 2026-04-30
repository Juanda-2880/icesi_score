#!/usr/bin/env python3
import os
import sys
from pathlib import Path

try:
    import psycopg2
except ImportError:
    print("❌ psycopg2-binary no está instalado. Ejecuta: pip install psycopg2-binary")
    sys.exit(1)

SCHEMA_FILE = Path(__file__).parent / "schema.sql"

def get_config():
    required = ["DB_HOST", "DB_PORT", "DB_NAME", "DB_USER", "DB_PASSWORD"]
    missing = [v for v in required if not os.environ.get(v)]
    if missing:
        print(f"❌ Variables de entorno faltantes: {', '.join(missing)}")
        sys.exit(1)
    return {
        "host": os.environ["DB_HOST"],
        "port": int(os.environ["DB_PORT"]),
        "dbname": os.environ["DB_NAME"],
        "user": os.environ["DB_USER"],
        "password": os.environ["DB_PASSWORD"],
        "sslmode": "require",
        "connect_timeout": 10,
    }

def run_migrations():
    if not SCHEMA_FILE.exists():
        print(f"❌ No se encontró el archivo de schema: {SCHEMA_FILE}")
        sys.exit(1)

    sql = SCHEMA_FILE.read_text(encoding="utf-8")
    config = get_config()

    conn = None
    cur = None
    try:
        print(f"  Conectando a {config['host']}:{config['port']}/{config['dbname']} (SSL requerido)…")
        conn = psycopg2.connect(**config)
        conn.autocommit = True
        cur = conn.cursor()

        print("  Ejecutando schema.sql…")
        cur.execute(sql)

        print("✓ Migraciones aplicadas exitosamente.")
    except psycopg2.errors.DuplicateObject as exc:
        # ENUMs o tipos ya existen — idempotencia tolerada
        print(f"⚠  Algunos objetos ya existen (puede ser normal en re-ejecución): {exc.pgcode}")
        print("✓ Esquema ya estaba aplicado o se aplicó parcialmente.")
    except psycopg2.OperationalError as exc:
        print(f"❌ Error de conexión: {exc}")
        sys.exit(1)
    except psycopg2.Error as exc:
        print(f"❌ Error ejecutando schema.sql [{exc.pgcode}]: {exc.pgerror or exc}")
        sys.exit(1)
    finally:
        if cur:
            cur.close()
        if conn:
            conn.close()

if __name__ == "__main__":
    run_migrations()
