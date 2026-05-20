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

## Infraestructura en Tiempo Real (WebSockets)

### Visión General

Cuando un Admin registra un evento de fútbol, el sistema no solo actualiza la base de datos sino que propaga el cambio en tiempo real a todos los aficionados que en ese momento tienen abierta la pantalla de detalle de ese partido. El canal de transmisión es un WebSocket persistente gestionado por API Gateway v2.

---

### Flujo de Broadcast

1. **Admin registra un evento** — realiza una solicitud `POST /admin/matches/{id}/soccer-events` autenticada con JWT de Cognito.

2. **Lambda `post_soccer_event`** — valida el rol del usuario consultando `app_users WHERE id = cognito_sub` (el JWT no contiene `custom:role`; el rol solo vive en la base de datos). Una vez confirmado el acceso, inserta el evento en la tabla `soccer_event` y actualiza el marcador en la tabla `match`. La operación se realiza dentro de una única transacción.

3. **Publicación en SNS** — tras confirmar la transacción, `post_soccer_event` publica un mensaje en el topic `icesi-score-ws-broadcast`. La publicación es *fire-and-forget*: si falla, el error se registra en los logs pero la respuesta HTTP al Admin ya fue enviada con código `201`.

4. **SNS invoca `ws_broadcaster`** — SNS entrega el mensaje de forma asíncrona a la Lambda `icesi-score-ws-broadcaster` mediante una suscripción de tipo `lambda`.

5. **`ws_broadcaster` consulta DynamoDB** — hace un `Scan` sobre la tabla `icesi-score-ws-connections` filtrando por el `match_id` del evento para obtener todos los `connectionId` activos de ese partido.

6. **Envío por WebSocket** — para cada `connectionId`, `ws_broadcaster` llama a `postToConnection` de la API Gateway Management API, enviando un mensaje con la siguiente estructura:

   ```json
   {
     "type": "SOCCER_EVENT",
     "event": { ... },
     "newScore": { "homeScore": 1, "awayScore": 0 }
   }
   ```

   Si `postToConnection` retorna `GoneException` (conexión muerta), `ws_broadcaster` elimina automáticamente ese registro de DynamoDB.

7. **Flutter actualiza la UI** — la pantalla del aficionado recibe el mensaje por el canal WebSocket y actualiza la línea de tiempo y el marcador sin necesidad de pull-to-refresh.

---

### Ciclo de Vida de la Conexión WebSocket

**Al entrar a la pantalla de detalle de un partido:**
- Flutter obtiene el `idToken` de Cognito y abre una conexión WSS hacia el API Gateway WebSocket, enviando `?token=<idToken>&match_id=<matchId>` como parámetros de query.
- La Lambda `ws_connect` valida el token y escribe `{ connectionId, match_id, ttl }` en DynamoDB con un TTL de 24 horas.

**Al salir de la pantalla:**
- Flutter cierra el canal WebSocket.
- La Lambda `ws_disconnect` elimina el registro del `connectionId` de DynamoDB.

---

### Decisiones de Infraestructura y Free Tier

#### 1. `post_soccer_event` fuera de la VPC

La Lambda `post_soccer_event` corre fuera de la VPC. Una Lambda dentro de la VPC sin NAT Gateway ni VPC Endpoints no puede alcanzar SNS, DynamoDB ni la API de Lambda; las únicas alternativas serían agregar un NAT Gateway (~32 USD/mes) o VPC Endpoints (~7 USD/mes por servicio). Como la RDS ya es públicamente accesible (`publicly_accessible = true`, security group con ingress `0.0.0.0/0:5432`), mover la Lambda fuera de la VPC no introduce riesgo adicional: la conexión a la base de datos usa `sslmode=require` en todos los casos.

#### 2. SNS como intermediario del broadcast

`post_soccer_event` no invoca a `ws_broadcaster` directamente. En cambio, publica en el topic SNS `icesi-score-ws-broadcast` y SNS se encarga de invocar a `ws_broadcaster` como suscriptor Lambda. Este patrón desacopla ambas funciones, es elegible para el free tier de SNS (1 millón de publicaciones/mes gratuitas) y permite que `ws_broadcaster` viva fuera de la VPC con acceso completo a DynamoDB y API Gateway. La alternativa descartada fue un VPC Endpoint para Lambda (~7 USD/mes).

#### 3. Rol del usuario en PostgreSQL, no en Cognito

El JWT de Cognito no incluye `custom:role`. Todos los Lambdas que requieren validación de rol ejecutan una consulta adicional:

