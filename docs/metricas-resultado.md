# Métricas de resultado del frontend (antes / después)

Medición final del frontend tras las fases 2, 3 y 4 del plan, con los mismos comandos, el mismo equipo y el mismo AVD que
la línea base ([`metricas-baseline.md`](metricas-baseline.md)).

- **Antes:** línea base, código `458e0e6` (documentada en `3e113e6`), medida el 2026-10-18.
- **Después:** `eb1e86a` de `feat/m6-fe-03-denunciados`, medido el 2026-10-26.
- **Comparaciones A/B:** donde la cifra absoluta depende del estado del emulador, base y HEAD se midieron intercalados en
  la misma sesión. Para eso se compiló `3e113e6` en un worktree temporal fuera del repositorio, que después se borró.

Las métricas del backend están en el repositorio del backend, en `docs/metricas-resultado.md`.

## Entorno de medición

| Elemento | Valor |
|---|---|
| CPU / RAM | AMD Ryzen 5 7600X (6 núcleos / 12 hilos), 31,1 GB |
| SO host | Windows 11 Pro 10.0.26200 |
| Flutter / Dart | Flutter 3.41.9 (stable), Dart 3.11.5 |
| Emulador | AVD `Pixel_9_Pro`, Android 17 (API 37), x86_64, 4 vCPU, 2 GB, `hw.gpu.mode=auto`, con ventana. Boot en 36 s; se esperó 1 min en reposo antes de medir |
| Backend | `crowdradar-backend-api-1` (docker) con `npm run bench:seed` recién aplicado: 200 lugares, 100 usuarios, 5000 reportes bench, 150 reportes denunciados |
| Otros procesos | Docker Desktop con `crowdradar-testdb` y un contenedor ajeno en reposo. Ningún bench ni suite del backend corrió durante estas mediciones |

## Tabla de metas

| Métrica | Antes | Después | Meta | ¿Cumplida? |
|---|---|---|---|---|
| Cobertura de líneas `lib/features` | 96,8 % | **97,3 %** | ≥ 80 % | Cumplida |
| Cobertura de líneas total (`lib/`) | 96,2 % | 96,5 % | (informativa) | — |
| Cubits con pruebas de error (timeout 15 s, 401, 5xx, sin red) | Timeout 0/23 (solo el equivalente), 401 1/23, 5xx 17/23, sin red 23/23 | **23/23 en los 4 casos** (helper `test/helpers/errores_comunes.dart`) | Todos | Cumplida |
| Flakiness `flutter test` (3 corridas) | No medido | 3/3 idénticas: 1203 OK, 0 fallidas | 0 inestables | Cumplida |
| Duración de `flutter test` (pared, mediana) | 56,7 s (1020 pruebas) | 48,8 s (1203 pruebas): −14 % | −20 % | **No cumplida** |
| Páginas con `ListView(children: …)` | 14 | **0** (las 14 usan `ListaPerezosa`, sobre `ListView.builder`) | 0 | Cumplida |
| Caché de tiles del mapa | Sin caché en disco | Caché en disco de `flutter_map` 8.3.2 (200 MB) detrás de `FlutterMapAdapter` | Con caché | Cumplida |
| Arranque en frío (`am start -W`, mediana A/B en la misma sesión) | 1563 ms (`3e113e6`) | 1495 ms: −4 % | −20 % | **No cumplida** |
| Frames > 16 ms al hacer scroll en listas | 30–36 % | 29–43 % (A/B: ~99 % en base y en HEAD con la GPU degradada) | 0 | **No cumplida** |
| Diagramas PlantUML del front | 0 | 4 (`componentes`, `despliegue`, `navegacion`, `secuencia-reporte-validacion`), enlazados en el README | ≥ 8 entre los dos repos | Cumplida (9 en total con el backend) |

## 1. `flutter test`

| Corrida | Pared | Runner | Resultado |
|---|---:|---:|---|
| 1 | 60,1 s | 00:37 | +1203, All tests passed |
| 2 | 45,1 s | 00:37 | +1203, All tests passed |
| 3 | 48,8 s | 00:41 | +1203, All tests passed |
| **Mediana** | **48,8 s** | **00:37** | |
| `--coverage` | 80,4 s | 01:12 | +1203 |

