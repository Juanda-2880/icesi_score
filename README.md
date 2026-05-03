# IcesiScore

Plataforma móvil para el seguimiento de partidos deportivos universitarios (Fútbol y Voleibol) en tiempo real.

---

## Sprint 1 — Autenticación de Usuarios

### Contexto

IcesiScore maneja tres tipos de usuario, cada uno con un flujo de autenticación propio:

| Tipo | Descripción | Cómo se crea |
|------|-------------|--------------|
| **Usuario Regular** | Aficionado que consulta partidos y estadísticas en tiempo real | Auto-registro desde la app |
| **Admin** | Gestiona equipos, ligas y partidos en el dashboard administrativo | Lo crea el Superadmin desde la app |
| **Superadmin** | Control total de la plataforma; puede promover otros admins | Se crea con el script de seed (`make db-migrate`) |

---

### Flujo 1 — Registro (Usuario Regular)

El registro aplica exclusivamente a usuarios regulares. Admins y Superadmin se crean desde dentro de la plataforma.

1. Abre la app → pantalla **Bienvenida**.
2. Toca **Crear cuenta**.
3. Completa el formulario de onboarding:
   - Nombre completo
   - Correo electrónico (`@uicesi.edu.co` o cualquier dominio válido)
   - Teléfono
   - Universidad
   - Contraseña (y confirmación)
4. Toca **Registrarse** → se envía un código de verificación al correo ingresado.
5. En la pantalla **Verificar cuenta**, ingresa el código de 6 dígitos.
6. Al confirmar, la app navega automáticamente a la pantalla principal (**Home**).

---

### Flujo 2 — Inicio de Sesión

El mismo flujo de login aplica para los tres tipos de usuario; la app enruta a la pantalla correcta según el rol.

1. Abre la app → pantalla **Bienvenida**.
2. Toca **Iniciar sesión**.
3. Ingresa correo y contraseña.
4. Toca **Entrar**.
   - **Usuario Regular** → navega a **Home** (feed de partidos).
   - **Admin** → navega al **Dashboard de Administrador**.
   - **Superadmin** → navega al **Dashboard de Superadmin** (incluye opción de crear admins).

> Si el usuario fue creado por el Superadmin y es su primer inicio de sesión, la app lo redirige a la pantalla **Establecer nueva contraseña** antes de continuar.

---

### Flujo 3 — Resumen del Perfil

Accesible para todos los tipos de usuario una vez autenticados.

**Desde Home (Usuario Regular):**
- Toca el ícono de perfil (esquina superior derecha o barra de navegación) → pantalla **Perfil**.

**Desde el Dashboard (Admin / Superadmin):**
- Toca el botón de perfil / menú → pantalla **Perfil**.

La pantalla de Perfil muestra:
- Nombre completo (editable)
- Correo electrónico (solo lectura)
- Teléfono (editable)
- Rol del usuario (`USUARIO`, `ADMINISTRADOR` o `SUPER ADMIN`)

Desde el perfil también es posible **cerrar sesión** o **eliminar la cuenta**.

---

## Arquitectura Frontend: Clean Architecture + BLoC

El frontend sigue **Clean Architecture** combinada con **BLoC**. La regla fundamental es que las capas externas dependen de las internas, nunca al revés. El dominio no conoce Flutter, ni Amplify, ni HTTP.

### Las tres capas

Cada feature vive en `lib/features/<feature>/` con tres subcarpetas que representan cada capa:

```
lib/features/auth/
├── domain/          ← núcleo puro, sin dependencias externas
│   ├── entities/    ← modelos de negocio (AuthUser)
│   ├── exceptions/  ← errores del dominio (AuthException)
│   ├── repository/  ← contrato abstracto (AuthRepository)
│   └── usecases/    ← una clase por operación de negocio
├── data/            ← implementa los contratos del dominio
│   ├── repository/  ← AuthRepositoryImpl (orquesta los datasources)
│   └── source/      ← datasources abstractos + implementaciones con SDK
└── ui/              ← presentación
    ├── bloc/        ← BLoC: eventos, estados, lógica de presentación
    └── screens/     ← widgets que renderizan la UI
```

### Dirección de dependencias

```
ui/screens  →  ui/bloc  →  domain/usecases  →  domain/repository (abstracto)
                                                        ↑
                                              data/repository (implementación)
                                                        ↓
                                              data/source (datasources)
```

- **`domain/`** no importa nada externo. Es Dart puro. Si se borra Flutter del proyecto, el dominio sigue compilando.
- **`data/`** depende del dominio porque implementa sus contratos (`AuthRepositoryImpl implements AuthRepository`).
- **`ui/`** depende solo del dominio (usa los use cases). Nunca importa nada de `data/`.

### Capa de Dominio

`AuthRepository` es una clase abstracta que declara el contrato de autenticación sin saber cómo se implementa. Los use cases (`SignInUseCase`, `SignUpUseCase`, etc.) encapsulan cada operación de negocio y dependen únicamente de esa abstracción. Las excepciones (`AuthException`, `NewPasswordRequiredException`) también viven en el dominio porque son conceptos del negocio que tanto los datasources como los BLoCs necesitan referenciar.

### Capa de Data

`AuthRepositoryImpl` implementa `AuthRepository` orquestando tres datasources:
- `CognitoAuthDataSource` — autenticación vía Amplify SDK (AWS Cognito)
- `SecureStorageDataSource` — persistencia de sesión local con `flutter_secure_storage`
- `UserProfileApiDataSource` — perfil de usuario vía HTTP al API Gateway

