# Tareas de Contribucion - Equipo IcesiScore

Cada tarea mejora algo concreto del MVP y puede completarse en pocos commits.

> **Importante:** El archivo `lib/amplifyconfiguration.dart` esta en el `.gitignore` y no esta incluido en el repositorio. Este archivo contiene las credenciales de AWS Cognito y API Gateway y se genera automaticamente con Terraform al desplegar la infraestructura. Como no tienen un usuario IAM no pueden generarlo ni ejecutar `flutter run`. Para verificar sus cambios usen `flutter analyze` desde la carpeta `icesi_score/`, que compila el proyecto y reporta errores de tipos, imports rotos y violaciones de arquitectura sin necesitar conectarse a ningun servicio. Si no reporta errores, el codigo es correcto. El lider del equipo verificara el comportamiento visual antes de aprobar el PR.

**Flujo de trabajo:**

```bash
git checkout feature/infra-and-ui-sync
git pull origin feature/infra-and-ui-sync
git checkout -b feat/<nombre-de-tu-tarea>
```

El PR debe apuntar a `feature/infra-and-ui-sync`. Describe brevemente en el PR que cambiaste y como verificarlo. No modifiques archivos fuera de los indicados en tu tarea sin consultar primero.

---

La app sigue **Clean Architecture + BLoC**. Las reglas:

| Permitido | Prohibido |
|-----------|-----------|
| Los widgets reciben datos y callbacks como parametros | Un widget llama `context.read<AlgunBloc>()` dentro de logica propia |
| El BLoC filtra, transforma y decide | El widget hace `.where(...)` directamente sobre la lista de matches |
| La pantalla (`Screen`) solo despacha eventos y consume estados | La pantalla instancia repositorios o datasources |
| Un widget reutilizable vive en `lib/widgets/` | Logica de negocio dentro de un `StatelessWidget` |

Los `StatelessWidget` solo renderizan. Los `Screen` (`StatefulWidget`) despachan eventos al BLoC y consumen estados. El BLoC solo usa UseCases del dominio.

---

## TAREA 1 - Pantalla de Bienvenida: ajustar layout de botones

**Rama:** `feat/welcome-screen-layout`
**Archivo:** `lib/features/login/ui/screens/welcome_screen.dart`
**Capa:** UI, ningun BLoC ni dominio involucrado

### Contexto

La pantalla de bienvenida tiene el logo/texto en el centro y los dos botones ("Iniciar Sesion" y "Registrarse") pegados al fondo. Los dos `Spacer()` distribuyen el espacio en partes iguales, lo que deja los botones muy abajo en pantallas altas. Ademas, el `ElevatedButton` de "Iniciar Sesion" no tiene `style` explicito y no respeta el tema visual.

### Que hacer

1. **Ajusta los `Spacer()` para que los botones queden en el tercio inferior, no al fondo.** El `Spacer` tiene un parametro opcional `flex:` que controla que proporcion del espacio disponible consume. Si el primer `Spacer` tiene `flex: 1` y el segundo tiene `flex: 3`, el bloque de logo/texto sube hacia el centro-superior y los botones quedan en la zona inferior-media. Experimenta con los valores hasta que se vea equilibrado.

2. **Agrega `style` al `ElevatedButton` de "Iniciar Sesion"** para que tenga ancho completo y altura minima de 55 px, igual que el `OutlinedButton` de "Registrarse" que ya lo tiene. Mira la propiedad `minimumSize` dentro de `ElevatedButton.styleFrom(...)` y replica lo que ya usa el boton de registro.

3. **Agrega un `SizedBox(height: 40)` al final** (despues del boton de Registrarse) para que los botones no queden pegados al borde inferior en telefonos sin notch.

### Como verificar

`flutter run` -> la pantalla de Bienvenida aparece sin necesidad de login. Comprueba en un emulador de pantalla alta que los botones no esten al fondo sino en la zona central-inferior.

---

