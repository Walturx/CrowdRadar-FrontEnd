# Rediseño visual: alcance (CRO-88)

- **Ticket:** [CRO-88](https://linear.app/crowdradar/issue/CRO-88/aplicar-el-rediseno-visual-de-crowdradar-en-la-app)
- **Rama:** `feat/cro-88-rediseno-visual` (sale de `develop` @ `12e14d4`)
- **Propuesta de diseño:** [`design-system.md`](design-system.md), [`lamina-1-pantallas.png`](lamina-1-pantallas.png), [`lamina-2-antes-y-despues.png`](lamina-2-antes-y-despues.png)
- **Plan de trabajo y agentes:** [`plan-agentes.md`](plan-agentes.md)
- **Seguimiento (ODD):** [`../../odd/tasks/rediseno-visual.md`](../../odd/tasks/rediseno-visual.md)

**Estado:** borrador. No se toca código hasta que las decisiones de la sección 4 estén resueltas o marcadas como "se difiere".

---

## 1. Regla principal

> Cambia cómo se ve la app, pero no lo que hace. Se mantienen las mismas pantallas, los mismos datos, las mismas acciones y los mismos textos de botones.
> (`design-system.md`)

En la práctica:

- **No cambian** cubits, estados, repositorios, modelos, rutas ni servicios. Si algo del diseño lo exige, va a la sección 4 como decisión y solo entra si se aprueba.
- **La librería del mapa se queda.** `flutter_map` y sus tiles no cambian. Solo cambian los pines y lo que flota encima del mapa.
- **Se cambia la vista, no la lógica.** Los cambios viven en `lib/theme`, `lib/core/widgets`, `lib/layout` y en los widgets de cada pantalla.

## 2. Qué entra

| Área | Qué cambia | Archivos principales |
|---|---|---|
| Colores y theme | Paleta nueva, tipografía Inter (incluida en la app, no descargada), botones, campos, tarjetas, barra inferior, hojas | `lib/theme/app_colors.dart`, `lib/theme/app_theme.dart`, `pubspec.yaml`, `assets/fonts/` |
| Componentes compartidos | Medidor de barras (nuevo); etiqueta de nivel con `fg`/`bg`/`dot`; pin en forma de gota; íconos de categoría en lugar de emojis | `lib/core/widgets/chip_saturacion.dart`, `pin_saturacion.dart`, widget nuevo del medidor, `lib/features/lugares/categoria_presentacion.dart` |
| Adaptador del mapa | Tamaño del marcador y estilo del punto de ubicación. Solo la parte visual del `Marker` | `lib/core/map/flutter_map_adapter.dart` |
| Inicio de sesión | Subtítulo, etiquetas visibles, campos nuevos | `lib/features/auth/login/login_page.dart` |
| Mapa | Mapa a pantalla completa, buscador flotante, chips de filtro con medidor | `lib/features/lugares/mapa/*`, `lib/features/exploracion/explorar/filtros_mapa.dart` |
| Detalle del lugar | Tarjeta grande del nivel; «Reportar saturación» como botón principal | `lib/features/lugares/detalle/detalle_lugar_page.dart` |
| Reportar | Opciones grandes con medidor y check | `lib/features/reportes/reportar/reportar_sheet.dart` |
| Validar | Pregunta «¿Está así ahora mismo?» y botones con ícono | `lib/features/validacion/pendientes/*` (solo widgets) |
| Historial | Barras con el color `dot`, resumen arriba, acciones como filas | `lib/features/analitica/historial/*`, `lib/features/analitica/widgets/*` |
| Perfil | Iniciales, tarjeta de tier, cuadrícula de datos, lista de acciones | `lib/features/perfil/ver/*` |
| Moderación | Filas compactas | `lib/features/moderacion/denunciados/*` |
| Navegación | Píldora activa en la barra inferior | `lib/layout/cr_bottom_nav.dart`, `lib/layout/admin_layout.dart` |
| Red de seguridad | Claves en las pruebas, capturas de referencia, pruebas de accesibilidad | `test/**` (D8: no se toca `lib`) |

Las pantallas que no aparecen en las láminas (favoritos, alertas, registro, recuperar contraseña, etc.) **solo** reciben los colores y el theme nuevos. Tienen que compilar y verse coherentes, pero no se rediseñan.

## 3. Qué no entra

- La librería del mapa y sus tiles.
- El **círculo que agrupa lugares** en el mapa. Hoy no existe agrupación: es una función nueva y va en otro ticket.
- El **progreso «1 de 7»** en Validar. `PendientesCubit` no guarda el total (`pendientes_cubit.dart`), así que mostrarlo obliga a cambiar el estado. Va en otro ticket si se aprueba.
- El logo y el ícono de la app.
- Cambios de backend.

## 4. Decisiones pendientes

Cada decisión necesita respuesta antes de la fase que bloquea. "Recomendación" es la propuesta técnica; quien decide es producto o diseño.

| ID | Decisión | Evidencia | Recomendación | Bloquea | Decidió | Resultado |
|---|---|---|---|---|---|---|
| D1 | ¿«Sin información» pasa a «Sin reportes», y «Todos» a «Todos los niveles»? | `chip_saturacion.dart:23`, `filtros_mapa.dart:102-121`; unas 40 pruebas buscan los nombres de los niveles | Mantener los textos de hoy (lo pide la regla principal) | T7, T8 | Walter, 2026-11-17 | **Aprobada:** se mantienen «Sin información» y «Todos» |
| D2 | ¿El error del login pasa de snackbar a un aviso dentro del formulario? | `login_page.dart:57-73`; `login_page_test.dart:64` | Hacerlo solo en el login, con el mismo mensaje | T8-G1 | Walter, 2026-11-17 | **Aprobada:** aviso dentro del formulario, solo en el login |
| D3 | ¿La leyenda del mapa se integra en los chips de filtro? | `map_page.dart:235-239` muestra «Sin información», que no es un filtro | Mantener una leyenda mínima para «Sin información» | T8-G2 | Walter, 2026-11-17 | **Aprobada:** chips con medidor y una leyenda mínima para «Sin información» |
| D4 | ¿Se muestra la nota «Puedes reportar el mismo lugar cada 30 minutos»? | La regla solo vive en el servidor (`REPORTE_EN_ESPERA`) | No escribir «30» en la app; dejarlo para cuando la API lo devuelva | T8-G2 | Walter, 2026-11-17 | **Opción b:** nota sin número, «Puedes volver a reportar este lugar más tarde» |
| D5 | ¿Se muestran los puntos en la tarjeta del tier? | `tarjeta_tier.dart:6-8` los oculta a propósito; `Usuario.puntos` existe | Decisión de producto; el dato ya está | T8-G4 | Walter, 2026-11-17 | **Sí:** la tarjeta del tier muestra `Usuario.puntos` |
| D6 | ¿Qué colores usan las escalas de validación y confiabilidad? | `chip_estado_validacion.dart:13-16`, `insignia_confiabilidad.dart:15-18` usan `success`/`warning`/`danger` | Pasarlas a neutros más ícono para no confundirlas con los niveles | T6 | Walter, 2026-11-17 | **Aprobada:** neutros con ícono |
| D7 | ¿Se mantienen alias para los colores que la paleta borra? | `secondary`, `success`, `warning`, `onPrimaryMuted` y `borderNav` se usan en 11 archivos | Sí: alias marcados como obsoletos, y se migran sus usos en el mismo ticket | T6 | | Pendiente |
| D8 | ¿Cómo se fija la hora en las capturas de referencia? | `haceCuanto(fecha, {DateTime? ahora})` ya acepta la hora (`formato_fecha.dart:2`), pero las pantallas no se la pasan. Las pruebas actuales arman fechas relativas a la hora real (`detalle_lugar_page_test.dart:44`) | a) Datos relativos a la hora real, sin tocar `lib`; pasar a b) (hora controlable desde las pantallas) solo si alguna captura falla de forma intermitente | T4 | Walter, 2026-11-17 | **Opción a:** no se toca `lib`; T3 se cancela |