Cada datasource concreto implementa su respectiva interfaz abstracta (`RemoteAuthDataSource`, `LocalAuthDataSource`, `UserProfileDataSource`), aplicando inversión de dependencias en toda la cadena.

### Capa de Presentación (BLoC)

Cada pantalla tiene su BLoC. El BLoC recibe eventos de la UI, llama al use case correspondiente y emite estados. Nunca instancia repositorios ni datasources directamente.

El ensamblado de dependencias ocurre exclusivamente en `main.dart` (composition root):

```dart
'/login': (_) => BlocProvider<LoginBloc>(
  create: (_) => LoginBloc(
    SignInUseCase(AuthRepositoryImpl(CognitoAuthDataSource())),
  ),
  child: const LoginScreen(),
),
```

`LoginScreen` no sabe que existe Cognito. Solo sabe que hay un `LoginBloc` disponible en el árbol de widgets.

### Reglas de Desarrollo

1. **Uso obligatorio de `Key`:** Todos los widgets deben inicializarse con un `key` (ej. `super.key` en el constructor) para evitar ciclos de re-renderizado innecesarios en Flutter.

2. **StatefulWidgets:**
   * Limitados **exclusivamente** a las pantallas completas (Screens/Pages).
   * Se ubican en `lib/features/<feature>/ui/screens/`.
   * No contienen lógica de negocio — delegan al BLoC correspondiente.

3. **StatelessWidgets:**
   * Todo lo que no sea una pantalla completa debe ser un `StatelessWidget`.
   * Se ubican en `lib/widgets/` (componentes globales) o dentro de la carpeta `ui/` del feature.
   * Solo reciben datos y callbacks como parámetros. Nunca acceden al BLoC directamente.

4. **BLoC:**
   * Un BLoC por pantalla o tab, ubicado en `lib/features/<feature>/ui/bloc/`.
   * Solo conoce UseCases del dominio, nunca `RepositoryImpl` ni fuentes de datos.

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
* `lib/features/`: Features de la app, cada uno con subcarpetas `domain/`, `data/` y `ui/`.
* `lib/widgets/`: Componentes UI reutilizables y atomizados (StatelessWidget).
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


#### 4. Aplicar el schema y crear el SUPERADMIN
```bash
make db-migrate DB_PASSWORD=tu_password SUPERADMIN_PASSWORD=tu_password_superadmin
```
Crea el entorno virtual Python (`.venv/`) la primera vez, instala `psycopg2-binary` y `boto3`,
ejecuta `backend/db/schema.sql` sobre la RDS con SSL, y luego crea automáticamente el usuario
SUPERADMIN en Cognito y en `app_users`.

Variables opcionales del SUPERADMIN (tienen valores por defecto):

| Variable | Default |
|----------|---------|
| `SUPERADMIN_EMAIL` | `superadmin@uicesi.edu.co` |
| `SUPERADMIN_FULL_NAME` | `Super Administrador` |
| `SUPERADMIN_PHONE` | `+57000000000` |
| `SUPERADMIN_UNIVERSITY` | `Icesi` |

Ejemplo con todos los parámetros:
```bash
make db-migrate DB_PASSWORD=X SUPERADMIN_PASSWORD=Y \
  SUPERADMIN_EMAIL=admin@midominio.com \
  SUPERADMIN_FULL_NAME="Mi Nombre"
```

> El script de SUPERADMIN es **idempotente**: si el usuario ya existe en Cognito o en la BD,
> lo actualiza sin fallar. Se puede ejecutar varias veces con seguridad.

#### 5. Cargar datos de prueba (seed)
```bash
make db-seed DB_PASSWORD=tu_password
```

#### 6. (Opcional) Re-crear solo el SUPERADMIN sin re-migrar
Útil si ya tienes el schema aplicado y solo necesitas resetear el SUPERADMIN:
```bash
make superadmin-seed DB_PASSWORD=tu_password SUPERADMIN_PASSWORD=tu_password_superadmin
```

#### 7. (Opcional) Conectarse interactivamente a la base de datos
```bash
make db-connect DB_PASSWORD=tu_password
```

#### 8. Correr la app Flutter
```bash
flutter run
```

#### 9. Apagar la infraestructura al terminar
> **Importante:** siempre destruye la RDS al finalizar tu sesión para no generar costos.
```bash
make db-down DB_PASSWORD=tu_password
```

---

### Referencia rápida de targets

| Comando | Acción |
|---------|--------|
| `make venv` | Crea `.venv` e instala `psycopg2-binary` y `boto3` |
| `make db-up DB_PASSWORD=X` | `terraform apply` — levanta RDS y despliega Lambdas |
| `make db-migrate DB_PASSWORD=X SUPERADMIN_PASSWORD=Y` | Aplica `schema.sql` y crea el SUPERADMIN |
| `make superadmin-seed DB_PASSWORD=X SUPERADMIN_PASSWORD=Y` | Crea/actualiza solo el SUPERADMIN |
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
- Seed SUPERADMIN: `backend/db/seed_superadmin.py` (Cognito + BD)
- Datos de prueba: `backend/db/seed.sql` (2 equipos, 1 liga, 6 jugadores)
- La tabla de usuarios se llama `app_users` (`user` es palabra reservada en PostgreSQL)
- Toda conexión requiere `sslmode=require`
- La RDS es accesible públicamente (protegida por credenciales + SSL); las Lambdas en VPC la alcanzan por red privada
