# IcesiScore

Plataforma móvil para el seguimiento de partidos deportivos universitarios (Fútbol y Voleibol) en tiempo real.

---

## Sprint 1 - Autenticación de Usuarios

### Contexto

IcesiScore maneja tres tipos de usuario, cada uno con un flujo de autenticación propio:

| Tipo | Descripción | Cómo se crea |
|------|-------------|--------------|
| **Usuario Regular** | Aficionado que consulta partidos y estadísticas en tiempo real | Auto-registro desde la app |
| **Admin** | Gestiona equipos, ligas y partidos en el dashboard administrativo | Lo crea el Superadmin desde la app |
| **Superadmin** | Control total de la plataforma; puede promover otros admins | Se crea con el script de seed (`make db-migrate`) |

---

### Flujo 1 - Registro (Usuario Regular)

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

### Flujo 2 - Inicio de Sesión

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

### Flujo 3 - Resumen del Perfil

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

### Flujo 4 - Restauración de Sesión

Al abrir la app sin haber cerrado sesión explícitamente, el sistema recupera la sesión guardada localmente sin mostrar la pantalla de Bienvenida ni pedir credenciales de nuevo.

1. La app muestra un indicador de carga en la pantalla inicial mientras resuelve la sesión.
2. `GetStoredSessionUseCase` lee el `AuthUser` serializado desde `FlutterSecureStorage`.
3. Si la sesión existe, se carga en `SessionCubit` y la app navega directamente a la pantalla correspondiente al rol:
   - **Usuario Regular** - Home (feed de partidos).
   - **Admin** - Dashboard de Administrador.
   - **Superadmin** - Dashboard de Superadmin.
4. Si no hay sesión guardada (primer uso o después de un cierre de sesión explícito), la app navega a la pantalla de **Bienvenida**.

La sesión se persiste en `FlutterSecureStorage` al completar el login y se elimina al cerrar sesión o al eliminar la cuenta.

---

### Registro de Usuarios en la Base de Datos

Cuando un usuario regular completa la verificación del código de correo, Cognito invoca automáticamente la Lambda `post_confirmation` (trigger `PostConfirmation`). Esta Lambda inserta el nuevo usuario en la tabla `app_users` con `role = NORMAL`, usando el `sub` de Cognito como identificador primario. El proceso es transparente para el usuario y ocurre antes de que la app navegue al Home.

---

### Referencia de Endpoints REST - Sprint 1

Todos los endpoints requieren JWT de Cognito en el encabezado `Authorization`.

| Método | Ruta | Lambda | Acceso |
|--------|------|--------|--------|
| `GET` | `/user/profile` | `get_user_profile` | Todos |
| `PUT` | `/user/profile` | `update_user_profile` | Todos |
| `DELETE` | `/user` | `delete_user` | Todos |
| `POST` | `/admin/users` | `create_admin_user` | SUPERADMIN |

---

## Infraestructura en Tiempo Real (WebSockets)

### Visión General

Cuando un Admin registra un evento de fútbol, el sistema no solo actualiza la base de datos sino que propaga el cambio en tiempo real a todos los aficionados que en ese momento tienen abierta la pantalla de detalle de ese partido. El canal de transmisión es un WebSocket persistente gestionado por API Gateway v2.

---

### Flujo de Broadcast

1. **Admin registra un evento** - realiza una solicitud `POST /admin/matches/{id}/soccer-events` autenticada con JWT de Cognito.

2. **Lambda `post_soccer_event`** - valida el rol del usuario consultando `app_users WHERE id = cognito_sub` (el JWT no contiene `custom:role`; el rol solo vive en la base de datos). Una vez confirmado el acceso, inserta el evento en la tabla `soccer_event` y actualiza el marcador en la tabla `match`. La operación se realiza dentro de una única transacción.

3. **Publicación en SNS** - tras confirmar la transacción, `post_soccer_event` publica un mensaje en el topic `icesi-score-ws-broadcast`. La publicación es *fire-and-forget*: si falla, el error se registra en los logs pero la respuesta HTTP al Admin ya fue enviada con código `201`.

4. **SNS invoca `ws_broadcaster`** - SNS entrega el mensaje de forma asíncrona a la Lambda `icesi-score-ws-broadcaster` mediante una suscripción de tipo `lambda`.

5. **`ws_broadcaster` consulta DynamoDB** - hace un `Scan` sobre la tabla `icesi-score-ws-connections` filtrando por el `match_id` del evento para obtener todos los `connectionId` activos de ese partido.

6. **Envío por WebSocket** - para cada `connectionId`, `ws_broadcaster` llama a `postToConnection` de la API Gateway Management API, enviando un mensaje con la siguiente estructura:

   ```json
   {
     "type": "SOCCER_EVENT",
     "event": { ... },
     "newScore": { "homeScore": 1, "awayScore": 0 }
   }
   ```

   Si `postToConnection` retorna `GoneException` (conexión muerta), `ws_broadcaster` elimina automáticamente ese registro de DynamoDB.

