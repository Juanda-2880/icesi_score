# Sprint Tasks — IcesiScore

Estas son las tareas pendientes para el sprint actual. Cada tarea vive en su propia rama y termina en un PR hacia `feature/infra-and-ui-sync`.

---

## Aviso importante

Solo 2 miembros del equipo tienen usuario IAM en AWS. La aplicación requiere el archivo `lib/amplifyconfiguration.dart` (generado por Terraform y excluido del repositorio) para iniciar. **Si no tienes ese archivo, la app no compila.**

Lo que esto significa para cada tarea:

- **Tarea 1 (WelcomeScreen):** cambios de texto y eliminación de un bloque de widgets. No requiere ejecutar la app — basta con leer el archivo, hacer el cambio y confirmar que el código compila con `flutter analyze`.
- **Tarea 3 (seed.sql):** es SQL puro, sin relación con Flutter ni Amplify. Solo edita el archivo y verifica que la sintaxis sea correcta.
- **Tarea 2 (VerifyScreen):** es la más delicada porque implica lógica de UI con estado. Ver consejos abajo.

### Consejos para la Tarea 2 sin poder correr la app

1. **Usa `flutter analyze`** desde la raíz del proyecto para detectar errores de tipos, controladores no cerrados o referencias rotas antes de hacer PR. No compila la app, solo analiza el código estáticamente.
   ```bash
   flutter analyze lib/features/verify/
   ```
2. **Lee el código existente antes de modificar.** El archivo `verify_screen.dart` ya tiene un `_VerifyScreenState` con un `TextEditingController` y un `FocusNode` implícito. La tarea consiste en reemplazar ese patrón por 6 controllers y 6 focus nodes — la estructura es la misma, solo se multiplica.
3. **El `dispose()` es crítico.** Si agregas controllers o focus nodes y no los dispones, `flutter analyze` lo detectará como un leak. Asegúrate de iterar sobre las dos listas en `dispose()`.
4. **No toques el BLoC ni los estados.** El evento `VerifyCodeSubmittedEvent` ya recibe el código como `String`. Tu único trabajo en `_submit()` es construir ese string uniendo los 6 controllers: `_digitControllers.map((c) => c.text).join()`.
5. **El código de la tarea es autocontenido.** Todo el cambio vive dentro de `_VerifyScreenState` y en el `build()` de la misma clase. No necesitas modificar ningún otro archivo.

---

## Flujo de colaboración

```
main
 └── feature/infra-and-ui-sync          ← rama base del sprint
       ├── feat/welcome-tagline          ← Tarea 1
       ├── feat/verify-otp-boxes         ← Tarea 2
       └── feat/seed-teams-players       ← Tarea 3
```

**Pasos para cada colaborador:**

1. Asegúrate de tener la rama base actualizada:
   ```bash
   git fetch origin
   git checkout feature/infra-and-ui-sync
   git pull origin feature/infra-and-ui-sync
   ```
2. Crea tu rama desde ahí:
   ```bash
   git checkout -b feat/<nombre-de-tu-rama>
   ```
3. Realiza los cambios descritos en tu tarea.
4. Haz commit y abre un **Pull Request hacia `feature/infra-and-ui-sync`** (no hacia `main`).
5. Notifica al responsable de integración para que haga el merge.

> El responsable de integración (`Melo088`) recogerá los 3 PRs, los mergeará en `feature/infra-and-ui-sync` y abrirá el PR final hacia `main`.

---

## Tarea 1 — Ajuste de textos en WelcomeScreen

**Rama:** `feat/welcome-tagline`  
**Archivo:** `lib/features/login/ui/screens/welcome_screen.dart`

### Cambio 1 — Tagline

Busca el `Text` con el contenido `'Track - Predict - Win'` (línea ~49) y reemplaza únicamente el string:

```dart
// Antes
'Track - Predict - Win'

// Después
'Track • Follow • Stay Updated'
```

### Cambio 2 — Eliminar sección SSO

Elimina el bloque completo que va desde el `SizedBox(height: 40)` justo después del botón "Registrarse" hasta el cierre de la `Column` (inclusive el `SizedBox(height: 20)` del final). Es decir, borra estas líneas:

```dart
const SizedBox(height: 40),
const Text(
  'Are you a university administrator?',
  style: TextStyle(color: Colors.grey),
),
TextButton(
  onPressed: () {},
  child: const Text(
    'Log in with Icesi SSO',
    style: TextStyle(color: Color(0xFF5C5CFF)),
  ),
),
const SizedBox(height: 20),
```

