# Rediseño visual: plan de trabajo y agentes (CRO-88)

Este documento dice quién hace cada fase, en qué orden y cómo le reporta cada agente al orquestador. El alcance está en [`alcance.md`](alcance.md) y el seguimiento de tareas en [`../../odd/tasks/rediseno-visual.md`](../../odd/tasks/rediseno-visual.md).

## 1. Roles

| Rol | Quién | Hace | No hace |
|---|---|---|---|
| **Humano** | Walter | Resuelve las decisiones D1–D8, aprueba las capturas de referencia y las finales, decide push, PR y merge | — |
| **Orquestador** | Sesión principal de Claude Code (Opus) | Mantiene el documento de seguimiento y su copia en Engram; reparte tareas; revisa cada diff contra la superficie autorizada; corre la suite completa al final de cada fase; hace los commits; actualiza CRO-88 | No decide producto; no aprueba capturas en lugar del humano |
| **Explorador** | Subagente de solo lectura (Opus) | Mapea código cuando el orquestador necesita decidir algo y no le alcanza una lectura corta | No edita archivos |
| **Escritor** | Subagente `general-purpose` (Opus), uno por unidad | Implementa una tarea dentro de su superficie de edición, con prueba primero cuando aplica | No sale de su superficie; no hace commit ni push; no toma decisiones de producto; no corre formateadores sobre todo el repo |
| **Verificador** | Subagente independiente (Opus), distinto del escritor | Revisa las especificaciones S# una por una contra el diff y las capturas; devuelve un veredicto por S# | No corrige; solo reporta |

## 2. Fases y orden

```text
F0 Documentos (orquestador)            ── espera D1–D8 del humano
F1 Red de seguridad                     T2 ∥ T4  →  T5        (T3 cancelada por D8)
F2 Colores y theme                      T6
F3 Componentes compartidos              T7  →  verificador
F4 Pantallas (4 escritores en paralelo) T8-G1 ∥ T8-G2 ∥ T8-G3 ∥ T8-G4  →  suite completa
F5 Cierre                               T9 verificador + revisión humana de capturas  →  T10 PR
```

| Tarea | Fase | Ruta | Por qué esa ruta |
|---|---|---|---|
| T1 Documentos y decisiones | F0 | Orquestador | Es planificación, sin código |
| T2 Claves y búsquedas estables en las pruebas | F1 | Escritor A | En paralelo con T4, sin archivos compartidos |
| T3 Reloj inyectable | — | — | Cancelada: D8 = a |
| T4 Capturas de referencia | F1 | Escritor B | En paralelo con T2; solo archivos nuevos de prueba, con fechas relativas a la hora real |
| T5 Pruebas de las reglas del diseño | F1 | Escritor | Necesita T2 |
| T6 Colores, theme e Inter | F2 | Orquestador | Una sola unidad pequeña |
| T7 Componentes compartidos | F3 | Orquestador + verificador | Lo usan 12 pantallas: riesgo alto |
| T8-G1…G4 Pantallas | F4 | 4 escritores en paralelo | Cuatro grupos sin archivos compartidos |
| T9 Verificación final | F5 | Verificador + humano | El cambio es visual y las pruebas no lo ven solas |
| T10 PR | F5 | Orquestador | El humano decide el merge |

### Grupos de pantallas para F4 (superficies separadas)

| Grupo | Pantallas | Superficie de edición |
|---|---|---|
| G1 | Inicio de sesión | `lib/features/auth/login/**`, `test/features/auth/login_page_test.dart` |
| G2 | Mapa, detalle, reportar | `lib/features/lugares/**`, `lib/features/exploracion/explorar/filtros_mapa.dart`, `lib/features/reportes/reportar/**`, sus pruebas en `test/features/{lugares,exploracion,reportes}/**` |
| G3 | Validar, historial | `lib/features/validacion/pendientes/**` (solo widgets y páginas), `lib/features/analitica/**` (solo widgets y páginas), sus pruebas |
| G4 | Perfil, moderación, navegación | `lib/features/perfil/ver/**`, `lib/features/moderacion/denunciados/**`, `lib/layout/**`, sus pruebas |