## TAREA 2 - Feed: mostrar fecha completa en partidos programados

**Rama:** `feat/match-card-full-date`
**Archivo:** `lib/widgets/match/match_feed_list.dart`
**Capa:** Widget de presentacion, sin BLoC ni dominio

### Contexto

La etiqueta que aparece encima de cada tarjeta de partido ("eyebrow label") muestra actualmente:
- `LIVE` si el partido esta en curso
- `Terminado` si finalizo
- Solo la hora (ej. `16:00`) si esta programado

La entidad `Match` ya tiene dos campos de texto: `matchDate` (formato `"2026-05-24"`) y `matchTime` (formato `"16:00"`). Para partidos `SCHEDULED`, el aficionado solo ve la hora pero no sabe el dia.

### Que hacer

En el getter `_eyebrowLabel` de la clase privada `_MatchListItemState`, el caso por defecto devuelve `widget.match.matchTime ?? '--:--'`.

Modifica **solo ese caso** para que, cuando `matchDate` no sea nulo, muestre la fecha y la hora juntas. Por ejemplo: `"24 May - 16:00"`.

- `matchDate` es un `String?` con formato ISO `"YYYY-MM-DD"`. Puedes parsearlo con `DateTime.parse(widget.match.matchDate!)`.
- Dart expone `DateTime.day` y `DateTime.month` (entero 1 a 12). Puedes escribir una funcion privada local o un `switch` para convertir el numero de mes a texto abreviado (`"Ene"`, `"Feb"`, etc.).
- No uses ningun paquete externo. El paquete `intl` no esta en `pubspec.yaml`.
- Si `matchDate` es `null`, muestra solo `matchTime`, igual que antes.

### Como verificar

Con `flutter run` y al menos un partido `SCHEDULED` visible en el feed, la etiqueta sobre la tarjeta debe mostrar la fecha y la hora, no solo la hora.

---

## TAREA 3 - Feed: barra de busqueda funcional

**Rama:** `feat/match-feed-search`
**Archivos a modificar (en este orden):**
1. `lib/features/match/ui/bloc/match_feed_event.dart`
2. `lib/features/match/ui/bloc/match_feed_bloc.dart`
3. `lib/widgets/common/app_top_bar.dart`
4. `lib/features/home/ui/screens/home_screen.dart`

**Capa:** BLoC + Widget

**Nota de coordinacion:** Esta tarea y la TAREA 4 modifican los mismos archivos de BLoC. Coordinense con el compañero de la TAREA 4 para no generar conflictos. Lo ideal es que esta tarea se fusione primero, y quien haga la TAREA 4 haga `git pull` antes de empezar.

### Contexto

La barra de busqueda en `AppTopBar` es un `Container` estatico decorativo sin ningun `TextField`. El `MatchFeedBloc` emite todos los partidos sin filtro. La tarea es conectar ambas partes.

### Que hacer

**Cambios en la capa BLoC (primer commit)**

En `match_feed_event.dart`: agrega un nuevo evento `MatchFeedSearchChangedEvent` con un campo `final String query`. Sigue la misma estructura de `MatchFeedStartedEvent`.

En `match_feed_bloc.dart`:
- Declara un atributo privado `List<Match> _allMatches = []` en la clase `MatchFeedBloc`. Este campo guarda la lista completa sin filtrar.
- En el handler de `MatchFeedStartedEvent`, tras obtener los partidos de la API, asigna el resultado a `_allMatches` antes de hacer `emit`.
- Registra un nuevo handler para `MatchFeedSearchChangedEvent`. Dentro del handler: filtra `_allMatches` donde el nombre del equipo local, el equipo visitante o el nombre de la liga contengan `event.query` (usa `.toLowerCase()` en ambos lados). Si `query` esta vacia, emite `_allMatches` completo. Emite `MatchFeedLoadedState` con la lista resultante.

**Cambios en la capa UI (segundo commit)**

