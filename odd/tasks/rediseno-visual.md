# rediseno-visual (CRO-88)

Objetivo: aplicar el rediseño visual de `docs/rediseno/design-system.md` sin cambiar la lógica. Rama: `feat/cro-88-rediseno-visual`.
Entrega: `ask-on-risk` (se espera más de 400 líneas: se preguntará la estrategia de cadena antes del primer PR). Pruebas: `flutter test`, `flutter analyze`.

## Specs

- **S1. Regla principal.** «Cambia cómo se ve la app, pero no lo que hace. Se mantienen las mismas pantallas, los mismos datos, las mismas acciones y los mismos textos de botones.» (`design-system.md`)
- **S2. Rediseño limpio.** El usuario pidió: «si se puede hacer un rebranding limipio sin que nada depneda de que una funcion sea correcta». No cambian cubits, estados, repositorios, modelos, rutas ni servicios, salvo lo aprobado en `docs/rediseno/alcance.md` §4.
- **S3. El mapa se queda.** El usuario dijo: «creo q lo del mapa se queda asi pq es la libreria que estamos usando». `flutter_map` y sus tiles no cambian; solo los pines y lo que flota encima.
- **S4. Primero los documentos.** El usuario pidió: «Primero empecemos con los documentos antes de siquiera empezar a tocar codigo apra determinar alcance que agente hara todo y como se lo comunicaran al orquestador». No se escribe código hasta cerrar T1.
- **S5. Lista de control del diseño** (`design-system.md` §9, textual):
  - «El texto tiene un contraste de al menos 4,5:1 (el texto grande de 24 px o más, al menos 3:1).»
  - «Ningún nivel depende solo del color: siempre lleva el medidor y el texto.»
  - «Los elementos tocables miden al menos 44 × 44 px y están separados al menos 8 px.»
  - «No hay emojis como íconos.»
  - «Los textos de los botones son los mismos de hoy.»
  - «`flutter test` pasa completo.»
- **S6. Pantallas** (`design-system.md` §7): inicio de sesión, mapa, detalle del lugar, reportar, validar, historial, perfil y moderación, más la barra inferior. Cada una como en `docs/rediseno/lamina-1-pantallas.png`, dentro de lo que permitan las decisiones D1–D8.
- **S7. Red de seguridad antes del estilo.** Antes de cambiar estilos existen las capturas de referencia de cada pantalla, y las pruebas usan claves en lugar de tipos de widget o íconos (criterio de CRO-88).
- **S8. Fuera de alcance:** el círculo que agrupa lugares, el progreso «1 de 7», el logo y el ícono de la app (`alcance.md` §3).

## Tasks

| ID | Specs | Ruta | Estado | Evidencia / commit |
|---|---|---|---|---|
| T1 Documentos: alcance, plan de agentes y decisiones D1–D8 | S4 | inline (orquestador) | **hecha** | `c3a1012`, `d7bfd40`, `1d7c513` |
| T2 Claves y búsquedas estables en las pruebas | S7, S1 | delegado (escritor A, paralelo con T4) | pendiente | |
| T3 Reloj inyectable | — | — | **cancelada** (D8 = a: datos relativos a la hora real, sin tocar `lib`) | |
| T4 Capturas de referencia de las 8 pantallas, con fechas relativas a la hora real | S7 | delegado (escritor B, paralelo con T2) | pendiente | |
| T5 Pruebas de las reglas de diseño (contraste, 44 px, nivel con medidor y texto) | S5 | delegado; después de T2 | pendiente | |
| T6 Colores, theme e Inter con alias temporales (D7 = B) | S1, S5 | inline | pendiente | |
| T6b Borrar los alias obsoletos al final de F4 | S1 | inline | pendiente | |
| T7 Componentes compartidos: medidor, etiqueta de nivel, pin, íconos de categoría | S5, S3 | inline + verificador; requiere D1 | pendiente | |
| T8-G1 Inicio de sesión | S6 | delegado (paralelo); requiere D2 | pendiente | |
| T8-G2 Mapa, detalle, reportar | S6, S3 | delegado (paralelo); requiere D1, D3, D4 | pendiente | |
| T8-G3 Validar, historial | S6, S2 | delegado (paralelo) | pendiente | |
| T8-G4 Perfil, moderación, navegación | S6 | delegado (paralelo); requiere D5 | pendiente | |
| T9 Verificación final y revisión humana de capturas | S1–S8 | verificador + humano | pendiente | |
| T10 PR hacia `develop` | — | orquestador; el humano decide el merge | pendiente | |

