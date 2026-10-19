# Métricas baseline del frontend (Fase 1)

Esta es la medición **antes de cualquier optimización**. No se modificó código de producto ni se agregaron pruebas de producto. Los únicos agregados son `tool/coverage_summary.dart` y el arnés de rendimiento (`integration_test/perf/`, `test_driver/`).

- **Fecha:** 2026-10-18
- **Rama / commit medido:** `feat/m6-fe-03-denunciados` @ `458e0e6`

## Resumen

| Métrica | Valor baseline |
|---|---|
| `flutter test`: tiempo de pared | **56.7 s** (el runner reporta 00:48–00:56) |
| `flutter test`: resultado | **1020 pasan / 0 fallan / 0 omitidas** (113 archivos `*_test.dart`) |
| `flutter test --coverage`: tiempo de pared | 71.8 s |
| Cobertura de líneas total (`lib/`) | **96.2 %** (5518 / 5736) |
| Cobertura de líneas `lib/features` | **96.8 %** (3530 / 3646) |
| Arranque en frío (`am start -W`, TotalTime, mediana de 5) | **1364 ms** |
| Primer frame (`--trace-startup`) | 284.7 ms construido / 1553.1 ms rasterizado |
| Frames > 16 ms: mapa pan/zoom | 12.8 % / 25.1 % (corrida 1 / corrida 2) |
| Frames > 16 ms: listas largas | 30–36 % (ver detalle) |
| Páginas con `ListView(children: …)` | **14** |
| Caché de tiles | **Sin caché en disco**: `NetworkTileProvider` por defecto, solo con el `ImageCache` en memoria |

## Entorno de medición

| Elemento | Valor |
|---|---|
| CPU | AMD Ryzen 5 7600X, 6 núcleos / 12 hilos |
| RAM | 31.1 GB |
| SO host | Windows 11 Pro 10.0.26200 |
| Flutter / Dart | Flutter 3.41.9 (stable, `00b0c91f06`), Dart 3.11.5, DevTools 2.54.2 |
| Emulador | AVD `Pixel_9_Pro`, Android Emulator 37.2.12.0, imagen `android-37.2 / google_apis_playstore_ps16k / x86_64` (Android 17, API 37), 4 vCPU, 2 GB RAM, `hw.gpu.mode=auto`, 1280×2856 |
| Backend | `crowdradar-backend-api-1` (docker, `localhost:3000`, desde el emulador `10.0.2.2:3000`) con el seed bench: 200 lugares, 100 usuarios, ~8600 reportes, 150 reportes denunciados |

**Ruido conocido.** Durante la medición corrían en docker contenedores ajenos al proyecto:

- dos stacks Supabase completos: `*_implementext-ref-leadhunter` y `*_apoyo-ia`;
- el stack `reserva-labs-*`;
- `crowdradar-testdb`.

Además, las dos primeras corridas de `flutter test` coincidieron con el arranque del emulador. La corrida de cobertura y las de rendimiento se hicieron con el emulador ya iniciado.

## 1. `flutter test`

| Corrida | Tiempo de pared | Reporte del runner | Resultado |
|---|---:|---:|---|
| 1 (con `--reporter expanded`, emulador arrancando) | ~57 s | 00:56 | +1020 |
| 2 (medido con `Measure-Command`) | 56.7 s | 00:48 | +1020, All tests passed |
| `--coverage` | 71.8 s | 01:04 | +1020 |

**Concurrencia.** Se usa la concurrencia por defecto. No existe `dart_test.yaml` ni `test/flutter_test_config.dart`, y no se pasa `-j`. `flutter_tools` solo reenvía `--concurrency` cuando se especifica (`packages/flutter_tools/lib/src/test/runner.dart:81`). Por eso aplica el valor por defecto de `package:test`, la mitad de los procesadores lógicos: 12 / 2 = **6 procesos**.

## 2. Cobertura (`flutter test --coverage`)