En `app_top_bar.dart`:
- Agrega un parametro opcional `final ValueChanged<String>? onSearchChanged` al constructor de `AppTopBar`.
- Reemplaza el `Container` estatico (el `Row` con el icono y el texto hardcodeado) por un `TextField` real. El `TextField` debe tener `onChanged: onSearchChanged`, el hint `'Buscar equipos, partidos...'` y decoracion consistente con el estilo actual: `filled: true`, sin borde visible, `prefixIcon: Icon(Icons.search)`.

En `home_screen.dart`:
- El `AppTopBar` ya se instancia alrededor de la linea 90. Pasale `onSearchChanged: (query) { ... }`.
- En el callback, despacha `MatchFeedSearchChangedEvent(query)` a **ambos** BLoCs (`FootballFeedBloc` y `VolleyballFeedBloc`), para que la busqueda actue en los dos tabs.

### Restriccion importante

El filtrado ocurre exclusivamente en el BLoC. La pantalla despacha el evento, el BLoC filtra, la pantalla muestra lo que el BLoC emite. Nunca filtres la lista directamente en un widget o en la pantalla.

### Como verificar

Con `flutter run`, escribe en la barra el nombre parcial de un equipo. La lista debe actualizarse en tiempo real mostrando solo los partidos que coincidan.

---

## TAREA 4 - Feed: filtrar partidos por estado

**Rama:** `feat/match-feed-status-filter`
**Archivos a modificar:**
1. `lib/features/match/ui/bloc/match_feed_event.dart`
2. `lib/features/match/ui/bloc/match_feed_bloc.dart`
3. `lib/features/home/ui/screens/home_screen.dart`

**Capa:** BLoC + Widget

**Nota de coordinacion:** Esta tarea modifica los mismos archivos de BLoC que la TAREA 3. Antes de empezar, haz `git pull origin feature/infra-and-ui-sync` para ver si esa tarea ya fue fusionada. Si lo fue, el campo `_allMatches` ya existe en el BLoC y tu solo necesitas agregar el nuevo evento de filtro. Si no fue fusionada, necesitaras agregarlo tu tambien.

### Contexto

El feed actualmente muestra todos los partidos del deporte seleccionado mezclados: programados, en vivo y terminados. No hay forma de ver solo los partidos en curso o solo los terminados.

### Que hacer

**Cambios en la capa BLoC (primer commit)**

En `match_feed_event.dart`: agrega un evento `MatchFeedStatusFilterChangedEvent` con un campo `final String? status`. Cuando `status` sea `null` significa "Todos".

En `match_feed_bloc.dart`:
- Si `_allMatches` aun no existe (la TAREA 3 no esta fusionada), declaralo y asignalo en el handler de `MatchFeedStartedEvent`, igual que se describe en esa tarea.
- Agrega un atributo privado `String? _activeStatusFilter` inicializado en `null`.
- Registra un handler para `MatchFeedStatusFilterChangedEvent`. Dentro: actualiza `_activeStatusFilter` con `event.status`. Luego aplica el filtro sobre `_allMatches`: si `_activeStatusFilter` es `null`, emite la lista completa; si no, emite solo los partidos cuyo `status` coincida.

**Cambios en la capa UI (segundo commit)**

En `home_screen.dart`, debajo del `SportSelector` y antes del `Expanded` que contiene el `IndexedStack`, agrega una fila de chips de filtro. Los chips deben ser: `Todos`, `En vivo`, `Programados`, `Terminados`. Los valores de `status` a enviar en el evento son: `null`, `'IN_PROGRESS'`, `'SCHEDULED'`, `'FINISHED'`.

Guia de implementacion del widget de chips:
- Usa `_selectedStatus` como variable de estado local (`String? _selectedStatus`), inicializada en `null`.
- Al tocar un chip, actualiza `_selectedStatus` con `setState` y despacha `MatchFeedStatusFilterChangedEvent(_selectedStatus)` a **ambos** BLoCs.
- Para la apariencia, usa `ChoiceChip` de Material. El chip seleccionado puede tener `selectedColor: AppTheme.primaryColor`. Coloca los chips en un `SingleChildScrollView` horizontal para que no se corten en pantallas pequenas.

