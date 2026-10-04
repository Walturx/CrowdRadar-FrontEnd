# CrowdRadar (Flutter client)

Mobile client for CrowdRadar: live crowd saturation of places, reports,
validation, favorites and an admin moderation area.

## Run

```bash
flutter pub get
flutter run --dart-define=API_URL=http://10.0.2.2:3000        # real backend
flutter run --dart-define=USAR_FAKES=true                      # in-memory fakes
```

| Define | Default | Meaning |
|---|---|---|
| `API_URL` | `http://10.0.2.2:3000` | Backend base URL (Android emulator host). |
| `USAR_FAKES` | `false` | Every repository resolves to its in-memory `*RepositoryFake`. Refused in release builds (`Dependencias.crear` throws). |

Fake login: see `lib/app/fakes/datos_fake.dart`. Cleartext HTTP is allowed in
the Android **debug** manifest only.

## Tests

```bash
flutter analyze
flutter test
```

`test/core/reglas_arquitectura_test.dart` enforces the layering rules below.

## Folder tree

```
lib/
  main.dart            bootstrap (restore session, build Dependencias)
  app/                 composition root, router, guards, routes, fakes
  core/                shared, feature-agnostic code
    config/ logging/ map/ models/ network/ push/ session/ storage/ utils/ widgets/
  features/<name>/     one folder per feature, owned by one stream
    data/              <x>_repository.dart (interface) + <x>_repository_http.dart
    <screen>/          page + cubit + state
  layout/ theme/       shells (main/admin) and theming
```

Rules: features depend on `core` and on repository **interfaces**, never on
another feature or on an SDK (`flutter_map` lives only in `FlutterMapAdapter`).
Endpoint strings live only in `features/*/data/*_repository_http.dart`.
Route path literals live only in `app/rutas.dart`.

## Places and map (M2)

`features/lugares/` has `data/` (`LugarRepository` + HTTP + fake), and one
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

Every places request sends `limite`: `MapaCubit.limiteLugares = 200` (map) and
`BuscarLugarCubit.limiteResultados = 50` (search). `MapaCubit.centro` is the
live camera centre (null before the first camera event; the detail then hides
the distance).

## Reports, karma and analytics (M4)

`features/reportes/` has `data/` (`ReporteRepository` + HTTP; the fake lives in
`app/fakes/reporte_repository_fake.dart`), `reportar/` and `mis_reportes/`.

- **Reportar sheet**: `mostrarReportarSheet` (opened from the place detail)
  completes with `true` once a report was accepted, however the sheet is
  dismissed, so the detail refreshes. `ReportarCubit` guards every emit with
  `isClosed`; a failure is `ReportarFallido` with `bloqueante` (403/404: the
  form only offers "Cerrar") or `reintentable` (offline/5xx: "Reintentar").
  The 422 `REPORTE_EN_ESPERA` shows the server message (minutes left).
- **Mis reportes** (`Rutas.perfilReportes`): paginated, newest first.
  `MisReportesCubit.cargar` over a loaded list keeps it visible; "Cargar más"
  de-duplicates by `id` and stops on an empty page.
- **Karma**: `Usuario.puntosKarma`, shown by the profile's karma card.
  `KarmaFake` is the counter shared by the report and profile fakes.
- **Refresh without blanking**: `PerfilCubit.refrescar` (profile tab
  re-activation) and `DetalleLugarCubit.refrescar` (after a report) keep the
  data on screen and only add a soft error (`errorActualizacion`, snackbar).

`features/analitica/` has `data/` (`AnaliticaRepository` + HTTP; fake in
`app/fakes/analitica_repository_fake.dart` with `historial_sintetico.dart`),
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
`app/fakes/validacion_repository_fake.dart`, which shares `KarmaFake` and the
session checks), and one folder per screen. The models in
`core/models/validacion.dart` mirror the backend DTOs (`lugar{}` and
`confiabilidad{}` are nested; counts live inside `confiabilidad`).

- **Pending list** (`/validar`, `PendientesCubit`): reports around the last map
  centre (`CentroMapaCompartido`, written by `MapPage`, Lima by default). A vote
  is optimistic: the report leaves the list at once and comes back if the call
  fails; 404 / 409 / 422 keep it removed (409 reads "Ya participaste...").
  Success shows the thanks and "+2 karma" with the choice just made.
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
`app/fakes/favorito_repository_fake.dart`) and `lista/`. `FavoritosCubit`
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
`router.push(Rutas.lugar(id))` while signed in. Real delivery (FCM) is not
part of this build: `ReceptorPushNulo` is the default and `ReceptorPushConsola`
(fake token, `simularApertura`) is used with `USAR_FAKES`; the in-app alert
list is the guaranteed channel.

## Account security (M1)

- **Recover password** (`/recuperar`, `RecuperarCubit`): always shows the
  neutral "Si el correo está registrado..." text. Only a backend with
  `POLITICA_MENSAJES_AUTH=DETALLADA` answers 404 `CUENTA_NO_EXISTE`, which the
  screen shows as "Ese correo no está registrado" (HU 2.1 c3). The reset form
  itself is a page served by the backend (`/recuperar/restablecer?token=`).
- **Change password** (`/perfil/password`, `CambiarPasswordCubit`): checks the
  match and the policy (8-64 characters, an uppercase, a digit; see
  `requisitos_password.dart`) before calling the API. On success the session
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
- **Demo without a backend**: `flutter run --dart-define=USAR_FAKES=true`;
  recovery answers the neutral text and the password change uses the fake
  password in `lib/app/fakes/datos_fake.dart`. With the real backend use
  `CORREO_PROVEEDOR=consola` to read the recovery link in the server console.

## Naming convention

Domain vocabulary is Spanish (`Lugar`, `Reporte`, `SesionCubit`,
`iniciarSesion`). Technical vocabulary is English (`ApiClient`, `TokenStorage`,
`Interceptor`-style suffixes, doc comments). `ApiException` keeps its field
names (`status`, `message`, `code`, `errors`) as the shared contract; renaming
would ripple through every stream.

## Pattern map

| Pattern | Where |
|---|---|
| Composition root (manual DI) | `app/dependencias.dart` (`Dependencias`) |
| Strategy / chain of responsibility | `InterceptorApi` and its implementations in `core/network/interceptores/` |
| Observer | `SesionCubit` listens to the `SessionService.eventos` stream |
| Adapter | `MapaAdapter` (`FlutterMapAdapter`), `ReceptorPush` (`ReceptorPushNulo`, `ReceptorPushConsola`) |
| Repository + fakes | `<X>Repository` ports, `<x>_repository_http.dart`, `app/fakes/<x>_repository_fake.dart` (`<X>RepositoryFake`) |
| Factory Method | `ClienteHttpFactory` builds the `http.Client` inside `core/network` |
| Null Object (stub) | `RepositorioNoImplementado` mixin: a repository port satisfied by a 501 stub until its stream implements it |
| Strategy-style selection | `Dependencias` picks the HTTP or the fake repository set from `USAR_FAKES` |
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