Los archivos compartidos (`lib/theme/**`, `lib/core/widgets/**`, `lib/core/map/**`, `pubspec.yaml` y las capturas de referencia) **no** se tocan en F4. Si un grupo necesita un cambio ahí, devuelve `blocked` y lo hace el orquestador al final.

En G3, los cubits y estados (`*_cubit.dart`, `*_state.dart`) quedan fuera de la superficie.

## 3. Cómo el orquestador le pasa una tarea a un agente

El orquestador **nunca resume** las especificaciones: las referencia. Cada encargo lleva esta forma:

```markdown
Spec: odd/tasks/rediseno-visual.md, T<n>, S<a>-S<b>
Lee ese documento hasta `## Log` antes de tocar nada.
Contexto: docs/rediseno/alcance.md (decisiones resueltas), docs/rediseno/design-system.md, láminas en docs/rediseno/.

## Allowed edit surfaces
<rutas exactas o globs acotados, una por línea>

## Verification
- flutter test <pruebas enfocadas>
- flutter test   (solo si el orquestador lo pide)
- flutter analyze

## Known environmental failures
<pruebas que ya fallan en la base, o "ninguna">

## Reglas
- Primero la prueba en rojo cuando haya una prueba ejecutable y un resultado claro; después en verde.
- Sin commits, sin push, sin formateadores sobre todo el repo (solo `dart format` en tus archivos).
- No cambies textos visibles, cubits, estados, repositorios, modelos ni rutas.
- Si algo exige una decisión de producto o un archivo fuera de tu superficie: detente y devuelve `blocked` con la pregunta.
- Artefactos (código, comentarios, nombres de pruebas) en inglés salvo la convención del archivo; los textos de la interfaz quedan como están.
```

## 4. Cómo el agente le responde al orquestador

Todo agente termina con este sobre y nada más:

```markdown
## Resultado
estado: done | partial | blocked
tarea: T<n>
specs cubiertas: S<a>, S<b>
specs no cubiertas: S<c> (motivo)

## Archivos cambiados
- <ruta> — <qué y por qué>

## Verificación
- `<comando>`: <resultado observado, con números>
- RED: <prueba> falló con <mensaje>   (si aplica)
- GREEN: <prueba> pasa                (si aplica)

## Desvíos y hallazgos
<lo que no salió como decía el plan, o "ninguno">

## Preguntas para el orquestador
<solo si estado = blocked o partial>

## Key Learnings
1. <hecho reutilizable>
```

Reglas del sobre:

- `done` solo con todas las verificaciones corridas y observadas. Si una falla, es `partial`.
- Nunca se inventa una evidencia RED o GREEN.
- Una pregunta de producto **siempre** es `blocked`. El agente no elige por el humano.

## 5. Qué hace el orquestador con la respuesta

1. Compara el diff con la superficie autorizada. Si algo queda afuera, lo rechaza.
2. Vuelve a correr **una** verificación reportada (control puntual).
3. Si la respuesta es `blocked`, lleva la pregunta al humano y se detiene en esa tarea.
4. Marca la tarea en el documento de seguimiento, actualiza la copia en Engram y hace el commit de la unidad (Conventional Commits, sin coautoría de IA).
5. Al cerrar cada fase: suite completa una vez y comentario breve en CRO-88.

## 6. Verificación

- **Correcciones:** los bloqueos del verificador tienen una sola ronda de corrección y un solo rechequeo de esos bloqueos. Si siguen, pasan al humano como "Necesita tu decisión".
- **Capturas:** se generan y comparan siempre en la misma máquina (Windows de desarrollo) hasta definir CI. El humano revisa las diferencias una por una antes de aceptarlas.
- **Fin de cada fase:** `flutter analyze` y `flutter test` completos.
