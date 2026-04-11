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
1. Instalar [AWS CLI](https://aws.amazon.com/cli/).
2. Instalar [Terraform](https://developer.hashicorp.com/terraform/install).
3. Solicitar las llaves de acceso de AWS (`Access Key` y `Secret Key`).

### Pasos para levantar la nube

1. **Configurar credenciales de AWS:**
   ```bash
   aws configure
   ```
   Ingresa las llaves proporcionadas. Usa `us-east-2` como región y `json` como formato.

2. **Desplegar con Terraform:**
   ```bash
   cd infrastructure
   terraform init
   terraform apply
   ```
   Escribe `yes` cuando te pida confirmación. Esto creará los recursos en AWS y generará el archivo `amplifyconfiguration.dart` en tu carpeta `lib/`.

3. **Correr la App:**
   Vuelve a la raíz del proyecto y lanza la aplicación en tu emulador o dispositivo:
   ```bash
   cd ..
   flutter run
   ```

### Apagar la infraestructura (Importante)
**SIEMPRE** destruye la infraestructura al terminar tu sesión de trabajo si nadie más la está usando:
```bash
cd infrastructure
terraform destroy
```
Escribe `yes` para confirmar.