7. **Flutter actualiza la UI** - la pantalla del aficionado recibe el mensaje por el canal WebSocket y actualiza la línea de tiempo y el marcador sin necesidad de pull-to-refresh.

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

1. **Los mensajes `SOCCER_EVENT` y `VOLLEYBALL_EVENT` recibidos en LiveMode generan una petición HTTP adicional.** `LiveModeScreen` (fútbol) y `VolleyballLiveModeScreen` (voleibol) abren una conexión WebSocket autenticada al mismo partido. Cuando el Admin A registra un gol, tarjeta, punto u otro evento de juego, el Admin B lo recibe vía WebSocket y dispara automáticamente un `GET` a la API para refrescar la lista de eventos. Esto implica una petición HTTP por cada evento de juego registrado por el otro Admin mientras ambos tienen el partido abierto simultáneamente. Los mensajes `CLOCK_UPDATE` (inicio/fin de período, fin de partido) son la excepción: se procesan directamente en el BLoC sin ninguna llamada HTTP. Para el volumen de uso del MVP y el free tier de Lambda, el coste adicional de los eventos de juego es aceptable.

2. **El marcador del aficionado solo se actualiza en tiempo real mientras la pantalla está abierta.** Al reabrir la pantalla de detalle, el marcador se toma del objeto `Match` del feed. Si el feed no se ha recargado, el marcador puede estar desactualizado hasta el próximo pull-to-refresh o recarga automática.

3. **La RDS es públicamente accesible por diseño de desarrollo (free tier).** En un entorno de producción se recomienda: RDS privada en VPC, NAT Gateway o VPC Endpoints para las Lambdas que lo requieran, y remover el ingress `0.0.0.0/0` del security group de la base de datos.

4. **El aficionado no ve la transición SCHEDULED → IN_PROGRESS en tiempo real si ya tenía la pantalla abierta.** El WebSocket del `MatchDetailScreen` solo se conecta cuando el partido llega con estado `IN_PROGRESS`. Si el aficionado abrió la pantalla mientras el partido estaba `SCHEDULED` y el Admin inicia el primer tiempo después, el aficionado no recibirá el mensaje `CLOCK_UPDATE START`. Debe hacer pull-to-refresh para ver el partido en vivo. Esto es un compromiso conocido del MVP para evitar conexiones WebSocket en partidos no iniciados.

5. **El inicio de un set de voleibol no se propaga en tiempo real.** El Lambda `post_volleyball_set` publica un mensaje `SET_STARTED` en SNS, pero ningún cliente Flutter lo consume: tanto `VolleyballLiveModeScreen` (Admin B) como `VolleyballDetailScreen` (aficionado) solo procesan mensajes de tipo `VOLLEYBALL_EVENT`. Si el Admin A inicia un set, el Admin B y los aficionados no verán el nuevo set en pantalla hasta que se registre el primer evento de ese set (punto, ace, etc.), momento en que el refresh completo de datos sincroniza el estado. Como mitigación, el Admin B puede hacer pull-to-refresh manualmente.

---

## Sprint 2 - Gestión y Visualización de Partidos

### Contexto

Sprint 2 introduce las dos funcionalidades centrales de la plataforma: la creación de partidos por parte de los Admins y el feed de partidos visible para todos los usuarios autenticados.

---

### Flujo 1 - Creación de Partido (US-08)

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

**Alineación inicial automática.** Dentro de la misma transacción de la inserción del partido, el Lambda `create_match` consulta todos los jugadores de cada equipo y genera automáticamente la alineación inicial usando un algoritmo greedy de asignación por posición. Para fútbol, los primeros 11 jugadores se asignan como `STARTER` en la formación 1-4-4-2 (portero → defensas → mediocampistas → delanteros) según su `standard_position`; el resto pasa a `ON_BENCH`. Para voleibol, los 6 primeros jugadores se asignan como `STARTER` en las posiciones de rotación 1 a 6 (`SETTER`, `OUTSIDE`, `MIDDLE`); el resto a `ON_BENCH`. Si la inserción de cualquier fila de alineación falla, toda la transacción se revierte incluyendo el partido. Gracias a esto, el Admin puede abrir el Modo Live inmediatamente después de crear el partido y encontrar a los jugadores ya posicionados en el campo o la cancha.

---

### Flujo 2 - Feed de Partidos (US-05)

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
   - **Usuario Regular** - pantalla de detalle del partido (fútbol) o pantalla de detalle de voleibol.
   - **Admin** - Modo Live de fútbol o Modo Live de voleibol según el deporte del partido.

---

### Flujo 3 - Modo Live (US-06 / US-11)

El Modo Live es la pantalla exclusiva para el rol **Admin** que permite registrar eventos de partido en tiempo real directamente sobre la alineación visual. El Admin accede desde el Dashboard al tocar la tarjeta de un partido con estado `IN_PROGRESS`.