## Log

- **L1 (2026-11-17, pedido original, textual):** «C:\Users\Usuario\Downloads\DESIGN-SYSTEM.md Quiero que ejecutes subagentes de opus para poder hacer un discovery de una especie de rebrandign para el producto. Hagamos el discovery viendo al estimacion de carga laboral en hacer todo el cambio del front end que podria tocar modulos que no deberia y en si si se puede hacer un rebranding limipio sin que nada depneda de que una funcion sea correcta. Usa las buenas practicas que tenemos en ODD para poder hacer esto te dejo imagenes que me dieron para el rebraning [Image #2] [Image #3] aunq creo q lo del mapa se queda asi pq es la libreria que estamos usando . Empieza con la investigacion»
- **L2 (2026-11-17):** El discovery (3 exploradores Opus de solo lectura) concluyó:
  - El rediseño es viable sin tocar la lógica.
  - Toca entre 30 y 40 archivos, no 4, porque hay cero `Theme.of`.
  - Unas 690 pruebas de lógica no se ven afectadas, y unas 460 pruebas de pantalla son frágiles.
  - No hay capturas de referencia.
  - Hay 8 decisiones abiertas.
  - La estimación es de 13 a 17 días de una persona.
- **L3 (2026-11-17, textual):** «Armate un ticket en el linear de crowd radar metele lo que deberia hacer y crea un nueva rama con todo lo que tenemos actualmente en develop par aque puedas trabajar ahi. Primero empecemos con los documentos antes de siquiera empezar a tocar codigo apra determinar alcance que agente hara todo y como se lo comunicaran al orquestador»
- **L4 (2026-11-17):**
  - Se creó CRO-88: 8 puntos, responsable Walter, fecha límite 2026-11-20.
  - Se creó la rama `feat/cro-88-rediseno-visual` desde `develop` @ `12e14d4`, sincronizada con el remoto.
  - Se escribieron `docs/rediseno/alcance.md` y `docs/rediseno/plan-agentes.md`.
  - Se copiaron al repositorio la propuesta y las láminas.
  - Riesgo abierto: la fecha del viernes no alcanza para la estimación completa.
  - Siguiente paso: el humano resuelve D1–D8 y el alcance del viernes.
- **L5 (2026-11-17, decisiones del usuario, textual):** «Sis e muestrna los puntos en D5 D6 ME PARECE BIEN [...] LOS DESDE D1 A D3 APROBADOS» · «Camoscon la B en la D4» · «Vamos con a» (D8).
  - Resultado:
    - D1, D2, D3 y D6 aprobadas como se recomendó.
    - D4 = b: nota sin número.
    - D5 = sí: se muestran los puntos.
    - D8 = a: fechas relativas, sin tocar `lib`.
  - Corrección del orquestador: `haceCuanto()` ya aceptaba `ahora` (`formato_fecha.dart:2`), así que D8 nunca requería cambiar ese archivo.
  - T3 se cancela.
  - Pendiente: D7.
- **L6 (2026-11-17, textual):** «vamos con B».
  - D7 = B: alias temporales `@Deprecated` que se borran antes de cerrar.
  - Criterio de cierre: `flutter analyze` sin avisos de obsoletos.
  - Siguiente paso: acordar qué entra hasta el 2026-11-20.
- **L7 (2026-11-17, textual):** «Todo el ticket para el viernes».
  - Alcance del viernes: F1 a F5 completas.
  - Calendario comprimido:
    - martes 17: F1
    - miércoles 18: F2 y F3
    - jueves 19: F4 en paralelo
    - viernes 20: T6b, T9 y PR
  - Riesgo aceptado por el usuario: la revisión humana de capturas del viernes es el cuello de botella.
  - T1 cerrada.
- **L8 (2026-11-17):** Base de pruebas en la rama, con Flutter 3.47.9: `flutter test` → **1372 pasan, 0 fallan**. Se lanzan T2 y T4 en paralelo.