El resumen sale de `dart run tool/coverage_summary.dart`, que parsea `coverage/lcov.info` sin `lcov` ni `genhtml`.

| Ámbito | Líneas cubiertas | Líneas instrumentadas | Cobertura |
|---|---:|---:|---:|
| Total (`lib/`) | 5518 | 5736 | 96.2 % |
| `lib/features` | 3530 | 3646 | 96.8 % |

| Carpeta de `lib/` | Cubiertas | Instrumentadas | Cobertura |
|---|---:|---:|---:|
| app | 885 | 913 | 96.9 % |
| core | 1021 | 1090 | 93.7 % |
| features | 3530 | 3646 | 96.8 % |
| layout | 61 | 64 | 95.3 % |
| theme | 21 | 23 | 91.3 % |

| Feature | Cubiertas | Instrumentadas | Cobertura |
|---|---:|---:|---:|
| alertas | 180 | 193 | 93.3 % |
| analitica | 224 | 229 | 97.8 % |
| auth | 296 | 297 | 99.7 % |
| exploracion | 119 | 127 | 93.7 % |
| favoritos | 268 | 278 | 96.4 % |
| lugares | 523 | 527 | 99.2 % |
| moderacion | 719 | 747 | 96.3 % |
| perfil | 391 | 399 | 98.0 % |
| reportes | 284 | 293 | 96.9 % |
| validacion | 526 | 556 | 94.6 % |

**Salvedad.** `lcov.info` solo incluye los archivos que alguna prueba carga: 178 de 196 archivos `.dart` de `lib/`. Los 18 ausentes son casi todos interfaces abstractas sin líneas ejecutables, como `*_repository.dart`, `mapa_adapter.dart`, `token_storage.dart` y `receptor_push.dart`. También faltan enums o constantes (`motivo_cierre.dart`, `categoria_lugar.dart`, `analitica_parametros.dart`, `excepcion_con_mensaje.dart`, `repositorio_no_implementado.dart`) y **`lib/main.dart`**, que no se cubre. Su efecto sobre el porcentaje es marginal.

## 3. Rendimiento en modo profile (emulador Android)

El modo profile sobre el emulador x86_64 **funcionó sin errores**: `flutter build apk --profile`, `flutter run --profile` y `flutter drive --profile`. No hizo falta recurrir a modo debug.

### 3.1 Arranque en frío

Pasos: se construyó `flutter build apk --profile` (125 s) y se instaló. En cada corrida se ejecutó `adb shell am force-stop com.example.crowdradar` y luego `adb shell am start -W -n com.example.crowdradar/.MainActivity`. Se descartó un primer arranque posterior a la instalación, que tomó 2013 ms.

| Corrida | 1 | 2 | 3 | 4 | 5 | **Mediana** |
|---|---:|---:|---:|---:|---:|---:|
| TotalTime (ms) | 1364 | 1469 | 1175 | 1606 | 1253 | **1364** |

`TotalTime` mide hasta el primer frame de la ventana Android. Sin sesión persistida, la app muestra el `ArranqueApp` (restauración de sesión, máximo 3 s) y luego el login.

`flutter run --profile --trace-startup` generó `build/start_up_info.json` con estos valores:

| Campo | µs |
|---|---:|
| `timeToFrameworkInitMicros` | 273 276 |
| `timeToFirstFrameMicros` | 284 694 |
| `timeToFirstFrameRasterizedMicros` | 1 553 055 |
| `timeAfterFrameworkInitMicros` | 11 418 |

El primer frame se construye en unos 285 ms, pero tarda unos 1.55 s en rasterizarse. Ese tiempo incluye inicializar la GPU del emulador y compilar shaders.

### 3.2 Frames lentos (arnés reproducible)

El arnés está en `integration_test/perf/app_perf_test.dart`, con el driver `test_driver/perf_driver.dart`. Corre contra el **backend real** con el seed bench, sin fakes:

- El rol usuario usa `bench001@bench.crowdradar.local`.
- El rol admin usa `ADMIN_EMAIL` / `ADMIN_PASSWORD` del `.env` del backend, que se pasan por `--dart-define`.
- Cada escenario usa `IntegrationTestWidgetsFlutterBinding.watchPerformance` (`FrameTiming`) con la política de frames `fullyLive`.
- El driver escribe `build/perf/<escenario>.json` y `build/perf/resumen.md`.

Un frame cuenta como lento si su build **o** su raster supera 16.67 ms.

```sh
flutter drive --profile --no-dds -d emulator-5554 \
  --driver=test_driver/perf_driver.dart \
  --target=integration_test/perf/app_perf_test.dart \
  --dart-define=PERF_ADMIN_EMAIL=<ADMIN_EMAIL> \
  --dart-define=PERF_ADMIN_PASSWORD=<ADMIN_PASSWORD>
```

Notas del arnés:

- `--no-dds` es obligatorio. Sin esa opción, `watchPerformance` no puede conectarse al VM Service.
- Sin `PERF_ADMIN_PASSWORD`, los escenarios admin se omiten.
- Cada corrida inicia sesión 2 veces. El backend limita el login a 10 intentos cada 15 min por IP.
- En `buscar_lugar`, la consulta se envía directo al `BuscarLugarCubit`, porque `enterText` no llega a `onChanged` con el IME real del binding de integración.

| Escenario | Interacción medida |
|---|---|
| `mapa_pan_zoom` | `/mapa` (200 marcadores, tiles OSM reales): 4 arrastres de 300 px y luego pinch zoom de entrada y de salida |
| `mis_reportes_scroll` | `/perfil/reportes`: se expande a 101 filas (4 × "Cargar más") y se hacen 5 flings hacia abajo y 5 hacia arriba |
| `buscar_lugar_scroll` | `/mapa/buscar` con "Bench": 50 resultados (`ListView.builder`) y 5 flings en cada sentido |
| `admin_denunciados_scroll` | `/admin/reportes`: se expande a unos 100 ítems y se hacen 5 flings en cada sentido |
| `admin_usuarios_scroll` | `/admin/usuarios`: se expande a unos 100 usuarios y se hacen 5 flings en cada sentido |

**Corrida 1**

| Escenario | Frames | Build prom / p90 / p99 (ms) | Raster prom / p90 / p99 (ms) | Frames > 16 ms |
|---|---:|---|---|---:|
| mapa_pan_zoom | 462 | 1.23 / 2.86 / 9.01 | 8.61 / 17.33 / 32.08 | 59 (12.8 %) |
| mis_reportes_scroll | 1000 | 0.94 / 1.63 / 2.30 | 15.60 / 20.07 / 35.88 | 332 (33.2 %) |
| buscar_lugar_scroll | 1012 | 0.88 / 1.45 / 2.86 | 15.25 / 20.45 / 39.40 | 306 (30.2 %) |
| admin_denunciados_scroll | 997 | 0.77 / 1.28 / 2.31 | 16.51 / 21.76 / 41.40 | 363 (36.4 %) |
| admin_usuarios_scroll | 956 | 0.90 / 1.57 / 2.66 | 14.76 / 24.99 / 45.77 | 305 (31.9 %) |

**Corrida 2**

| Escenario | Frames | Build prom / p90 / p99 (ms) | Raster prom / p90 / p99 (ms) | Frames > 16 ms |
|---|---:|---|---|---:|
| mapa_pan_zoom | 434 | 1.55 / 3.15 / 16.93 | 11.15 / 20.95 / 35.15 | 109 (25.1 %) |
| mis_reportes_scroll | 906 | 1.09 / 1.76 / 5.45 | 18.80 / 26.97 / 100.76 | 316 (34.9 %) |
| buscar_lugar_scroll | 1019 | 0.84 / 1.46 / 2.83 | 16.51 / 19.40 / 35.19 | 365 (35.8 %) |
| admin_denunciados_scroll | 1008 | 0.83 / 1.43 / 3.25 | 15.01 / 20.03 / 35.50 | 303 (30.1 %) |
| admin_usuarios_scroll | 1001 | 0.97 / 1.58 / 4.26 | 15.61 / 21.33 / 34.79 | 346 (34.6 %) |