## 5. Riesgos conocidos

- **Plazo.** La fecha límite del ticket es el viernes 2026-11-20. La estimación del discovery es de 13 a 17 días de una persona. Los agentes en paralelo acortan la escritura, pero no las decisiones ni la revisión humana de las capturas. Hay que decidir si el viernes cierra todo el ticket o solo una parte (por ejemplo, la red de seguridad, los colores y los componentes).
- **Las pruebas no ven el diseño.** Unas 460 pruebas de pantalla buscan por tipo de widget, ícono o emoji, y ninguna compara capturas. Por eso la red de seguridad va primero.
- **Capturas según la plataforma.** Las capturas de referencia salen distintas en Windows y en Linux. Se generan y comparan siempre en la misma máquina. Además, sin cargar la fuente en la prueba, Flutter dibuja el texto como cajas.
- **Colores que cambian de valor sin cambiar de nombre.** `danger`, `bg` y `textMuted` compilan igual con valores nuevos, pero cambian errores, favoritos y estado de la cuenta.
- **Texto más grande.** Inter 27/800 y 24/800 pueden desbordar en las pruebas de accesibilidad al 130 % (ACC-APP-01 a 07).

## 6. Fuentes del discovery

Tres exploradores de solo lectura (2026-11-17): colores y theme, acoplamiento por pantalla, y red de pruebas. Las conclusiones están en la descripción de CRO-88 y en la memoria del proyecto (`Rebrand discovery: blast radius and safety net`).