**Por qué no se cumple el −20 %.**

- **Tiempo de pared:** bajó un 14 % (56,7 → 48,8 s) con un 18 % más de pruebas (1020 → 1203). Por prueba, la caída es del
  27 %. El tiempo del runner bajó de 00:48 a 00:37 (−23 %).
- **La meta se mide sobre el tiempo de pared, que no llega.** Lo domina la compilación: el frontend server compila cada uno
  de los ~115 archivos de prueba por separado (300–500 ms cada uno). Por eso `-j` y `dart_test.yaml` casi no cambian el
  resultado.
- **`--experimental-faster-testing` no se puede usar:** junta los archivos en uno solo, pero falla porque el nombre del
  directorio del repo tiene un guion y el alias de import que genera queda inválido.
- **La primera corrida es más lenta:** compila con la caché fría.

Después de esta medición, los fixes de perfil (`d22332c`, `4745be8`) dejaron la suite en 1206 pruebas, todas en verde.

## 2. Cobertura

| Ámbito | Antes | Después |
|---|---:|---:|
| Total (`lib/`) | 96,2 % (5518 / 5736) | **96,5 %** (5589 / 5793) |
| `lib/features` | 96,8 % (3530 / 3646) | **97,3 %** (3561 / 3661) |

| Feature | Antes | Después |
|---|---:|---:|
| alertas | 93,3 % | 93,3 % |
| analitica | 97,8 % | 97,8 % |
| auth | 99,7 % | 99,7 % |
| exploracion | 93,7 % | 95,3 % |
| favoritos | 96,4 % | 96,4 % |
| lugares | 99,2 % | 99,2 % |
| moderacion | 96,3 % | 97,6 % |
| perfil | 98,0 % | 98,0 % |
| reportes | 96,9 % | 97,0 % |
| validacion | 94,6 % | 95,3 % |

`lcov.info` incluye 179 archivos (antes, 178). Los ausentes siguen siendo interfaces abstractas, enums y `lib/main.dart`.

## 3. Arranque en frío

### 3.1 Corrida simple (como la línea base)

`flutter build apk --profile`, instalación, un arranque descartado y 5 corridas de `am force-stop` + `am start -W`:

| Corrida | 1 | 2 | 3 | 4 | 5 | Mediana |
|---|---:|---:|---:|---:|---:|---:|
| TotalTime (ms) | 2332 | 2426 | 3250 | 2707 | 2545 | **2545** |

**Esa cifra no sirve para comparar con la base** (1364 ms). Para descartar una regresión se repitió la medición
intercalando los dos APK en la misma sesión (3.2). Con el mismo código base, el emulador recién iniciado daba 2949 y
3313 ms. La diferencia la explica el estado del emulador, no el código.

### 3.2 A/B en la misma sesión (`3e113e6` y HEAD intercalados, 5 corridas por bloque)

| Ronda | APK | TotalTime (ms) | Mediana |
|---|---|---|---:|
| 1 | base | 2949 / 2429 / 1572 / 3313 / 1958 | 2429 |
| 1 | HEAD | 1761 / 1695 / 1640 / 1356 / 1658 | 1658 |
| 2 | base | 1563 / 1496 / 1489 / 1598 / 1632 | **1563** |
| 2 | HEAD | 1430 / 1670 / 1495 / 1473 / 1528 | **1495** |

La ronda 1 todavía muestra el calentamiento del emulador. La ronda 2, ya estable, da **−4 %** a favor de HEAD.

### 3.3 `--trace-startup` (A/B, 2 trazas por versión)

| Campo (ms) | base #1 | base #2 | HEAD #1 | HEAD #2 |
|---|---:|---:|---:|---:|
| `timeToFrameworkInit` | 266,0 | 252,7 | 178,3 | 229,3 |
| `timeToFirstFrame` | 277,6 | 881,5* | 187,5 | 243,1 |
| `timeToFirstFrameRasterized` | 1064,0 | 947,0 | 933,2 | 933,1 |

\* `timeAfterFrameworkInit` de 628,8 ms en esa traza: un valor atípico del emulador, no del código.

**Por qué no se cumple el −20 %.**

- **Lo que hizo la Fase 3 en Dart funciona:** el tema se construye una sola vez, la sesión se lee en paralelo y el
  registro de push se difiere al primer frame. El primer frame construido baja de ~278 ms a ~190–245 ms.