```sql
SELECT role FROM app_users WHERE id = %s  -- %s = cognito_sub extraído del JWT
```

Esto implica una consulta extra a la base de datos por cada solicitud autenticada que requiera control de acceso por rol.

#### 4. DynamoDB para la gestión de conexiones WebSocket

La tabla `icesi-score-ws-connections` almacena `connectionId` (clave de partición), `match_id` y un TTL de 24 horas. Las conexiones obsoletas se limpian de dos formas: DynamoDB las expira automáticamente vía TTL, y `ws_broadcaster` las elimina inmediatamente al detectar un `GoneException` al intentar enviar un mensaje.

---

### Limitaciones Conocidas del MVP

Las siguientes limitaciones están identificadas y se abordarán en sprints futuros:

1. **Admin no recibe actualizaciones en tiempo real de otros admins.** El `LiveModeScreen` del Admin no tiene listener WebSocket. Si dos admins operan el mismo partido simultáneamente, cada uno solo verá sus propios cambios localmente. Pendiente: agregar un listener WebSocket en `LiveModeBloc`.

2. **El marcador del aficionado solo se actualiza en tiempo real mientras la pantalla está abierta.** Al reabrir la pantalla de detalle, el marcador se toma del objeto `Match` del feed. Si el feed no se ha recargado, el marcador puede estar desactualizado hasta el próximo pull-to-refresh o recarga automática.

3. **La RDS es públicamente accesible por diseño de desarrollo (free tier).** En un entorno de producción se recomienda: RDS privada en VPC, NAT Gateway o VPC Endpoints para las Lambdas que lo requieran, y remover el ingress `0.0.0.0/0` del security group de la base de datos.

4. **El aficionado no ve la transición SCHEDULED → IN_PROGRESS en tiempo real si ya tenía la pantalla abierta.** El WebSocket del `MatchDetailScreen` solo se conecta cuando el partido llega con estado `IN_PROGRESS`. Si el aficionado abrió la pantalla mientras el partido estaba `SCHEDULED` y el Admin inicia el primer tiempo después, el aficionado no recibirá el mensaje `CLOCK_UPDATE START`. Debe hacer pull-to-refresh para ver el partido en vivo. Esto es un compromiso conocido del MVP para evitar conexiones WebSocket en partidos no iniciados.

---

## Sprint 2 — Gestión y Visualización de Partidos

### Contexto

Sprint 2 introduce las dos funcionalidades centrales de la plataforma: la creación de partidos por parte de los Admins y el feed de partidos visible para todos los usuarios autenticados.

---

### Flujo 1 — Creación de Partido (US-08)

Solo disponible para el rol **Admin**. El botón flotante (FAB) no aparece para Superadmins.

1. Inicia sesión como **Admin** → **Dashboard de Administrador**.
2. Toca el botón **+** (esquina inferior derecha).
3. Selecciona el deporte con las tarjetas de selección:
   - **Fútbol** o **Voleibol**
   - La tarjeta activa muestra un borde azul.
4. Elige el **equipo local** y el **equipo visitante** en los desplegables.
   - Los equipos se filtran automáticamente según el deporte seleccionado.
   - No se puede seleccionar el mismo equipo en ambos campos.
5. Completa los campos obligatorios:

| Campo | Tipo |
|-------|------|
| Fecha del partido | Selector de fecha (YYYY-MM-DD) |
| Hora del partido | Selector de hora (HH:MM) |
| Liga | Desplegable con las ligas existentes |
| Sede / Cancha | Texto libre |

6. (Opcional) Agrega notas adicionales en el campo de texto.
7. Toca **Crear partido**.
   - Campos faltantes o conflicto de datos en la API → diálogo de error con el mensaje correspondiente.
   - Éxito → snackbar de confirmación, regresa al dashboard y recarga el feed automáticamente.

El partido se inserta con `status = SCHEDULED`. El campo `id_admin_creador` se toma del `sub` del JWT del usuario autenticado.

---

### Flujo 2 — Feed de Partidos (US-05)

Accesible para **todos los usuarios** autenticados. El **Admin** lo ve dentro del Dashboard de Administrador (reemplaza el bloque "próximamente"); el **Usuario Regular** lo ve en la pantalla **Home**.

1. Inicia sesión con cualquier rol.
2. La barra superior contiene un selector de deporte integrado, sin elevación ni separación visual respecto al AppBar:
   - **Fútbol** | **Voleibol**
   - El tab activo muestra un subrayado en azul.