La pantalla está dividida en tres bloques: el marcador con el período activo en curso, el campo interactivo con los once jugadores de cada equipo posicionados según la formación 1-4-4-2, y la banca con los suplentes de ambos equipos. Al tocar cualquier jugador, ya sea en el campo o en la banca, se despliega un menú inferior con los eventos disponibles para ese jugador.

---

#### Campo interactivo - correcciones de formación y flujo

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

**Gol** - permite vincular opcionalmente una asistencia seleccionando otro jugador del mismo equipo en campo. Si se activa el toggle de asistencia, el desplegable de jugadores se vuelve obligatorio. Al confirmar, el evento de gol y el de asistencia se registran en la misma llamada.

**Asistencia independiente** - permite vincular la asistencia a un gol existente del partido que aún no tenga asistencia registrada, seleccionándolo desde un desplegable con el minuto y el nombre del goleador.

**Tarjeta Amarilla / Tarjeta Roja** - muestra únicamente el campo de minuto. La tarjeta roja incluye un aviso de que el jugador será marcado como expulsado en la base de datos.

**Sustitución** - muestra el jugador fijo como referencia (el que sale si se inició desde el campo; el que entra si se inició desde la banca) y un desplegable obligatorio para seleccionar al otro participante. El cuerpo enviado al backend siempre usa `mainPlayerId` para el jugador que abandona el campo y `secondaryPlayerId` para el que ingresa, independientemente de desde qué lado se inició la acción.

**Nota** - campo de texto libre de hasta 200 caracteres con el minuto de referencia.

Al confirmar cualquier evento, el BLoC emite un estado de éxito, muestra un snackbar informativo y recarga la lista de eventos del partido desde la API.

---

### Flujo 4 - Detalle de Partido - Fútbol (US-06)

Accesible para el rol **Usuario Regular** al tocar cualquier tarjeta de partido de fútbol en el feed. Los Admins acceden al Modo Live en su lugar.

La pantalla abre con un encabezado cuyo contenido central varía según el estado del partido. Para `SCHEDULED`, el centro muestra la fecha y la hora programada. Para `IN_PROGRESS`, aparece el badge `LIVE`, el marcador en naranja y un reloj corriendo en formato `MM:SS` que se actualiza cada segundo mediante un `Timer` local. El reloj calcula el tiempo transcurrido comparando el instante actual con el campo `start_time` del período activo; no hay ninguna consulta al servidor en cada tick. Para `FINISHED`, el centro muestra el marcador final en blanco con la etiqueta "Final".

La sección principal es la línea de tiempo de eventos, ordenada de más reciente a más antigua. Cada tarjeta es expandible al tocarla: los goles revelan el nombre del goleador y la asistencia si la hay; las sustituciones muestran una flecha roja hacia abajo con el jugador saliente y una flecha verde hacia arriba con el jugador entrante; las segundas tarjetas amarillas incluyen el texto "(Expulsado)" junto a un indicador rojo en el historial. Para partidos `SCHEDULED`, la línea de tiempo se reemplaza por el mensaje "El partido aún no ha comenzado."

Cuando el partido está `IN_PROGRESS`, la pantalla abre una conexión WebSocket al inicializarse. Los eventos que llegan por el canal se incorporan al inicio de la lista y el marcador se actualiza sin necesidad de pull-to-refresh. Al salir de la pantalla, la conexión se cierra y el feed de partidos se recarga automáticamente.

---

### Flujo 5 - Detalle de Partido - Voleibol (US-07)

Accesible para el rol **Usuario Regular** al tocar una tarjeta de partido de voleibol en el feed.

El encabezado muestra los sets ganados por cada equipo. Para `SCHEDULED`, el centro presenta la hora programada. Para `IN_PROGRESS` y `FINISHED`, el marcador de sets aparece en amarillo con la etiqueta "Sets".

Debajo del encabezado, si existe un set activo, aparece el bloque de **puntaje del set en curso**: el tanteo del set (`homeScore - awayScore`) en amarillo a 36 puntos, con el número de set en gris. Este bloque está ausente en partidos `SCHEDULED`.

Le sigue la tarjeta de **Set Scores**, que lista todos los sets jugados. El set activo tiene un fondo más cálido, un borde amarillo y el badge `LIVE`; los sets cerrados usan el estilo estándar con los colores de cada equipo. Si no hay sets registrados aún, la tarjeta muestra un mensaje informativo.

La línea de tiempo de eventos usa tarjetas expandibles. Cada tarjeta muestra a la izquierda el marcador en el momento del evento (`score_moment`), el emoji representativo del tipo y la descripción. Los tipos posibles son: Punto, Ace de Servicio, Bloqueo, Falta de Rotación, Sustitución y Nota. Al expandir una tarjeta, se muestra el nombre del jugador involucrado cuando está disponible.