- **Pero ese tramo es una parte chica del `TotalTime`:** el `TotalTime` de 1,5 s lo dominan el arranque del proceso
  Android, la carga del engine y el primer rasterizado en la GPU emulada (~0,93–1,06 s), y nada de eso cambia desde Dart.

## 4. Frames (arnés `integration_test/perf/app_perf_test.dart`)

Mismo arnés y mismo AVD que la línea base. Un frame cuenta como lento si su build **o** su raster supera 16,67 ms.

### 4.1 Corridas finales (HEAD)

| Escenario | Frames | Build prom / p90 / p99 (ms) | Raster prom / p90 / p99 (ms) | Frames > 16 ms |
|---|---:|---|---|---:|
| **Corrida 1** | | | | |
| mapa_pan_zoom | 333 | 2,39 / 4,50 / 36,36 | 22,04 / 39,86 / 67,84 | 201 (60,4 %) |
| mis_reportes_scroll | 933 | 0,72 / 1,30 / 2,21 | 17,95 / 28,74 / 40,58 | 393 (42,1 %) |
| buscar_lugar_scroll | 954 | 0,98 / 1,75 / 4,75 | 18,03 / 28,03 / 36,27 | 393 (41,2 %) |
| admin_denunciados_scroll | 1017 | 0,78 / 1,35 / 3,04 | 15,85 / 18,52 / 31,30 | 296 (29,1 %) |
| admin_usuarios_scroll | 997 | 0,91 / 1,61 / 2,60 | 16,44 / 19,33 / 31,35 | 329 (33,0 %) |
| **Corrida 2** | | | | |
| mapa_pan_zoom | 402 | 2,04 / 4,16 / 23,65 | 16,17 / 28,72 / 35,10 | 157 (39,1 %) |
| mis_reportes_scroll | 954 | 0,70 / 1,25 / 2,13 | 17,80 / 27,10 / 36,80 | 374 (39,2 %) |
| buscar_lugar_scroll | 941 | 0,82 / 1,49 / 3,04 | 17,89 / 28,83 / 33,97 | 398 (42,3 %) |
| admin_denunciados_scroll | 944 | 0,79 / 1,43 / 2,62 | 18,02 / 28,77 / 33,47 | 402 (42,6 %) |
| admin_usuarios_scroll | 954 | 1,02 / 1,79 / 3,01 | 17,18 / 28,34 / 33,27 | 363 (38,1 %) |

### 4.2 A/B en la misma sesión (una corrida por versión, después de 4.1)

| Escenario | Base: raster prom / p99 | Base: > 16 ms | HEAD: raster prom / p99 | HEAD: > 16 ms |
|---|---|---:|---|---:|
| mapa_pan_zoom | 28,51 / 48,57 | 85,1 % | 27,25 / 49,68 | 85,7 % |
| mis_reportes_scroll | 34,07 / 52,95 | 99,2 % | 30,36 / 48,22 | 99,5 % |
| buscar_lugar_scroll | 32,54 / 52,97 | 99,6 % | 31,33 / 52,39 | 98,5 % |
| admin_denunciados_scroll | 32,96 / 50,01 | 99,4 % | 29,88 / 49,41 | 99,7 % |
| admin_usuarios_scroll | 32,85 / 48,75 | 99,8 % | 51,48 / 208,65 | 97,7 % |

Build promedio en el A/B: ≤ 1,04 ms (base) y ≤ 1,21 ms (HEAD) en las listas.

**Lectura.**

- **El build es bajo en las dos versiones y en todas las corridas:** promedio de ~1 ms y p99 de 6 ms o menos en las
  listas. Pasar a `ListView.builder` no cambia ese valor, porque las páginas ya construían rápido. Lo que reduce es la
  cantidad de widgets vivos, y eso no se ve en `FrameTiming`.
- **Todos los frames lentos se deben al raster.** El raster depende del estado de la GPU emulada: durante la sesión
  subió de ~16–18 ms a ~30 ms de promedio con el **mismo** código, y en ese punto base y HEAD dan ~99 % de frames lentos
  por igual.