3. La lista de partidos se carga automáticamente al entrar a la pantalla.
4. Cada elemento de la lista contiene:
   - Una **etiqueta superior** independiente de la tarjeta (texto en gris claro, alineado a la izquierda):
     - `SCHEDULED` → hora del partido (ej. "16:00")
     - `IN_PROGRESS` → "LIVE"
     - `FINISHED` → "Terminado"
   - La **tarjeta del partido** con equipo local, equipo visitante y el área central:
     - `SCHEDULED` → hora del partido
     - `IN_PROGRESS` → badge LIVE + marcador en naranja
     - `FINISHED` → marcador final en blanco (sin badge)

> El marcador (`homeScore` / `awayScore`) solo se expone desde el backend cuando el partido está en `IN_PROGRESS` o `FINISHED`. Para partidos `SCHEDULED` la API devuelve `null` en esos campos.

5. Desliza hacia abajo para recargar el feed manualmente (pull-to-refresh).
6. El feed también se recarga de forma automática al regresar desde la pantalla de creación de partido.
7. Toca una tarjeta para navegar al detalle según el rol:
   - **Usuario Regular** → pantalla de detalle de partido (en desarrollo).
   - **Admin** → panel de modo live (en desarrollo).

---

### Flujo 3 — Modo Live (US-06 / US-11)

El Modo Live es la pantalla exclusiva para el rol **Admin** que permite registrar eventos de partido en tiempo real directamente sobre la alineación visual. El Admin accede desde el Dashboard al tocar la tarjeta de un partido con estado `IN_PROGRESS`.

La pantalla está dividida en tres bloques: el marcador con el período activo en curso, el campo interactivo con los once jugadores de cada equipo posicionados según la formación 1-4-4-2, y la banca con los suplentes de ambos equipos. Al tocar cualquier jugador, ya sea en el campo o en la banca, se despliega un menú inferior con los eventos disponibles para ese jugador.

---

#### Campo interactivo — correcciones de formación y flujo

**Formación y posicionamiento.** El campo usa una formación fija 1-4-4-2 para ambos equipos. Los jugadores locales ocupan la mitad inferior y los visitantes la superior; cada línea (portero, defensas, mediocampistas y delanteros) está separada un 11 % de la altura total del campo, de modo que ningún delantero cruza la línea de mediocampo y no hay solapamiento visual entre jugadores de equipos distintos. El nombre de cada jugador aparece siempre debajo de su burbuja, independientemente del equipo al que pertenezca.

**Jugadores expulsados.** Cuando un jugador recibe tarjeta roja y su estado cambia a `EXPELLED`, su burbuja pasa a color gris y muestra un indicador rojo en la esquina superior derecha. El jugador permanece visible en su posición del campo pero deja de ser tappable, lo que impide registrarle eventos adicionales por error. El mismo comportamiento aplica a los suplentes expulsados en la sección de banca.

**Tarjetas amarillas.** Al registrar una tarjeta amarilla aparece de inmediato un indicador amarillo en la esquina superior derecha de la burbuja del jugador. Si ese mismo jugador acumula dos tarjetas amarillas, el indicador pasa a rojo y la burbuja se torna gris, replicando visualmente el estado de expulsión. Este cambio es únicamente una indicación local para el Admin; el jugador queda formalmente expulsado en el sistema solo cuando el Admin registra la tarjeta roja correspondiente.

**Herencia de posición en la sustitución.** Al confirmar una sustitución, el jugador que entra ocupa exactamente la misma ranura del campo que tenía el jugador que sale; ningún otro jugador se desplaza. Esto se logra intercambiando posiciones directamente en la lista de alineación en el momento de la sustitución, sin reordenar el resto de la lista.

**Sustitución iniciada desde la banca.** Al tocar un suplente, el formulario de sustitución lo pre-rellena como el jugador que entra y muestra un desplegable obligatorio con los jugadores en campo del mismo equipo para seleccionar quién sale. Cuando la sustitución se inicia desde el campo, el comportamiento es el inverso: el jugador tocado queda pre-relleno como el que sale y el desplegable lista los suplentes disponibles. En ambos casos el evento enviado al backend mantiene la misma semántica: `mainPlayerId` identifica al jugador que abandona el campo y `secondaryPlayerId` al que entra.

