# IcesiScore

Plataforma móvil para el seguimiento de partidos deportivos universitarios (Fútbol y Voleibol) en tiempo real.

## Frontend: Reglas de Desarrollo (Flutter)

1. **Uso obligatorio de `Key`:** Todos los widgets deben inicializarse con un `key` (ej. `super.key` en el constructor) para evitar ciclos de re-renderizado innecesarios en Flutter.

2. **StatefulWidgets components:**
   * Limitados **exclusivamente** a las Pantallas completas (Screens/Pages).
   * Se ubican en la carpeta `lib/screens/`.
   * Son responsables de manejar el estado de la aplicación, interactuar con los servicios y pasar la información a los componentes hijos.

3. ** StatelessWidgets components:**
   * Todo lo que no sea una pantalla completa debe ser un `StatelessWidget`.
   * Se ubican en la carpeta `lib/widgets/` y están divididos por contexto (`common`, `match`, `soccer`, `volleyball`).
   * Solo reciben datos mediante parámetros y dibujan la interfaz. No manejan lógica de negocio ni estado interno. Si requieren una acción (como un botón), reciben la función como parámetro (Callbacks).

## Backend e Infraestructura: Reglas de Desarrollo

Nube construida en **AWS** (Cognito, API Gateway, Lambda) y gestionada como código usando **Terraform**.

1. **Automatización de Credenciales:**
   * **NO** modificar manualmente el archivo `lib/amplifyconfiguration.dart`.
   * Este archivo es generado y sobrescrito automáticamente por Terraform cuando la infraestructura se despliega. Está ignorado en Git para evitar conflictos de credenciales entre los miembros del equipo.

2. **Desarrollo de Lambdas (Python):**
   * El código de las funciones Lambda vive en la carpeta `backend/`.
   * Si necesitas probar o agregar dependencias al script de Python (ej. `promote_admin.py`), utiliza un entorno virtual local (`.venv`). **No subas el `.venv` ni la carpeta `__pycache__` a Git**.
   * Terraform se encarga automáticamente de empaquetar el código Python en un `.zip` al momento de hacer el despliegue.

## Estructura de Carpetas Principal

* `assets/`: Fuentes, imágenes, logos e iconos.
* `backend/`: Scripts de Python para las funciones Lambda de AWS.
* `infrastructure/`: Archivos `.tf` de Terraform que definen y construyen nuestra nube en AWS.
* `lib/models/`: Clases puras de Dart (ej. Team, Player, Match, AppUser).
* `lib/screens/`: Pantallas principales de la app (Stateful), divididas por dominio (`auth/`, `home/`, `admin/`).
* `lib/widgets/`: Componentes UI reutilizables y atomizados (Stateless).
* `lib/services/`: Lógica de conexión a backend y AWS Amplify (`AuthService`, etc.).
* `lib/theme/`: Configuración global de Material App, colores y tipografías.

## Guía de Despliegue Local (Para el Equipo)

### Requisitos Previos

| Herramienta | Instalación |
|-------------|-------------|
| AWS CLI | [aws.amazon.com/cli](https://aws.amazon.com/cli/) |
| Terraform | [developer.hashicorp.com/terraform/install](https://developer.hashicorp.com/terraform/install) |
| Python 3.x | ya incluido en la mayoría de sistemas |
| psql | `sudo apt install postgresql-client` / `brew install libpq` |

Solicita las llaves de acceso AWS (`Access Key` + `Secret Key`) a un compañero con acceso.

---

### Flujo completo con Makefile

Todos los pasos se orquestan desde `icesi_score/` usando el `Makefile` incluido.  
Pasa siempre `DB_PASSWORD=<tu_password>` como argumento.

```bash
cd icesi_score
```

#### 1. Configurar credenciales AWS
```bash
aws configure
# Región: us-east-2 | Formato: json
```

#### 2. Inicializar Terraform (solo la primera vez)
```bash
cd infrastructure && terraform init && cd ..
```

#### 3. Levantar la infraestructura con acceso temporal a RDS
```bash
make db-up DB_PASSWORD=tu_password
```
Esto empaqueta las Lambdas automáticamente, detecta tu IP pública y hace `terraform apply`.  
La RDS quedará accesible **solo desde tu IP** mientras trabajas.  
Escribe `yes` para confirmar.


#### 4. Aplicar el schema de base de datos
```bash
make db-migrate DB_PASSWORD=tu_password
```
Crea el entorno virtual Python (`.venv/`) la primera vez, instala `psycopg2-binary`
y ejecuta `backend/db/schema.sql` sobre la RDS con SSL.

#### 5. Cargar datos de prueba (seed)
```bash
make db-seed DB_PASSWORD=tu_password
```

#### 6. (Opcional) Conectarse interactivamente a la base de datos
```bash
make db-connect DB_PASSWORD=tu_password
```

#### 7. Correr la app Flutter
```bash
flutter run
```

#### 8. Apagar la infraestructura al terminar
> **Importante:** siempre destruye la RDS al finalizar tu sesión para no generar costos.
```bash
make db-down DB_PASSWORD=tu_password
```

---

### Referencia rápida de targets

| Comando | Acción |
|---------|--------|
| `make venv` | Crea `.venv` e instala dependencias Python |
| `make db-up DB_PASSWORD=X` | `terraform apply` — levanta RDS con tu IP |
| `make db-migrate DB_PASSWORD=X` | Aplica `schema.sql` (Python + SSL) |
| `make db-seed DB_PASSWORD=X` | Carga `seed.sql` con `psql` |
| `make db-connect DB_PASSWORD=X` | Terminal `psql` interactiva con SSL |
| `make db-down DB_PASSWORD=X` | `terraform destroy` |

---

### Base de datos (PostgreSQL en Amazon RDS)

| Parámetro | Valor |
|-----------|-------|
| Motor | PostgreSQL 15 |
| Instancia | db.t3.micro (Free Tier) |
| Storage | 20 GB |
| Nombre DB | `icesi_score` |
| Usuario | `icesi_admin` |
| Región | `us-east-2` |

- Schema completo: `backend/db/schema.sql`
- Datos de prueba: `backend/db/seed.sql` (2 equipos, 1 liga, 6 jugadores)
- La tabla de usuarios se llama `app_users` (`user` es palabra reservada en PostgreSQL)
- Toda conexión requiere `sslmode=require`
- En producción la RDS **no es accesible públicamente**; solo las Lambdas dentro de la VPC se conectan
