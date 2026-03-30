# icesi_score

### Reglas de Desarrollo

1. **Uso obligatorio de `Key`:** Todos los widgets deben inicializarse con un `key` (ej. `super.key` en el constructor) para evitar ciclos de re-renderizado innecesarios en Flutter.

2. **Componentes Inteligentes (StatefulWidgets):**
   * Limitados **exclusivamente** a las Pantallas completas (Screens/Pages).
   * Se ubican en la carpeta `lib/screens/`.
   * Son responsables de manejar el estado de la aplicación, interactuar con los servicios y pasar la información a los componentes hijos.

3. **Componentes Tontos (StatelessWidgets):**
   * Todo lo que no sea una pantalla completa debe ser un `StatelessWidget`.
   * Se ubican en la carpeta `lib/widgets/` y están divididos por contexto (`common`, `match`, `soccer`, `volleyball`).
   * Solo reciben datos mediante parámetros y dibujan la interfaz. No manejan lógica de negocio ni estado interno. Si requieren una acción (como un botón), reciben la función como parámetro (Callbacks).

### Estructura de Carpetas Principal

* `assets/`: Fuentes, imágenes, logos de la universidad e iconos.
* `lib/models/`: Clases puras de Dart (ej. Team, Player, Match).
* `lib/screens/`: Pantallas principales de la app (Stateful).
* `lib/widgets/`: Componentes UI reutilizables y atomizados (Stateless).
* `lib/services/`: Lógica de conexión a backend y AWS.
* `lib/theme/`: Configuración global de Material App, colores y tipografías (Google Fonts).