**Tarjetas de eventos recientes.** Las tarjetas de sustitución en la sección de eventos muestran ambos jugadores: el que sale con una flecha hacia abajo en rojo y el que entra con una flecha hacia arriba en verde. Las tarjetas de segunda tarjeta amarilla incluyen además el texto "(Expulsado)" junto a un indicador rojo para que la doble amonestación sea identificable en el historial del partido.

**Recarga automática del feed.** Al regresar de cualquier pantalla de detalle de partido, tanto el Modo Live del Admin como la vista de detalle del aficionado, el feed de partidos se recarga automáticamente. De este modo el marcador y el estado del partido se reflejan de forma inmediata sin necesidad de hacer pull-to-refresh manual.

---

#### Registro de Eventos en Vivo

Al tocar cualquier jugador del campo o de la banca, aparece un panel inferior con las acciones disponibles para ese jugador. Los jugadores en campo ofrecen seis opciones: Gol, Asistencia, Tarjeta Amarilla, Tarjeta Roja, Sustitución y Nota. Los suplentes que todavía no han jugado ofrecen cuatro: Sustitución (como jugador que entra), Tarjeta Amarilla, Tarjeta Roja y Nota. Los jugadores que ya fueron sustituidos y regresaron a la banca solo pueden recibir Tarjeta Amarilla, Tarjeta Roja y Nota; la opción de Sustitución desaparece porque un jugador que salió no puede re-ingresar.

Cada tipo de evento tiene su propio formulario con un campo de minuto editable, pre-calculado desde el inicio del período activo:

**Gol** — permite vincular opcionalmente una asistencia seleccionando otro jugador del mismo equipo en campo. Si se activa el toggle de asistencia, el desplegable de jugadores se vuelve obligatorio. Al confirmar, el evento de gol y el de asistencia se registran en la misma llamada.

**Asistencia independiente** — permite vincular la asistencia a un gol existente del partido que aún no tenga asistencia registrada, seleccionándolo desde un desplegable con el minuto y el nombre del goleador.

**Tarjeta Amarilla / Tarjeta Roja** — muestra únicamente el campo de minuto. La tarjeta roja incluye un aviso de que el jugador será marcado como expulsado en la base de datos.

**Sustitución** — muestra el jugador fijo como referencia (el que sale si se inició desde el campo; el que entra si se inició desde la banca) y un desplegable obligatorio para seleccionar al otro participante. El cuerpo enviado al backend siempre usa `mainPlayerId` para el jugador que abandona el campo y `secondaryPlayerId` para el que ingresa, independientemente de desde qué lado se inició la acción.

**Nota** — campo de texto libre de hasta 200 caracteres con el minuto de referencia.

Al confirmar cualquier evento, el BLoC emite un estado de éxito, muestra un snackbar informativo y recarga la lista de eventos del partido desde la API.

---

### Flujo 4 — Detalle de Partido - Fútbol (US-06)

Accesible para el rol **Usuario Regular** al tocar cualquier tarjeta de partido de fútbol en el feed. Los Admins acceden al Modo Live en su lugar.

La pantalla abre con un encabezado cuyo contenido central varía según el estado del partido. Para `SCHEDULED`, el centro muestra la fecha y la hora programada. Para `IN_PROGRESS`, aparece el badge `LIVE`, el marcador en naranja y un reloj corriendo en formato `MM:SS` que se actualiza cada segundo mediante un `Timer` local. El reloj calcula el tiempo transcurrido comparando el instante actual con el campo `start_time` del período activo; no hay ninguna consulta al servidor en cada tick. Para `FINISHED`, el centro muestra el marcador final en blanco con la etiqueta "Final".

La sección principal es la línea de tiempo de eventos, ordenada de más reciente a más antigua. Cada tarjeta es expandible al tocarla: los goles revelan el nombre del goleador y la asistencia si la hay; las sustituciones muestran una flecha roja hacia abajo con el jugador saliente y una flecha verde hacia arriba con el jugador entrante; las segundas tarjetas amarillas incluyen el texto "(Expulsado)" junto a un indicador rojo en el historial. Para partidos `SCHEDULED`, la línea de tiempo se reemplaza por el mensaje "El partido aún no ha comenzado."

Cuando el partido está `IN_PROGRESS`, la pantalla abre una conexión WebSocket al inicializarse. Los eventos que llegan por el canal se incorporan al inicio de la lista y el marcador se actualiza sin necesidad de pull-to-refresh. Al salir de la pantalla, la conexión se cierra y el feed de partidos se recarga automáticamente.

---

### Flujo 5 — Detalle de Partido - Voleibol (US-07)

Accesible para el rol **Usuario Regular** al tocar una tarjeta de partido de voleibol en el feed.