Cuando el partido está `IN_PROGRESS`, la pantalla se conecta al WebSocket. A diferencia de fútbol, los eventos de voleibol no se incorporan incrementalmente: al recibir un mensaje de tipo `VOLLEYBALL_EVENT`, la pantalla dispara una recarga completa de sets y eventos desde la API.

---

### Flujo 6 - Edición y Eliminación de Partidos (US-09, US-10)

Solo disponible para el rol **Admin**. Ambas acciones están restringidas a partidos en estado `SCHEDULED`; la API rechaza cualquier intento sobre partidos `IN_PROGRESS` o `FINISHED`.

El feed del Admin muestra las mismas tarjetas que el usuario regular, pero con soporte de swipe. Al deslizar una tarjeta hacia la izquierda emerge un panel con dos botones: **Editar** y **Eliminar**. Si el partido no está en estado `SCHEDULED`, los botones aparecen en gris y no responden a toques. Deslizar la tarjeta hacia la derecha o tocarla cierra el panel sin disparar ninguna acción.

**Editar partido** - Al tocar Editar sobre un partido `SCHEDULED`, la app navega al formulario de creación pre-cargado con todos los campos actuales: deporte, equipo local, visitante, liga, fecha, hora, sede y notas. El formulario es idéntico al de creación; al confirmar se envía `PUT /admin/matches/{id}`. Al completarse con éxito, la app regresa al dashboard y muestra un snackbar de confirmación.

**Eliminar partido** - Al tocar Eliminar aparece un diálogo de confirmación. Si el Admin confirma, la app envía `DELETE /admin/matches/{id}`. Al retornar al feed, el partido ya no aparece en la lista. Si el partido cambió de estado entre el swipe y la confirmación, la API devuelve un error que se muestra en pantalla.

En ambos casos, al regresar al dashboard el feed se recarga automáticamente para reflejar los cambios.

---

### Referencia de Endpoints REST - Sprint 2

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

## Sprint 3 - Modo Live Completo: Reloj, Campo y Voleibol

### Contexto

Sprint 3 completa el ciclo de vida de un partido en tiempo real para ambos deportes. Para fútbol se incorpora la máquina de estados del reloj (primer tiempo, descanso, segundo tiempo, finalizado) y se consolidan las correcciones pendientes del campo interactivo. Para voleibol se introduce la gestión de sets con cierre automático por puntuación y la cancha interactiva con rotaciones, registro de eventos y sincronización incremental vía WebSocket.

---

### Flujo 1 - Reloj del Partido (US-15)

El Admin controla el ciclo temporal del partido desde el `LiveModeScreen` mediante un único botón con cuatro estados secuenciales: **Iniciar 1er Tiempo → Finalizar 1er Tiempo → Iniciar 2do Tiempo → Finalizar Partido**. No es posible saltarse ningún estado ni retroceder.

**Iniciar un período.** Al tocar el botón de inicio, la app envía `POST /admin/match-periods` con el `matchId` y el `periodLabel` (`1T` o `2T`). El Lambda `post_match_period` inserta una fila en `match_period` con `start_time = NOW()` y rechaza la solicitud con código `409` si ya hay otro período activo. Si el partido estaba en `SCHEDULED`, el status pasa automáticamente a `IN_PROGRESS` en la misma transacción. Tras confirmar, el Lambda publica en SNS un mensaje de tipo `CLOCK_UPDATE` con `action: START`, el `periodLabel`, el `startTime` y el `periodId`.

**Reloj en pantalla.** Tanto el Admin como el aficionado calculan el tiempo transcurrido de forma puramente local: al recibir el `startTime` del período activo, arrancan un `Timer` que recalcula `MM:SS` cada segundo comparando `DateTime.now()` contra ese instante. No hay ningún polling al servidor en cada tick. En la pantalla del aficionado, el encabezado muestra la etiqueta del período junto al reloj corriendo (por ejemplo, `1T · 23:45`). Entre períodos, cuando no hay período activo pero el partido aún no ha finalizado, el encabezado muestra `Descanso`.

**Finalizar un período.** Al tocar el botón mientras el primer tiempo está activo, la app envía `PUT /admin/match-periods/{id}` con el `periodId` del período activo. El Lambda `put_match_period` escribe `end_time = NOW()` en la fila correspondiente de `match_period` y publica en SNS el mensaje `CLOCK_UPDATE` con `action: END` y el `periodLabel` del período cerrado. El partido no cambia de status: sigue `IN_PROGRESS`. Desde ese momento el botón muestra el estado **Descanso** hasta que el Admin inicia el segundo tiempo.

**Finalizar el partido.** Al tocar el botón mientras el segundo tiempo está activo, la app envía `PATCH /admin/matches/{id}/finish`. El Lambda `patch_match_finish` cierra el período activo escribiendo `end_time = NOW()` y actualiza el status del partido a `FINISHED` en una única transacción. A continuación publica en SNS el mensaje `CLOCK_UPDATE` con `action: FINISHED`. Desde ese momento la pantalla del Admin bloquea el campo interactivo con `IgnorePointer` y muestra el banner de partido finalizado.