### Como verificar

Con `flutter run`, toca el chip "En vivo". El feed debe mostrar solo los partidos con estado `IN_PROGRESS`. Al tocar "Todos", vuelven a aparecer todos.

---

## TAREA 5 - LiveMode: botones de finalizar en rojo

**Rama:** `feat/live-mode-destructive-buttons`
**Archivo:** `lib/features/match/ui/screens/live_mode_screen.dart`
**Capa:** UI, ningun BLoC ni dominio involucrado

### Contexto

El boton de control del reloj en `LiveModeScreen` siempre es morado (`AppTheme.primaryColor`), independientemente de si la accion es "Iniciar 1er Tiempo" (accion segura) o "Finalizar Partido" (accion destructiva e irreversible). Las acciones destructivas deben diferenciarse visualmente.

El boton "Finalizar 1er Tiempo" y el boton "Finalizar Partido" deben mostrarse en rojo `#EB5757`.

### Que hacer

La clase `_ClockButton` (alrededor de la linea 501 del archivo) es un `StatelessWidget` puramente presentacional que recibe `label`, `onPressed` e `isLoading`. La logica del color esta en su metodo `build`, en la propiedad `backgroundColor` del `ElevatedButton.styleFrom`.

1. **Agrega un parametro `bool isDestructive = false`** al constructor de `_ClockButton`. No es `required`, el valor por defecto es `false` para no romper nada.

2. **Modifica `backgroundColor`** en el `build` para que use la logica siguiente:
   - Si `onPressed == null` (boton deshabilitado): color gris, igual que ahora.
   - Si `isDestructive == true`: `const Color(0xFFEB5757)`.
   - En cualquier otro caso: `AppTheme.primaryColor`, igual que ahora.

3. **En `_ClockSection`**, donde se instancia `_ClockButton` (alrededor de la linea 454), pasa `isDestructive: true` cuando el label empieza con `'Finalizar'`. Puedes usar `label.startsWith('Finalizar')` o revisar directamente el estado de `activePeriod` para determinarlo. El metodo `_buttonLabel` ya esta definido en la misma clase y puedes usarlo como referencia para saber cuando el boton es destructivo.

### Como verificar

Con `flutter run`, entra al modo live de un partido en progreso. El boton "Iniciar 1er Tiempo" y el boton "Iniciar 2do Tiempo" deben seguir siendo morados. El boton "Finalizar 1er Tiempo" y el boton "Finalizar Partido" deben ser rojos (`#EB5757`).

---

## TAREA 6 - Feed: empty state con icono

**Rama:** `feat/feed-empty-state`
**Archivo:** `lib/widgets/match/match_feed_list.dart`
**Capa:** Widget de presentacion, sin BLoC ni dominio

### Contexto

Cuando el feed carga correctamente pero no hay partidos disponibles, el widget `MatchFeedList` muestra solo un texto gris centrado: `'No hay partidos disponibles'`. No hay icono ni mensaje secundario que oriente al usuario.

### Que hacer

En el metodo `build` de `MatchFeedList`, localiza el bloque que se ejecuta cuando `matches.isEmpty`. Actualmente construye un `ListView` con un `Text` simple.

Reemplaza el contenido de ese `ListView` por un `Column` centrado que tenga:

1. Un icono grande con `Icons.event_busy` o `Icons.sports_score`, tamano ~72, color `Colors.white24`.
2. Un `SizedBox(height: 16)`.
3. El texto principal `'No hay partidos disponibles'` en color blanco, `fontSize: 16`, `fontWeight: FontWeight.w600`.
4. Un `SizedBox(height: 8)`.
5. Un texto secundario de apoyo, por ejemplo `'Vuelve pronto para ver los proximos partidos'`. Usa `fontSize: 13` y `color: Colors.grey`.