**Lectura.**

- **El build es bajo en todos los escenarios:** promedio de 1 ms o menos y p99 de 6 ms o menos, salvo el mapa, con un p99 de unos 17 ms.
- **Los frames lentos se deben al raster**, con promedios de unos 15–19 ms.
- **Ese raster depende sobre todo de la GPU emulada:** la lista con builder (`buscar_lugar`) muestra el mismo patrón que las listas `ListView(children: …)`.
- **El mapa varía mucho entre corridas** (12.8 % frente a 25.1 %), porque depende de la descarga de tiles OSM, que no tienen caché en disco.
- **Comparaciones futuras:** deben hacerse con este mismo arnés y en el mismo AVD. Los valores absolutos no son extrapolables a un dispositivo físico.

## Observaciones (inventario para fases posteriores)

### O1. Páginas con `ListView(children: …)` sin builder: 14

| # | Archivo:línea |
|---:|---|
| 1 | `lib/features/favoritos/lista/favoritos_page.dart:124` |
| 2 | `lib/features/alertas/lista/alertas_page.dart:63` |
| 3 | `lib/features/moderacion/revision_reporte/revision_reporte_page.dart:111` |
| 4 | `lib/features/analitica/widgets/vista_analitica.dart:80` |
| 5 | `lib/features/moderacion/usuario_detalle/usuario_admin_detalle_page.dart:61` |
| 6 | `lib/features/moderacion/denunciados/denunciados_page.dart:69` |
| 7 | `lib/features/moderacion/usuarios/usuarios_admin_page.dart:154` |
| 8 | `lib/features/reportes/mis_reportes/mis_reportes_page.dart:86` |
| 9 | `lib/features/validacion/pendientes/validar_page.dart:76` |
| 10 | `lib/features/validacion/estado/estado_validacion_page.dart:55` |
| 11 | `lib/features/validacion/detalle_reporte/detalle_reporte_page.dart:68` |
| 12 | `lib/features/perfil/ver/profile_page.dart:107` |
| 13 | `lib/features/perfil/acerca/acerca_page.dart:20` |
| 14 | `lib/features/lugares/detalle/detalle_lugar_page.dart:157` |

En todo `lib/` solo hay un `ListView.builder`, en `lib/features/lugares/buscar/buscar_lugar_page.dart:111`. Las listas paginadas (mis reportes, denunciados, usuarios, validar) construyen **todas** las filas cargadas en cada build.

### O2. Carga de tiles del mapa

- La configuración vive en `lib/core/map/flutter_map_adapter.dart:58`, el único archivo que importa `flutter_map` (versión 7.0.2).
- El `TileLayer` usa `urlTemplate: https://tile.openstreetmap.org/{z}/{x}/{y}.png` y `userAgentPackageName: com.crowdradar.app`.
- `tileProvider` es inyectable, pero en producción es `null` (`lib/app/dependencias.dart:116` usa `FlutterMapAdapter()`). Se aplica entonces el `NetworkTileProvider` por defecto.
- **No hay caché persistente.** Los tiles solo quedan en el `ImageCache` en memoria de Flutter, y no hay dependencias de caché en `pubspec.yaml`.
- Tampoco se configuran `keepBuffer`, `panBuffer`, `maxNativeZoom` ni un `tileProvider` con caché.

### O3. Pruebas de estados de error por Cubit

Cómo se mapean los errores en `lib/core/network`:

- `ApiClient` usa `timeoutPorDefecto = 15 s`.
- `TimeoutException`, `SocketException` y `ClientException` se convierten en `ApiException.sinConexion()` (status 0). **Timeout y "sin red" son el mismo error para los Cubits.**
- 401 y 5xx llegan como `ApiException(status)`, sin un tipo propio.
- El 401 fuera de `/api/auth/` lo atiende globalmente `SesionExpiradaInterceptor`, que expira la sesión. Ese caso está probado una sola vez, en el core: `test/core/network/api_client_test.dart` y `test/core/session/session_service_test.dart`. El core también prueba 500 y 500 con cuerpo no JSON.

Leyenda:

- **Sí**: el escenario está probado.
- **Parcial**: está probado el equivalente (para timeout, el caso `sinConexion`), pero no el caso específico.
- **No**: no hay prueba.

| Cubit | Timeout (15 s) | 401 | 5xx | Sin red | Notas |
|---|---|---|---|---|---|
| SesionCubit (core) | N/A | Sí | N/A | N/A | expirar → NoAutenticada |
| LoginCubit | Parcial | Parcial | Sí | Sí | 401 = credenciales inválidas, no expiración |
| RegistroCubit | Parcial | No | No | Sí | prueba 409/400 |
| RecuperarCubit | Parcial | No | No | Sí | prueba 404/429 |
| AlertasCubit | Parcial | No | Sí | Sí | 500 y 503 |
| AnaliticaCubit (base de Historial / Comparar / MejorHorario) | Parcial | No | Sí | Sí | |
| ExplorarCubit | Parcial | No | No | Sí | |
| FavoritosCubit | Parcial | No | Sí | Sí | |
| BuscarLugarCubit | Parcial | No | Sí | Sí | |
| DetalleLugarCubit | Parcial | No | Sí | Sí | |
| MapaCubit | Parcial | No | Sí | Sí | |
| DenunciadosCubit | Parcial | No | Sí | Sí | |
| RevisionReporteCubit | Parcial | No | No | Sí | prueba 404/409 |
| UsuariosAdminCubit | Parcial | No | Sí | Sí | |
| UsuarioAdminDetalleCubit | Parcial | No | Sí | Sí | 500 solo en reactivar |
| PerfilCubit | Parcial | Sí | Sí | Sí | 401 generado por el repositorio |
| EditarPerfilCubit | Parcial | No | Sí | Sí | |
| CambiarPasswordCubit | Parcial | No | Sí | Sí | sin red → resultado incierto |
| MisReportesCubit | Parcial | No | Sí | Sí | |
| ReportarCubit | Parcial | No | Sí | Sí | 503 reintentable (lógica por status) |
| DetalleReporteCubit | Parcial | No | Sí | Sí | |
| DenunciarCubit | Parcial | No | No | Sí | ramifica 404/409/422; el fallback 5xx no está probado |
| EstadoValidacionCubit | Parcial | No | No | Sí | |
| PendientesCubit | Parcial | No | Sí | Sí | |

Totales sobre los 23 Cubits con HTTP:

| Caso | Sí | Parcial | No |
|---|---:|---:|---:|
| Timeout | 0 | 23 | 0 |
| 401 | 1 (PerfilCubit) | 1 (LoginCubit) | 21 |
| 5xx | 17 | 0 | 6 |
| Sin red | 23 | 0 | 0 |

SesionCubit, que no hace HTTP, también prueba el 401.

Brechas reales:

- **5xx en Cubits que ramifican por status:** `DenunciarCubit` no prueba su fallback 5xx.
- **5xx en Cubits con manejo genérico:** Registro, Recuperar, Explorar, RevisionReporte y EstadoValidacion manejan los errores de forma genérica, así que el caso ya queda cubierto por sus pruebas de 4xx o sin red.
- **Timeout:** no tiene tipo propio, así que una prueba de timeout a nivel Cubit solo aportaría valor si en el futuro se distingue de "sin red".