El widget resultante debe quedar con el botón "Registrarse" como último elemento visible antes del cierre de la `Column`.

---

## Tarea 2 — OTP con casillas individuales en VerifyScreen

**Rama:** `feat/verify-otp-boxes`  
**Archivo:** `lib/features/verify/ui/screens/verify_screen.dart`

Reemplaza el `TextField` único (`_codeController`) por 6 casillas independientes que avancen automáticamente al completar cada dígito.

### Cambios en el estado (`_VerifyScreenState`)

Elimina:
```dart
final _codeController = TextEditingController();
```

Agrega:
```dart
final List<TextEditingController> _digitControllers =
    List.generate(6, (_) => TextEditingController());
final List<FocusNode> _focusNodes =
    List.generate(6, (_) => FocusNode());
```

Actualiza `dispose()` para limpiar los nuevos controllers y focus nodes:
```dart
@override
void dispose() {
  _bloc.close();
  for (final c in _digitControllers) c.dispose();
  for (final f in _focusNodes) f.dispose();
  super.dispose();
}
```

### Cambios en `_submit()`

Reemplaza la lectura de `_codeController.text` por la unión de los 6 dígitos:
```dart
void _submit() {
  final code = _digitControllers.map((c) => c.text).join();
  if (code.length != 6) {
    _showError('El código debe tener exactamente 6 dígitos.');
    return;
  }
  _bloc.add(VerifyCodeSubmittedEvent(email: _email, code: code));
}
```

### Cambios en `build()` — reemplazar el TextField

Elimina el `TextField` existente y sustituye ese bloque por una `Row` con 6 campos:

```dart
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: List.generate(6, (i) => SizedBox(
    width: 44,
    child: TextField(
      controller: _digitControllers[i],
      focusNode: _focusNodes[i],
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      maxLength: 1,
      decoration: InputDecoration(
        counterText: '',
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2),
        ),
      ),
      onChanged: (value) {
        if (value.length == 1 && i < 5) {
          _focusNodes[i + 1].requestFocus();
        } else if (value.isEmpty && i > 0) {
          _focusNodes[i - 1].requestFocus();
        }
      },
    ),
  )),
),
```

---

## Tarea 3 — Seed de equipos y jugadores

**Rama:** `feat/seed-teams-players`  
**Archivo:** `backend/db/seed.sql`

### Contexto del schema

Las dos tablas que debes poblar son:

```
team
  id               UUID  PK
  name             VARCHAR(255)  NOT NULL
  sport            sport_type    NOT NULL   → solo acepta: 'FOOTBALL' | 'VOLLEYBALL'

player
  id               UUID  PK
  team_id          UUID  FK → team.id
  full_name        VARCHAR(255)  NOT NULL
  standard_position VARCHAR(100)           → posición habitual del jugador (texto libre)
  jersey_number    INT   NOT NULL
```

**Distinción importante:** `standard_position` en `player` es la posición general del jugador (rol permanente, texto libre). No confundir con `position_coordinate` en `match_lineup`, que es la posición táctica en cancha durante un partido (`'PO'`, `'DF_IZQ'`… para fútbol; `'1'`–`'6'` para voleibol).

**Convención para `standard_position`:**
- Fútbol: `PO` · `DF_IZQ` · `DF_CEN` · `DF_DER` · `MED_IZQ` · `MED_CEN` · `MED_DER` · `DEL`
- Voleibol: `LIBERO` · `SETTER` · `OUTSIDE` · `OPPOSITE` · `MIDDLE`

### Qué hacer

Reemplaza el bloque de `INSERT INTO team` y todos los `INSERT INTO player` del archivo actual por los 4 equipos y sus jugadores. Mantén el encabezado de comentarios y el `INSERT INTO league` que ya existe.

> El seed actual tiene 2 equipos y 3 jugadores por equipo con UUIDs distintos a los que se proponen abajo. Si la base ya tiene esos datos, ejecuta primero:
> ```sql
> TRUNCATE player, team CASCADE;
> ```

### Equipos

```sql
INSERT INTO team (id, name, sport) VALUES
    ('a1000000-0000-0000-0000-000000000001', 'Icesi FC',         'FOOTBALL'),
    ('a1000000-0000-0000-0000-000000000002', 'Univalle FC',      'FOOTBALL'),
    ('a2000000-0000-0000-0000-000000000001', 'Icesi Volley',     'VOLLEYBALL'),
    ('a2000000-0000-0000-0000-000000000002', 'Javeriana Volley', 'VOLLEYBALL');
```