El `Column` debe ir dentro de un `Center` con `mainAxisAlignment: MainAxisAlignment.center`. Mantiene el `ListView` externo con `AlwaysScrollableScrollPhysics` porque es necesario para que el `RefreshIndicator` funcione incluso con lista vacia.

### Como verificar

Esta pantalla es dificil de ver sin datos. Puedes verificarla temporalmente **cambiando en local** la condicion `matches.isEmpty` a `matches.isNotEmpty` (o similar) para forzar el empty state con cualquier lista. Revierte ese cambio antes de hacer commit. El lider del equipo verificara visualmente antes de hacer merge.

---

## TAREA 7 - main.dart: una sola instancia del repositorio de autenticacion

**Rama:** `feat/main-single-auth-repo`
**Archivo:** `lib/main.dart`
**Capa:** Composicion de dependencias (capa de infraestructura, fuera del dominio)

### Contexto

Actualmente `main.dart` crea una nueva instancia de `AuthRepositoryImpl(CognitoAuthDataSource())` en cada ruta de navegacion de forma independiente. En la ruta `/profile` se crean tres instancias distintas del repositorio para los tres BLoCs que se montan ahi (`LogoutBloc`, `ProfileBloc`, `DeleteBloc`). Como Amplify es un singleton global, en la practica esto no causa bugs, pero es un desperdicio de memoria y un antipatron: la composicion de dependencias debe ocurrir una sola vez, no dispersa por todo el archivo.

La solucion mas directa, sin introducir un contenedor de inyeccion de dependencias, es construir una sola instancia del repositorio al inicializar el widget raiz y pasarla a todas las rutas que la necesiten.

### Que hacer

La clase `_App` es un `StatefulWidget` y `_AppState` es su estado. En `_AppState`:

1. **Declara los repositorios compartidos como atributos de la clase**, usando `late final`:

   ```
   late final CognitoAuthDataSource _cognitoSource;
   late final AuthRepositoryImpl _authRepo;
   ```

2. **Inicializalos en `initState`**, antes o despues de `_sessionFuture = _initApp()`. `CognitoAuthDataSource` no recibe parametros; `AuthRepositoryImpl` recibe la fuente de datos. Guarda ambas referencias en los atributos declarados.

3. **Reemplaza todos los `AuthRepositoryImpl(CognitoAuthDataSource())` dispersos en las rutas** por `_authRepo`. Cuenta cuantas ocurrencias hay (son varias: `/login`, `/register`, `/verify`, `/set-password`, `/admin`, `/superadmin`, `/create-admin`, `/profile`) y sustituyelas una a una. El metodo de busqueda `Ctrl+Shift+H` (o `Cmd+Shift+H`) en tu IDE puede ayudarte, pero revisa cada una manualmente para no romper nada.

4. **Para `MatchRepositoryImpl`**: sigue el mismo patron si quieres dar un paso extra. Declara `late final MatchRepositoryImpl _matchRepo` e inicializalo en `initState`. Las rutas `/home`, `/admin`, `/match-detail`, `/volleyball-detail`, `/live-mode`, `/volleyball-live-mode`, `/create-match` y `/create-admin` crean instancias locales; puedes unificarlas de la misma manera.

### Restriccion importante

No toques nada dentro de `domain/`, `data/` ni `features/`. Este cambio es exclusivamente en `main.dart`, que es el **composition root** de la app: el unico lugar que tiene permitido conocer todas las implementaciones concretas. La arquitectura no cambia; solo se consolida donde se construyen las instancias.

### Como verificar

`flutter run`. La app debe arrancar, iniciar sesion, navegar al perfil y cerrar sesion exactamente igual que antes. No debe haber cambio de comportamiento visible; el cambio es estructural. Verifica que no aparecen errores de compilacion ni de ejecucion.