**Sincronización con el aficionado.** Al recibir un mensaje `CLOCK_UPDATE` por WebSocket, la pantalla del aficionado actualiza el layout en tiempo real sin pull-to-refresh: cuando `action` es `START`, monta el `RunningClock` con el `startTime` recibido y cambia la etiqueta del período; cuando `action` es `FINISHED`, desmonta el reloj y muestra el marcador final.

**Sincronización entre Admins.** Si un segundo Admin tiene el mismo partido abierto simultáneamente, también recibe los mensajes `CLOCK_UPDATE` por su propia conexión WebSocket. El `LiveModeBloc` los procesa directamente en el estado sin llamada HTTP adicional: `action: START` construye un nuevo `MatchPeriod` con `startTime = DateTime.now()` y actualiza el botón al estado siguiente; `action: END` mueve el período activo a `closedPeriodLabels` y limpia `activePeriod`; `action: FINISH` actualiza `match.status` a `FINISHED` y bloquea la pantalla. De este modo el botón de reloj del Admin B siempre refleja el estado real del partido sin necesidad de recargar.

**Conexión WebSocket del Admin (fútbol).** `LiveModeScreen` abre una conexión WSS autenticada en cuanto se inicializa la pantalla, independientemente del estado del partido (`SCHEDULED` o `IN_PROGRESS`). La conexión incluye el `idToken` de Cognito y el `match_id` como parámetros de query, igual que la pantalla del aficionado. Solo se procesan los mensajes de tipo `SOCCER_EVENT` y `CLOCK_UPDATE`; el resto se descarta. La conexión se cierra al salir de la pantalla.

**Ordenamiento de eventos.** Los eventos de ambos períodos se consultan con `ORDER BY created_at DESC`, lo que garantiza que los eventos registrados en el segundo tiempo aparezcan siempre encima de los del primero en la línea de tiempo, independientemente del minuto registrado manualmente.

---

### Flujo 2 - Campo Interactivo (US-11, correcciones Sprint 3)

Sprint 3 consolida una serie de correcciones en el `FootballFieldWidget` y en los flujos de registro del `LiveModeScreen`.

**Formación y posicionamiento.** La formación 1-4-4-2 es fija para ambos equipos. Los jugadores locales se posicionan en la mitad inferior del campo y los visitantes en la superior. Cada línea (portero, defensas, mediocampistas y delanteros) tiene un desplazamiento vertical fijo del 11 % de la altura total; ningún delantero alcanza la línea de mediocampo y no existe solapamiento visual entre jugadores de distintos equipos.

**Jugadores expulsados.** Cuando el status de un jugador cambia a `EXPELLED`, su burbuja pasa a color gris y muestra un indicador rojo en la esquina superior derecha. El jugador permanece visible en su posición del campo, pero un `IgnorePointer` envuelve su burbuja para impedir que el Admin le registre eventos adicionales. El mismo comportamiento aplica en la sección de banca.

**Tarjetas amarillas.** Al registrar una tarjeta amarilla, el BLoC actualiza la lista de eventos en memoria y aparece de inmediato un indicador amarillo en la burbuja del jugador. Si ese mismo jugador acumula dos tarjetas amarillas, el indicador pasa a rojo y la burbuja se torna gris, replicando visualmente el estado de expulsado. Este cambio es únicamente una indicación local para el Admin; el jugador queda formalmente expulsado en el sistema solo cuando el Admin registra la tarjeta roja correspondiente.

**Herencia de posición en la sustitución.** Al confirmar la sustitución, el jugador entrante ocupa exactamente la misma ranura del campo que tenía el saliente: el BLoC permuta las posiciones directamente en la lista en memoria antes de emitir el nuevo estado, de modo que ningún otro jugador se desplaza y el re-render es inmediato. Si un segundo Admin tiene el partido abierto, también recibe el evento `SOCCER_EVENT` de tipo `SUBSTITUTION` por WebSocket y aplica la misma permuta sobre su lista local; el campo de Admin B se actualiza sin petición HTTP adicional.

**Jugador saliente no puede re-entrar.** La banca distingue entre suplentes originales y jugadores que ya abandonaron el campo. Cuando el Admin toca un suplente que ya fue sustituido, el menú inferior no ofrece la opción de Sustitución; solo aparecen Tarjeta Amarilla, Tarjeta Roja y Nota.

**Recarga automática del feed.** Al regresar desde cualquier pantalla de partido, el feed se recarga automáticamente mediante un `PopScope` que dispara el evento de recarga del BLoC del feed, garantizando que el marcador y el estado del partido sean siempre consistentes sin necesidad de pull-to-refresh manual.