### Jugadores (15 por equipo)

Crea un `INSERT INTO player` separado para cada equipo con exactamente 15 filas.  
Usa el prefijo de UUID correspondiente al equipo para que los IDs sean legibles:

| Equipo           | UUID del equipo                        | Prefijo para jugadores          |
|------------------|----------------------------------------|---------------------------------|
| Icesi FC         | `a1000000-0000-0000-0000-000000000001` | `c1010000-0000-0000-0000-0000000000XX` |
| Univalle FC      | `a1000000-0000-0000-0000-000000000002` | `c1020000-0000-0000-0000-0000000000XX` |
| Icesi Volley     | `a2000000-0000-0000-0000-000000000001` | `c2010000-0000-0000-0000-0000000000XX` |
| Javeriana Volley | `a2000000-0000-0000-0000-000000000002` | `c2020000-0000-0000-0000-0000000000XX` |

Donde `XX` va del `01` al `15`.

**Ejemplo para Icesi FC** (completa las 12 filas restantes siguiendo el mismo patrón):

```sql
-- Players — Icesi FC (football)
INSERT INTO player (id, team_id, full_name, standard_position, jersey_number) VALUES
    ('c1010000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000001', 'Carlos Mena',    'PO',      1),
    ('c1010000-0000-0000-0000-000000000002', 'a1000000-0000-0000-0000-000000000001', 'Luis Torres',    'DF_DER',  2),
    ('c1010000-0000-0000-0000-000000000003', 'a1000000-0000-0000-0000-000000000001', 'Andrés Gómez',   'DEL',     9);
    -- ... 12 jugadores más
```

**Ejemplo para Univalle FC** (completa las 12 filas restantes):

```sql
-- Players — Univalle FC (football)
INSERT INTO player (id, team_id, full_name, standard_position, jersey_number) VALUES
    ('c1020000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000002', 'Jorge Montoya',   'PO',      1),
    ('c1020000-0000-0000-0000-000000000002', 'a1000000-0000-0000-0000-000000000002', 'Ricardo Palacios','DF_CEN',  4),
    ('c1020000-0000-0000-0000-000000000003', 'a1000000-0000-0000-0000-000000000002', 'Diego Cortés',    'DEL',     9);
    -- ... 12 jugadores más
```

**Ejemplo para Icesi Volley** (completa las 12 filas restantes):

```sql
-- Players — Icesi Volley (volleyball)
INSERT INTO player (id, team_id, full_name, standard_position, jersey_number) VALUES
    ('c2010000-0000-0000-0000-000000000001', 'a2000000-0000-0000-0000-000000000001', 'Sofia Ríos',       'LIBERO',  1),
    ('c2010000-0000-0000-0000-000000000002', 'a2000000-0000-0000-0000-000000000001', 'Valentina Cruz',   'SETTER',  2),
    ('c2010000-0000-0000-0000-000000000003', 'a2000000-0000-0000-0000-000000000001', 'Mariana López',    'OUTSIDE', 3);
    -- ... 12 jugadores más
```

**Ejemplo para Javeriana Volley** (completa las 12 filas restantes):

```sql
-- Players — Javeriana Volley (volleyball)
INSERT INTO player (id, team_id, full_name, standard_position, jersey_number) VALUES
    ('c2020000-0000-0000-0000-000000000001', 'a2000000-0000-0000-0000-000000000002', 'Alejandra Muñoz',  'LIBERO',  1),
    ('c2020000-0000-0000-0000-000000000002', 'a2000000-0000-0000-0000-000000000002', 'Carolina Rivas',   'SETTER',  2),
    ('c2020000-0000-0000-0000-000000000003', 'a2000000-0000-0000-0000-000000000002', 'Manuela Bernal',   'OUTSIDE', 3);
    -- ... 12 jugadores más
```

### Restricciones a respetar
- `jersey_number` debe ser único dentro de cada equipo.
- Los UUIDs de jugadores no pueden repetirse entre equipos.
- `sport` solo acepta los valores del enum: `'FOOTBALL'` o `'VOLLEYBALL'`.
- El `team_id` de cada jugador debe coincidir exactamente con el UUID del equipo al que pertenece.
