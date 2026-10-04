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
| `USAR_FAKES` | `false` | Every repository resolves to its in-memory `Fake*`. Refused in release builds (`Dependencias.crear` throws). |

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
| Repository + fakes | `<X>Repository` interfaces, `*_repository_http.dart`, `app/fakes/Fake*` |
| Singleton | `Entorno` (config), `SessionService.instance` (read only in `main.dart`) |
| Facade | `ApiClient` over `http` |

## Conventions for streams

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