- **El caso `admin_usuarios` de HEAD en el A/B** (raster p99 208 ms) es un pico aislado del emulador. En 4.1, el mismo
  escenario dio 31–33 ms de p99.

**Por qué no se cumple "0 frames > 16 ms".** En este AVD (`hw.gpu.mode=auto`), el raster promedio ya está en el
umbral de 16,67 ms o por encima, sin importar el widget tree. La meta solo se puede verificar en un dispositivo físico o en un emulador con GPU por hardware, y con este
entorno no se puede validar. No hay evidencia de una regresión: en el A/B, HEAD queda igual o mejor que la base en
raster promedio en 4 de 5 escenarios.

## 5. Tamaño del APK

En la sesión anterior se habían anotado 72,9 MB y 92,3 MB entre dos builds profile, sin una causa identificada. Para
explicarlo se compilaron `3e113e6` y HEAD con los mismos flags, desde un estado limpio. `--analyze-size` solo funciona
con builds release (`"--analyze-size" can only be used on release builds`), así que el análisis por paquete usa
`--release`.

| Build | `3e113e6` | HEAD | Diferencia |
|---|---:|---:|---:|
| `flutter build apk --profile` (todas las ABI) | 74 757 340 B (71,3 MB) | 75 363 262 B (71,9 MB) | +606 KB (+0,8 %) |
| `flutter build apk --release --analyze-size --target-platform android-x64` | 20 485 269 B (19,5 MB) | 20 616 505 B (19,7 MB) | +131 KB (+0,6 %) |

Paquetes del snapshot AOT (release x64) que cambiaron:

| Paquete | Base | HEAD | Δ | Motivo |
|---|---:|---:|---:|---|
| `package:flutter_map` | 127 KB | 197 KB | +70 KB | 7.0.2 → 8.3.2 (incluye el caché de tiles) |
| `package:jni` | — | 37 KB | +37 KB | nuevo transitivo: `flutter_map` 8 depende de `path_provider` |
| `dart:io` | 108 KB | 144 KB | +36 KB | E/S de archivos del caché en disco |
| `package:crowdradar` | 416 KB | 421 KB | +5 KB | código propio |
| `dart:core`, `dart:async`, `dart:typed_data`, otros | — | — | +~12 KB | arrastre de lo anterior |

`pubspec.lock` suma `uuid` y `fixnum` (de `flutter_map` 8) y quita `logger` y `polylabel` (de `flutter_map` 7).

**Conclusión.** El salto de 72,9 → 92,3 MB **no se reproduce**: con builds limpios y los mismos flags, el APK profile
crece un 0,8 % y el release un 0,6 %. Todo ese crecimiento se explica por la subida de `flutter_map` y el caché de tiles.
La cifra de 92,3 MB vino casi seguro de builds con flags o estado distintos, pero esos builds ya no existen y la causa no
se puede confirmar. El APK release x64 que se instala en el emulador pesa 19,7 MB.

## Resumen

**Cumplidas:**

- cobertura de `lib/features` del 97,3 % (meta ≥ 80 %);
- los 4 casos de error en los 23 Cubits;
- `flutter test` sin inestabilidad (3/3);
- las 14 páginas pasadas a builder;
- caché de tiles en disco;
- 4 diagramas del front, 9 en total con el backend.

**No cumplidas:**

- **`flutter test` −20 %:** −14 % de pared con un 18 % más de pruebas. Lo domina la compilación por archivo.
- **Arranque en frío −20 %:** −4 % en el A/B. Lo dominan el proceso Android, el engine y el raster emulado, no el código Dart.
- **0 frames > 16 ms en las listas:** no se puede alcanzar con la GPU emulada. El build está en ~1 ms y todo el exceso es
  raster. Hay que verificarlo en un dispositivo físico.

## Notas de comparabilidad

- **El emulador se degrada durante la sesión.** Los valores absolutos de arranque y de frames cambian según el tiempo que
  lleva encendido el AVD. Por eso las conclusiones de arranque y frames salen de los A/B en la misma sesión, no de la
  comparación con la línea base del 2026-10-18.
- **El backend se re-sembró** con `npm run bench:seed` antes de medir. La base tenía 26 595 reportes acumulados por los
  bench del backend, frente a los ~8600 de la línea base.
- **Durante las mediciones de esta sesión no corrió el bench del backend.**
