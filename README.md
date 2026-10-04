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
| Adapter | `MapaAdapter` (`FlutterMapAdapter`), `ReceptorPush` (`ReceptorPushNulo`) |
| Repository + fakes | `<X>Repository` ports, `<x>_repository_http.dart`, `app/fakes/<x>_repository_fake.dart` (`<X>RepositoryFake`) |
| Factory Method | `ClienteHttpFactory` builds the `http.Client` inside `core/network` |
| Null Object (stub) | `RepositorioNoImplementado` mixin: a repository port satisfied by a 501 stub until its stream implements it |
| Strategy-style selection | `Dependencias` picks the HTTP or the fake repository set from `USAR_FAKES` |
| Singleton | `Entorno` (config), `SessionService.instance` (read only in `main.dart`) |
| Facade | `ApiClient` over `http` |

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
