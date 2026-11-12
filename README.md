# CrowdRadar (Flutter client)

Mobile client for CrowdRadar: live crowd saturation of places, reports,
validation, favorites and an admin moderation area.

## Requirements

- Flutter stable with Dart `^3.11.5` (`pubspec.yaml`); `pubspec.lock` needs
  Flutter `>=3.38.4`. Measured and tested with Flutter 3.41.9 / Dart 3.11.5
  (`docs/metricas-baseline.md`).
- Android emulator or device. For the real backend, run
  `docker compose up` in the backend repo (API on `:3000`).

## Run

```bash
flutter pub get
flutter run --dart-define=API_URL=http://10.0.2.2:3000        # real backend
```

| Define | Default | Meaning |
|---|---|---|
| `API_URL` | `http://10.0.2.2:3000` | Backend base URL (Android emulator host). |

The app always talks to the backend at `API_URL`: there is no in-memory mode.
Cleartext HTTP is allowed in the Android **debug** manifest only.

## Push notifications (Firebase)

HU 8.3 alerts reach the phone through Firebase Cloud Messaging (FCM), Firebase
project `crowdradar-84ff1` (Spark plan, free).

**Setup.** `flutterfire configure --project=crowdradar-84ff1
--platforms=android,ios` generated `lib/firebase_options.dart`,
`android/app/google-services.json`, `firebase.json` and the
`com.google.gms.google-services` Gradle plugin. `google-services.json` and
`firebase_options.dart` hold public client identifiers (API key, app id,
project id), not secrets, so they are committed; run the command again only
when apps are added to the project. The server key (service account) lives
in the backend only, never in this repo.

**How it works.** `ReceptorPushFcm` (`core/push/`) starts Firebase after the
first frame, asks the notification permission (Android 13+) and returns the
FCM token, which `RegistroDispositivo` sends to the backend on sign in and
deletes on sign out (a restored session registers it again on each launch).

- App in background or closed: Android shows the notification; tapping it
  opens the place in its `data.lugarId` (a missing or non-numeric id is
  ignored). Without a session the place opens after the sign in.
- App in foreground: Android posts nothing by itself, so the app posts the
  message to the notification tray (`flutter_local_notifications`, channel
  `alertas_favoritos`; tapping it opens the place in `data.lugarId`, like a
  background notification) and also shows its own notice
  (snack bar with the notification title and body) whose "Ver" action opens
  the place in `data.lugarId` (no action when the id is missing or
  non-numeric), and reloads the in-app inbox at once, so the Favoritos tab
  badge and `AlertasPage` count the new alert. Without a session the notice
  is not shown.
- Firebase never starts in tests: they use `ReceptorPushNulo` or fakes, and
  `ReceptorPushFcm` takes its Firebase calls through `MensajeriaPush`.

**iOS limitation.** iOS is registered in Firebase but has no APNs key: push
notifications on iOS require an APNs key from a paid Apple Developer account;
without it iOS receives no push. The app still runs there (no token, so no
device is registered) and the in-app inbox keeps working.

## App icons

The launcher and notification icons are generated from
`assets/images/crowdradar-logo.png`: run `python assets/icon/generate_icon_sources.py`
(needs Pillow), then `dart run flutter_launcher_icons`. Afterwards revert
`ios/Runner.xcodeproj/project.pbxproj`
(`git checkout -- ios/Runner.xcodeproj/project.pbxproj`): the tool corrupts its
`ASSETCATALOG_*` settings. The Android notification icon is the monochrome
`@drawable/ic_notification`, declared in `AndroidManifest.xml` as the FCM default.

## Tests

```bash
flutter analyze
flutter test
flutter test --coverage && dart run tool/coverage_summary.dart   # coverage/lcov.info -> Markdown tables (total, lib/features, per feature)
```

`test/core/reglas_arquitectura_test.dart` enforces the layering rules below,
including that `lib/` ships no fakes.

Tests need no backend: the in-memory fakes and their seed data live in
`test/fakes/` and a test injects them with
`Dependencias.crear(entorno, sesion, repositorios: const FabricaRepositoriosFake())`.