---

### Flujo 3 - Gestión de Sets (US-16)

La gestión de sets es la contraparte en voleibol del reloj de fútbol: controla la apertura y el cierre de cada unidad de juego dentro del partido.

**Iniciar un set.** Mientras no hay un set activo y el partido no ha finalizado, la pantalla del Admin muestra el botón `Iniciar Set N`, donde N es el número de sets ya jugados más uno. Al tocarlo, la app envía `POST /admin/volleyball-sets` con el `matchId`. El Lambda `post_volleyball_set` verifica que el partido sea de voleibol, que no exista ya un set activo, y que ningún equipo haya alcanzado aún los 3 sets ganados. Luego inserta la fila en `volleyball_set` con `current_home_score = 0`, `current_away_score = 0` y `start_time = NOW()`. Si el partido estaba en `SCHEDULED`, pasa a `IN_PROGRESS` en la misma transacción. Tras confirmar, el Lambda publica en SNS un mensaje de tipo `SET_STARTED` con el `setId`, `setNumber` y `startTime`.

**Cierre automático del set.** El cierre no se inicia desde Flutter: ocurre dentro del Lambda `post_volleyball_event` cada vez que se registra un punto. Tras actualizar el marcador del set, el Lambda evalúa la condición de victoria: 25 puntos con ventaja de al menos 2 tantos para los sets 1 al 4, o 15 puntos con ventaja de al menos 2 para el 5to set. Si se cumple, el Lambda escribe `end_time = NOW()` en `volleyball_set`, incrementa `home_score` o `away_score` del partido, y evalúa si algún equipo llegó a 3 sets ganados. Si es así, el partido pasa a `FINISHED` de forma automática. Toda esta secuencia ocurre en una única transacción de base de datos; Flutter nunca toma esta decisión.

**Marcador global de sets.** El encabezado de la pantalla del Admin y la del aficionado muestran los sets ganados por cada equipo en todo momento. En la pantalla del aficionado, el marcador se actualiza en tiempo real a través del WebSocket: los mensajes `VOLLEYBALL_EVENT` con `setComplete: true` o `matchFinished: true` llevan el campo `matchScore` con los contadores actualizados, y el BLoC parchea el objeto `_currentMatch` antes de disparar el refresh completo de datos.

---

### Flujo 4 - Cancha Interactiva (US-17/US-18)

La cancha interactiva de voleibol sigue la misma filosofía visual que el campo de fútbol, adaptada a la mecánica de posiciones y rotaciones del deporte.

**Posicionamiento.** Cada equipo mantiene 6 jugadores con status `ON_FIELD` o `STARTER` distribuidos en las posiciones 1 a 6 según la rotación estándar. Cada posición numérica se mapea a coordenadas fraccionarias fijas dentro de la mitad de cancha correspondiente; por convención, la posición 1 ocupa la esquina trasera derecha. La burbuja de cada jugador muestra el número de camiseta dentro de un `CircleAvatar` coloreado según el equipo, y un badge naranja en la esquina superior derecha con el número de posición actual.

**Rotación.** La pantalla tiene dos botones de rotación, uno para el equipo local y otro para el visitante. Al tocar uno, la app envía `POST /admin/matches/{id}/rotate-team` con el `teamId`. El Lambda `post_rotate_team` ejecuta un `UPDATE` sobre `match_lineup` con una expresión `CASE` que desplaza todas las posiciones en sentido horario: `1→6, 2→1, 3→2, 4→3, 5→4, 6→5`. La respuesta incluye la nueva asignación de posiciones, y el BLoC actualiza la alineación en memoria para que el re-render de la cancha sea inmediato. El broadcast de rotación no se propaga por WebSocket porque el posicionamiento en cancha es información exclusiva del Admin.

**Registro de eventos.** Al tocar un jugador en cancha o en la banca, aparece un panel inferior con los eventos disponibles. `POINT`, `SERVICE_ACE` y `BLOCK` suman un punto al marcador del set del equipo del jugador. `ROTATION_FAULT` suma el punto al equipo contrario. La sustitución actualiza los status en `match_lineup` y el jugador entrante hereda el `position_coordinate` del saliente. El evento `NOTE` permite registrar una anotación libre que queda almacenada en base de datos y es visible para el aficionado al expandir la tarjeta en la línea de tiempo. Si un segundo Admin tiene el partido abierto, los mensajes `VOLLEYBALL_EVENT` de tipo `SUBSTITUTION` recibidos por WebSocket aplican la misma herencia de coordenada sobre la alineación local de Admin B, actualizando la cancha sin petición HTTP adicional.

**Jugador sustituido no puede re-entrar.** La banca distingue entre suplentes originales (sin `position_coordinate`) y jugadores que ya salieron del campo (con `position_coordinate` heredada). Cuando el Admin toca un suplente que ya fue sustituido, el menú inferior solo ofrece `NOTE`; las opciones de sustitución no aparecen.