El encabezado muestra los sets ganados por cada equipo. Para `SCHEDULED`, el centro presenta la hora programada. Para `IN_PROGRESS` y `FINISHED`, el marcador de sets aparece en amarillo con la etiqueta "Sets".

Debajo del encabezado, si existe un set activo, aparece el bloque de **puntaje del set en curso**: el tanteo del set (`homeScore - awayScore`) en amarillo a 36 puntos, con el número de set en gris. Este bloque está ausente en partidos `SCHEDULED`.

Le sigue la tarjeta de **Set Scores**, que lista todos los sets jugados. El set activo tiene un fondo más cálido, un borde amarillo y el badge `LIVE`; los sets cerrados usan el estilo estándar con los colores de cada equipo. Si no hay sets registrados aún, la tarjeta muestra un mensaje informativo.

La línea de tiempo de eventos usa tarjetas expandibles. Cada tarjeta muestra a la izquierda el marcador en el momento del evento (`score_moment`), el emoji representativo del tipo y la descripción. Los tipos posibles son: Punto, Ace de Servicio, Bloqueo, Falta de Rotación, Sustitución y Nota. Al expandir una tarjeta, se muestra el nombre del jugador involucrado cuando está disponible.

Cuando el partido está `IN_PROGRESS`, la pantalla se conecta al WebSocket. A diferencia de fútbol, los eventos de voleibol no se incorporan incrementalmente: al recibir un mensaje de tipo `VOLLEYBALL_EVENT`, la pantalla dispara una recarga completa de sets y eventos desde la API.

---

### Flujo 6 — Edición y Eliminación de Partidos (US-09, US-10)

Solo disponible para el rol **Admin**. Ambas acciones están restringidas a partidos en estado `SCHEDULED`; la API rechaza cualquier intento sobre partidos `IN_PROGRESS` o `FINISHED`.

El feed del Admin muestra las mismas tarjetas que el usuario regular, pero con soporte de swipe. Al deslizar una tarjeta hacia la izquierda emerge un panel con dos botones: **Editar** y **Eliminar**. Si el partido no está en estado `SCHEDULED`, los botones aparecen en gris y no responden a toques. Deslizar la tarjeta hacia la derecha o tocarla cierra el panel sin disparar ninguna acción.

**Editar partido** — Al tocar Editar sobre un partido `SCHEDULED`, la app navega al formulario de creación pre-cargado con todos los campos actuales: deporte, equipo local, visitante, liga, fecha, hora, sede y notas. El formulario es idéntico al de creación; al confirmar se envía `PUT /admin/matches/{id}`. Al completarse con éxito, la app regresa al dashboard y muestra un snackbar de confirmación.

**Eliminar partido** — Al tocar Eliminar aparece un diálogo de confirmación. Si el Admin confirma, la app envía `DELETE /admin/matches/{id}`. Al retornar al feed, el partido ya no aparece en la lista. Si el partido cambió de estado entre el swipe y la confirmación, la API devuelve un error que se muestra en pantalla.

En ambos casos, al regresar al dashboard el feed se recarga automáticamente para reflejar los cambios.

---

### Referencia de Endpoints REST — Sprint 2

Todos los endpoints requieren JWT de Cognito en el encabezado `Authorization`. Los endpoints bajo `/admin/` validan el rol consultando `app_users` en PostgreSQL antes de ejecutar cualquier operación.

| Método | Ruta | Lambda | Acceso |
|--------|------|--------|--------|
| `GET` | `/matches` | `get_matches` | Todos |
| `GET` | `/teams` | `get_teams` | Todos |
| `GET` | `/leagues` | `get_leagues` | Todos |
| `POST` | `/admin/matches` | `create_match` | ADMIN, SUPERADMIN |
| `PUT` | `/admin/matches/{id}` | `update_match` | ADMIN, SUPERADMIN |
| `DELETE` | `/admin/matches/{id}` | `delete_match` | ADMIN, SUPERADMIN |
| `GET` | `/matches/{id}/soccer-events` | `get_soccer_events` | Todos |
| `POST` | `/admin/matches/{id}/soccer-events` | `post_soccer_event` | ADMIN, SUPERADMIN |
| `GET` | `/matches/{id}/periods` | `get_match_periods` | Todos |
| `GET` | `/matches/{id}/lineup` | `get_match_lineup` | Todos |
| `GET` | `/matches/{id}/volleyball-data` | `get_volleyball_data` | Todos |

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