Performance harness (profile mode, real backend with the bench seed from the
backend's `scripts/bench`; the app uses the default `http://10.0.2.2:3000`):

```bash
flutter drive --profile --no-dds \
  --driver=test_driver/perf_driver.dart \
  --target=integration_test/perf/app_perf_test.dart \
  --dart-define=PERF_ADMIN_PASSWORD=...   # optional: admin scenarios are skipped without it
```

`PERF_USER_EMAIL` / `PERF_USER_PASSWORD` / `PERF_ADMIN_EMAIL` default to the
bench accounts. Results land in `build/perf/` (one JSON per scenario plus a
Markdown table). Baseline numbers: `docs/metricas-baseline.md`.

## Diagramas

PlantUML sources in `docs/diagramas/` with the rendered SVG next to each one
(rendered with the `plantuml/plantuml:1.2024.7` Docker image):

| Diagram | SVG | Source |
|---|---|---|
| Components and layers (composition root, `FabricaRepositorios`, `ApiClient` + interceptors, `MapaAdapter`) | [componentes.svg](docs/diagramas/componentes.svg) | [componentes.puml](docs/diagramas/componentes.puml) |
| Navigation (go_router: main and admin `StatefulShellRoute`s, guards, every path) | [navegacion.svg](docs/diagramas/navegacion.svg) | [navegacion.puml](docs/diagramas/navegacion.puml) |
| Sequence: create a report, validate it, see its validation status (with error branches) | [secuencia-reporte-validacion.svg](docs/diagramas/secuencia-reporte-validacion.svg) | [secuencia-reporte-validacion.puml](docs/diagramas/secuencia-reporte-validacion.puml) |
| Deployment (device, docker compose API + Postgres, OSM tiles + disk cache) | [despliegue.svg](docs/diagramas/despliegue.svg) | [despliegue.puml](docs/diagramas/despliegue.puml) |

Backend diagrams (components, ER, create-report and JWT-login sequences,
deployment) live in the backend repository under `docs/diagramas/`.

Re-render (Git Bash):

```bash
MSYS_NO_PATHCONV=1 docker run --rm -v "$(pwd -W)/docs/diagramas:/data" \
  plantuml/plantuml:1.2024.7 -tsvg /data/*.puml
```

## Folder tree

```
lib/
  main.dart            bootstrap (restore session, build Dependencias)
  app/                 composition root, repository factory, router, guards, routes
  core/                shared, feature-agnostic code
    config/ logging/ map/ models/ network/ push/ session/ storage/ utils/ widgets/
  features/<name>/     one folder per feature, owned by one stream
    data/              <x>_repository.dart (interface) + <x>_repository_http.dart
    <screen>/          page + cubit + state
  layout/ theme/       shells (main/admin) and theming
test/                  unit, cubit, widget and app tests (mirrors lib/)
integration_test/perf/ frame-timing scenarios (perf harness)
test_driver/           host side of the perf harness (writes build/perf/)
tool/                  coverage_summary.dart
docs/                  metricas-baseline.md, diagramas/
```

Rules: features depend on `core` and on repository **interfaces**, never on
another feature or on an SDK (`flutter_map` lives only in `FlutterMapAdapter`).
Endpoint strings live only in `features/*/data/*_repository_http.dart`.
Route path literals live only in `app/rutas.dart`.

## Places and map (M2)

`features/lugares/` has `data/` (`LugarRepository` + HTTP; fake in `test/fakes/`), and one
folder per screen: `mapa/` (map, markers, legend, tile banner), `detalle/`
(place detail, favorite toggle) and `buscar/` (search by name, route
`Rutas.buscarLugar`, which pops the chosen place id with `context.pop(id)`).
`categoria_presentacion.dart` holds the category label/emoji and
`subtituloLugar` ("Parque · 315 m"); `core/utils/distancia.dart` has the
haversine `distanciaMetros` and `formatoDistancia`; `core/widgets` has the
shared `EtiquetaSeccion` and `TarjetaError`.

`MapaAdapter.construirMapa` draws the map without exposing the map SDK. Its
notifications come in an `EventosMapa` parameter object: `alMoverCamara`
(continuous), `alCamaraQuieta` (map ready and after each gesture),
`alErrorTile` and `alTileCargado` (tile failed / loaded; the offline banner is
shown once per outage and re-armed when a tile loads again). Bounds are
`LimitesMapa`; the wire format of `bbox` is `minLng,minLat,maxLng,maxLat`.

Tiles come from `tile.openstreetmap.org` (flutter_map 8, `NetworkTileProvider`)
and are cached on disk with flutter_map's built-in
`BuiltInMapCachingProvider` (`FlutterMapAdapter.tamanoMaximoCache` = 200 MB),
which honours the server's HTTP freshness headers and survives restarts.

Every places request sends `limite`: `MapaCubit.limiteLugares = 200` (map) and
`BuscarLugarCubit.limiteResultados = 50` (search). `MapaCubit.centro` is the
live camera centre (null before the first camera event; the detail then hides
the distance).

## Reports, tiers and analytics (M4)

`features/reportes/` has `data/` (`ReporteRepository` + HTTP; the fake lives in
`test/fakes/reporte_repository_fake.dart`), `reportar/` and `mis_reportes/`.

- **Reportar sheet**: `mostrarReportarSheet` (opened from the place detail)
  completes with `true` once a report was accepted, however the sheet is
  dismissed, so the detail refreshes. `ReportarCubit` guards every emit with
  `isClosed`; a failure is `ReportarFallido` with `bloqueante` (403/404: the
  form only offers "Cerrar") or `reintentable` (offline/5xx: "Reintentar").
  The 422 `REPORTE_EN_ESPERA` shows the server message (minutes left).
  Success only thanks the user: sending a report earns no points (they come
  once it is VALIDADO), so neither the sheet nor the detail's "Reporte
  enviado" snackbar announces any.
- **Mis reportes** (`Rutas.perfilReportes`): paginated, newest first.
  `MisReportesCubit.cargar` over a loaded list keeps it visible; "Cargar más"
  de-duplicates by `id` and stops on an empty page. A row shows `+puntos`
  only when the backend sent `puntos > 0` (10 for a VALIDADO report).
- **Tier** (CRO-74): `Usuario.puntos` and `Usuario.tier` come from the backend
  (`tier`: `CROWD_BABY` | `CROWD_EXPLORER` | `CROWD_COLLABORATOR` |
  `CROWD_ROYALTY`; unknown or missing reads as Crowd Baby). The profile shows
  `TarjetaTier` (`features/perfil/widgets/`): the badge of
  `TierUsuario.insignia` next to its name. The app never derives the tier from
  the points and does not show the points (pending a team decision). The test fakes
  seed both in `test/fakes/datos_fake.dart`.
- **Refresh without blanking**: `PerfilCubit.refrescar` (profile tab
  re-activation) and `DetalleLugarCubit.refrescar` (after a report) keep the
  data on screen and only add a soft error (`errorActualizacion`, snackbar).

`features/analitica/` has `data/` (`AnaliticaRepository` + HTTP; fake in
`test/fakes/analitica_repository_fake.dart` with `historial_sintetico.dart`),
and screens `historial/` (`Rutas.historial(id)`, today / 7 days), `comparar/`
(weekdays against weekends) and `mejor_horario/`. `comun/` holds the shared
`AnaliticaCubit<T>` / `AnaliticaState<T>` base (load/retry skeleton; "no data"
is a 200, not an error). **Exception to the one-cubit-one-state convention:**
the three screens share that single generic base instead of declaring their own
state. `widgets/` has `GraficoBarras` (plain bars, no chart dependency),
`VistaAnalitica` (loading / error / no-data / data switch) and `AvisoDemo`
(shown when the backend flags the data `sintetico`).
`AnaliticaParametros` names the shared windows and limits (7-day history,
28-day / 4-week comparison, top 3 slots, opening hours, `LABORABLES` /
`FIN_DE_SEMANA`). `NivelSaturacion.desdePromedio` is the only place the
1.67 / 2.34 cutoffs live.

## Validation (M5)

`features/validacion/`: `data/` (`ValidacionRepository` + HTTP; fake in
`test/fakes/validacion_repository_fake.dart`, with the session checks), and one
folder per screen. The models in
`core/models/validacion.dart` mirror the backend DTOs (`lugar{}` and
`confiabilidad{}` are nested; counts live inside `confiabilidad`).

- **Pending list** (`/validar`, `PendientesCubit`): reports around the last map
  centre (`CentroMapaCompartido`, written by `MapPage`, Lima by default). A vote
  is optimistic: the report leaves the list at once and comes back if the call
  fails; 404 / 409 / 422 keep it removed (409 reads "Ya participaste...").
  Success shows "¡Gracias por validar!" with the choice just made, no points:
  a vote earns them only once the report ends in the state it voted for.
- **Detail** (`/validar/reportes/:id`, `DetalleReporteCubit`): reliability badge
  (`InsigniaConfiabilidad`), raw counts, the BAJA warning, the INSUFICIENTE text,
  my vote and the vote / report actions (hidden on my own reports).
- **Report a report** (`mostrarDenunciarSheet`, `DenunciarCubit`): motivo
  required, description for `OTRO` (280 max); 409 / 422 / 404 end in a blocking
  message, a network failure returns to the form. Completes with `true` when it
  was registered (or already was).
- **Status of my reports** (`/perfil/validaciones`, `EstadoValidacionCubit`):
  first 50 reports, filtered client-side. `ChipEstadoValidacion` is also shown
  by `MisReportesPage` when it is given a `ValidacionRepository` (merged by
  report id, best effort).

## Favorites, alerts and filters (M3)

`features/favoritos/`: `data/` (`FavoritoRepository` + HTTP; fake in
`test/fakes/favorito_repository_fake.dart`) and `lista/`. `FavoritosCubit`
removes a favorite (a 404 counts as already gone) and offers undo
(`deshacerEliminar` adds it back, alert preference included). The master
switch "Alertas de cambios" is derived (`todasConAlertas`) and toggling it
sends one `configurarAlertas` per favorite that differs; a failure reloads
what the server holds. The page refreshes when the tab is re-activated. A
duplicate add is a 409 `FAVORITO_DUPLICADO`, handled by the place detail as
"already a favorite" (no error screen).

`features/exploracion/`: `data/` (`ExploracionRepository`: `explorar` with a
`FiltroExploracion`, `listarCategorias`) and `explorar/`. `FiltrosMapa` (the
chips and level control on `MapPage`) owns an `ExplorarCubit` (the server
categories plus the chosen filters) and reports changes through `alCambiar`;
the page calls `MapaCubit.aplicarFiltros`, which reloads the visible area and
keeps the filters while panning and retrying. Under a filter an empty result
reads with the HU 3.5 / 3.6 messages. `ExploracionRepository.explorar` (list
ordered by distance) is ready but no screen uses it yet; `/mapa/explorar`
is still a placeholder.

`features/alertas/`: `data/` (`AlertaRepository`: list with the unread count,
mark read, register / delete the push device) and `lista/`. `MainLayout` owns
one `AlertasCubit` per signed-in shell: the Favoritos tab badge
(`CrBottomNav.alertasNoLeidas`) and `AlertasPage` read it, and it reloads
when the app returns to the foreground. Only the first page of alerts is
shown. Tapping an alert marks it read (optimistic, restored on failure) and
opens the place.

Push: `RegistroDispositivo` (in `app/`) registers the token of the
`ReceptorPush` after sign in and removes it in `SesionCubit`'s `antesDeCerrar`
hook, before the session is cleared; both are best effort. `CrowdRadarApp`
turns `ReceptorPush.lugarAbierto` taps (also a cold start) into
`router.push(Rutas.lugar(id))` while signed in. The app uses
`ReceptorPushFcm` (see [Push notifications (Firebase)](#push-notifications-firebase));
`Dependencias.crear` defaults to `ReceptorPushNulo`, and tests use it or
`ReceptorPushConsola` (fake token, `simularApertura`) from `test/fakes/`, so no
test touches Firebase. The in-app alert list is the guaranteed channel.

## Account security (M1)

- **Recover password** (`/recuperar`, `RecuperarCubit`): always shows the
  neutral "Si el correo está registrado..." text. Only a backend with
  `POLITICA_MENSAJES_AUTH=DETALLADA` answers 404 `CUENTA_NO_EXISTE`, which the
  screen shows as "Ese correo no está registrado" (HU 2.1 c3). The reset form
  itself is a page served by the backend (`/recuperar/restablecer?token=`).
- **Change password** (`/perfil/password`, `CambiarPasswordCubit`): checks the
  match and the policy (8-64 characters, at most 72 UTF-8 bytes, an
  uppercase, a digit; see `core/utils/politica_password.dart`) before calling the API. On success the session
  ends with `MotivoCierre.passwordCambiada` (the old token is stale on the
  server) and the login shows the notice.
- **Login messages** (`mensajeDeLogin`): by `code`, `CREDENCIALES_INVALIDAS`,
  `CUENTA_NO_EXISTE` (DETALLADA only), `CUENTA_SUSPENDIDA` and the 429 codes
  (`DEMASIADOS_INTENTOS`, `DEMASIADAS_SOLICITUDES`), which read `Retry-After`
  (`ApiException.reintentarEnSegundos`).
- **Sign out** asks for confirmation; an expired session shows "Tu sesión
  terminó" on the login.
- **Acerca de** (`/perfil/acerca`): name, version (`Entorno.version`, kept equal
  to `pubspec.yaml` by a test), the "© OpenStreetMap contributors" attribution
  (ODbL) and the course line.
- **Recovery link in development**: run the backend with
  `CORREO_PROVEEDOR=consola` to read the recovery link in the server console.

## Naming convention

Domain vocabulary is Spanish (`Lugar`, `Reporte`, `SesionCubit`,
`iniciarSesion`). Technical vocabulary is English (`ApiClient`, `TokenStorage`,
`Interceptor`-style suffixes, doc comments). `ApiException` keeps its field
names (`status`, `message`, `code`, `errors`) as the shared contract; renaming
would ripple through every stream.

Five screens keep the English names they had when the report's class diagrams
were drawn: `LoginPage`, `RegisterPage`, `MapPage`, `ProfilePage` and
`EditProfilePage` (`login_page.dart`, `register_page.dart`, `map_page.dart`,
`profile_page.dart`, `edit_profile_page.dart`). They stay as they are so the
code matches those diagrams; new code follows the rule above.

## Pattern map

| Pattern | Where |
|---|---|
| Composition root (manual DI) | `app/dependencias.dart` (`Dependencias`) |
| Strategy / chain of responsibility | `InterceptorApi` and its implementations in `core/network/interceptores/` |
| Observer | `SesionCubit` listens to the `SessionService.eventos` stream |
| Adapter | `MapaAdapter` (`FlutterMapAdapter`), `ReceptorPush` (`ReceptorPushFcm` in the app; `ReceptorPushNulo` / `ReceptorPushConsola` in tests) |
| Repository + fakes | `<X>Repository` ports, `<x>_repository_http.dart`, `test/fakes/<x>_repository_fake.dart` (`<X>RepositoryFake`) |
| Factory Method | `ClienteHttpFactory` builds the `http.Client` inside `core/network` |
| Null Object (stub) | `RepositorioNoImplementado` mixin: a repository port satisfied by a 501 stub until its stream implements it |
| Abstract Factory | `FabricaRepositorios` builds the whole repository set: `FabricaRepositoriosHttp` in the app, `FabricaRepositoriosFake` in tests (`Dependencias.crear(repositorios:)`) |
| Singleton | `Entorno` (config), `SessionService.instance` (read only in `main.dart`) |
| Facade | `ApiClient` over `http` |
| Template-method-style hook | `SesionCubit.antesDeCerrar`: an injected callback run (2 s bound, failures ignored) before a user sign out, used to unregister the push device |

## Conventions for streams

- Naming is Spanish for the domain (`Usuario`, `Lugar`, `Rutas`) and English for
  technical roles (`Repository`, `Adapter`, `Factory`, `Fake`, `Http`); types
  sort as `<X>Repository`, `<X>RepositoryHttp`, `<X>RepositoryFake`.
- Shared JSON readers (`aMapa`, `aInt`, ...) live in `core/utils/lectura_json.dart`.

- Cubits receive repositories and `SessionService` by constructor; nothing
  outside `main.dart`/`Dependencias` reads `SessionService.instance`.
- Unimplemented repositories use the `RepositorioNoImplementado` stub, which
  throws `ApiException` 501 **synchronously** from `noSuchMethod`: always
  `await` repository calls inside `try` in cubits.
- Failure states carry `mensaje`, `codigo` and `esSinConexion`; use
  `core/utils/mensaje_error.dart` to build them (unknown errors map to a generic
  message, never `toString()`).
- Handled-but-notable errors go through `RegistroErrores` (default: debug
  console).