**Conexión WebSocket del Admin (voleibol).** `VolleyballLiveModeScreen` abre una conexión WSS autenticada únicamente cuando el partido llega con estado `IN_PROGRESS`. A diferencia de la pantalla de fútbol, no conecta para partidos `SCHEDULED`. Solo procesa mensajes de tipo `VOLLEYBALL_EVENT`; los mensajes `SET_STARTED` son recibidos por el servidor pero descartados en el cliente (ver Limitaciones Conocidas del MVP). La conexión se cierra al salir de la pantalla.

**Sincronización incremental con el aficionado.** Cada evento de voleibol publica un mensaje `VOLLEYBALL_EVENT` en SNS hacia `ws_broadcaster`. En la pantalla del aficionado, si el set continúa activo, el BLoC actualiza de forma incremental el marcador del set activo y antepone el nuevo evento a la lista sin recargar toda la pantalla. Cuando el set termina (`setComplete: true`) o el partido finaliza (`matchFinished: true`), el BLoC parchea el marcador de sets del encabezado y dispara un refresh completo desde la API para obtener el estado actualizado de todos los sets.

---

### Flujo 5 - Mejoras del Feed (Usuario Regular)

Las siguientes mejoras aplican exclusivamente a la pantalla **Home** del Usuario Regular. El Dashboard del Admin no incluye búsqueda ni chips de filtro.

**Búsqueda en tiempo real.** La barra de búsqueda integrada en la parte superior de la pantalla Home permite filtrar los partidos por nombre del equipo local, nombre del equipo visitante o nombre de la liga. El filtro opera sobre la lista en memoria sin realizar ninguna petición adicional al servidor; el `MatchFeedBloc` aplica el predicado sobre `_allMatches` cada vez que el texto cambia.

**Chips de filtro por estado.** Debajo del selector de deporte, una fila de chips deslizable en horizontal permite acotar los partidos por su estado:

| Chip | Estado filtrado |
|------|----------------|
| Todos | sin filtro (muestra todos) |
| En vivo | `IN_PROGRESS` |
| Programados | `SCHEDULED` |
| Terminados | `FINISHED` |

El chip activo aparece con fondo azul. Los filtros de búsqueda y estado se combinan: un partido es visible solo si satisface ambos predicados al mismo tiempo.

**Fecha completa en partidos programados.** La etiqueta superior de cada tarjeta de partido (`eyebrow label`) muestra la fecha y la hora para partidos con estado `SCHEDULED` en el formato `"DD Mes - HH:MM"` (por ejemplo, `"24 May - 16:00"`). Los partidos en curso muestran `LIVE` y los finalizados muestran `Terminado`.

**Estado vacío.** Cuando no hay partidos que cumplan los filtros activos o la API no devuelve resultados, el feed muestra un icono `event_busy` y un mensaje informativo en lugar de una lista vacía, manteniendo el `RefreshIndicator` activo para que el pull-to-refresh siga funcionando.

---

### Flujo 6 - Botones Destructivos en el Reloj (Admin)

Los botones de control del reloj en `LiveModeScreen` usan estilos de color diferenciados según el tipo de acción:

| Botón | Color |
|-------|-------|
| Iniciar 1er Tiempo | Morado (color primario) |
| Finalizar 1er Tiempo | Rojo `#EB5757` |
| Iniciar 2do Tiempo | Morado (color primario) |
| Finalizar Partido | Rojo `#EB5757` |

Los botones de inicio representan acciones reversibles (se puede terminar el período después), mientras que los botones de finalización son irreversibles y quedan marcados en rojo para que el Admin identifique visualmente el riesgo antes de tocar. Un botón deshabilitado (cuando no corresponde la acción en el estado actual) aparece en gris independientemente de su tipo.

---

### Decisiones de Infraestructura Sprint 3

Los Lambdas de escritura incorporados en este sprint (`post_match_period`, `put_match_period`, `patch_match_finish`, `post_volleyball_set`, `post_volleyball_event` y `post_rotate_team`) siguen el mismo patrón que `post_soccer_event` del Sprint 2: corren fuera de la VPC para poder alcanzar SNS sin necesidad de un NAT Gateway ni VPC Endpoints. La RDS sigue siendo accesible mediante credenciales y `sslmode=require`, por lo que sacar las funciones de la VPC no modifica el nivel de seguridad de la base de datos.

`post_rotate_team` es el único Lambda de escritura de voleibol que no publica en SNS. La rotación de posiciones es una operación exclusiva del Admin y los aficionados no reciben ni muestran las posiciones de los jugadores, de modo que no existe un receptor WebSocket para ese evento.

La lógica de cierre de set y de fin de partido vive íntegramente en `post_volleyball_event`. Flutter nunca evalúa si un set debe cerrarse ni si el partido debe terminar: solo recibe la señal a través del campo `setComplete` o `matchFinished` de la respuesta HTTP (Admin) o del mensaje WebSocket (aficionado) y reacciona en consecuencia. Esta decisión evita condiciones de carrera entre clientes y garantiza que el estado persistido en la base de datos sea siempre la fuente de verdad.

---

### Referencia de Endpoints REST - Sprint 3

Todos los endpoints requieren JWT de Cognito en el encabezado `Authorization`. Los endpoints bajo `/admin/` validan el rol consultando `app_users` en PostgreSQL.

| Método | Ruta | Lambda | Acceso |
|--------|------|--------|--------|
| `POST` | `/admin/match-periods` | `post_match_period` | ADMIN, SUPERADMIN |
| `PUT` | `/admin/match-periods/{id}` | `put_match_period` | ADMIN, SUPERADMIN |
| `PATCH` | `/admin/matches/{id}/finish` | `patch_match_finish` | ADMIN, SUPERADMIN |
| `POST` | `/admin/volleyball-sets` | `post_volleyball_set` | ADMIN, SUPERADMIN |
| `POST` | `/admin/volleyball-events` | `post_volleyball_event` | ADMIN, SUPERADMIN |
| `POST` | `/admin/matches/{id}/rotate-team` | `post_rotate_team` | ADMIN, SUPERADMIN |

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
- `CognitoAuthDataSource` - autenticación vía Amplify SDK (AWS Cognito)
- `SecureStorageDataSource` - persistencia de sesión local con `flutter_secure_storage`
- `UserProfileApiDataSource` - perfil de usuario vía HTTP al API Gateway

Cada datasource concreto implementa su respectiva interfaz abstracta (`RemoteAuthDataSource`, `LocalAuthDataSource`, `UserProfileDataSource`), aplicando inversión de dependencias en toda la cadena.

### Capa de Presentación (BLoC)

Cada pantalla tiene su BLoC. El BLoC recibe eventos de la UI, llama al use case correspondiente y emite estados. Nunca instancia repositorios ni datasources directamente.

`LoginScreen` no sabe que existe Cognito. Solo sabe que hay un `LoginBloc` disponible en el árbol de widgets.

### Inyección de Dependencias (GetIt)

El ensamblado de dependencias está centralizado en `lib/injection_container.dart` usando **GetIt**. Este archivo expone la variable global `sl` (`GetIt.instance`) y la función `initDependencies()`, que se llama en `main()` antes de `runApp()`.

Las dependencias se registran en orden de capas, de adentro hacia afuera:

```
DataSources → Repositories → UseCases → BLoCs/Cubits
```

**Reglas de registro:**

| Tipo | Método GetIt | Motivo |
|------|-------------|--------|
| Data sources, repositories, use cases | `registerLazySingleton` | Se crean una sola vez; la instancia se comparte |
| BLoCs y Cubits | `registerFactory` | Cada pantalla recibe una instancia nueva con estado propio |
| `SessionCubit` | `registerLazySingleton` | Singleton de sesión compartido a lo largo de toda la app |

**Inversión de dependencias respetada:** cada tipo se registra bajo su abstracción, no bajo su implementación concreta:

```dart
sl.registerLazySingleton<AuthRepository>(
  () => AuthRepositoryImpl(sl<RemoteAuthDataSource>(), ...),
);
```

De este modo los use cases reciben `AuthRepository` (el contrato del dominio), nunca `AuthRepositoryImpl`.

**`CognitoAuthDataSource` es lazy:** su constructor no toca Amplify. La primera vez que se accede es dentro de `_initApp()`, después de que `Amplify.configure()` ya completó, por lo que el orden de inicialización está garantizado.

**`SessionCubit` es singleton en GetIt y BlocProvider:** GetIt posee la instancia; `BlocProvider` la expone al árbol de widgets con `create: (_) => sl<SessionCubit>()`, de forma que `context.read<SessionCubit>()` sigue funcionando en todas las pantallas.

En `main.dart`, cada ruta simplemente pide su BLoC al contenedor:

```dart
'/login': (_) => BlocProvider<LoginBloc>(
  create: (_) => sl<LoginBloc>(),
  child: const LoginScreen(),
),
```

Los BLoCs no cambian internamente: siguen recibiendo sus dependencias por constructor, sin saber si las construyó `main.dart` o GetIt.

### Reglas de Desarrollo

1. **Uso obligatorio de `Key`:** Todos los widgets deben inicializarse con un `key` (ej. `super.key` en el constructor) para evitar ciclos de re-renderizado innecesarios en Flutter.

2. **StatefulWidgets:**
   * Limitados **exclusivamente** a las pantallas completas (Screens/Pages).
   * Se ubican en `lib/features/<feature>/ui/screens/`.
   * No contienen lógica de negocio - delegan al BLoC correspondiente.

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
| `make db-up DB_PASSWORD=X` | `terraform apply` - levanta RDS y despliega Lambdas |
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
