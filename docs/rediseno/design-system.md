# CrowdRadar: sistema de diseño (propuesta)

Estado: **propuesta**, aún no está en el código de la app.

Las imágenes de referencia son `Lamina-1-pantallas.png` y `Lamina-2-antes-y-despues.png`. Las pantallas de ejemplo están en HTML: `html/app.html` y `html/estilos.css`.

**Regla principal.** Cambia cómo se ve la app, pero no lo que hace. Se mantienen las mismas pantallas, los mismos datos, las mismas acciones y los mismos textos de botones. Así las pruebas de `flutter test` y las capturas del informe siguen valiendo.

---

## 1. Principios

1. **El nivel de saturación es lo más importante.** En cada pantalla donde aparece un lugar, su nivel es lo primero que se lee.
2. **El color nunca va solo.** Cada nivel se muestra con tres cosas a la vez: el color, un medidor de barras (1, 2 o 3 llenas) y su nombre en texto. Esto cumple la norma de accesibilidad WCAG 1.4.1.
3. **El verde, el ámbar y el rojo se usan solo para los niveles.** El resto de la interfaz es neutro, con el azul de la marca.
4. **Una acción principal por pantalla.** Esa acción va en un botón relleno azul; las demás van en botones con borde o en filas de lista.
5. **Todo se puede tocar con el dedo.** Ningún elemento tocable mide menos de 44 × 44 px.

---

## 2. Color

### 2.1 Marca y neutros

| Token | Hex | Uso |
|---|---|---|
| `brand` | `#1A3C8F` | Botón principal, elemento activo, enlaces. Es el mismo azul del logo y del `AppColors.primary` actual |
| `brand-700` | `#142F72` | Botón principal al presionarlo |
| `brand-100` | `#DCE4F7` | Fondo del ítem activo de la barra inferior, bordes de botones secundarios |
| `brand-50` | `#EEF2FB` | Fondo de los íconos en las filas, botón tonal |
| `ink` | `#0F172A` | Texto principal |
| `ink-2` | `#334155` | Texto de etiquetas y chips |
| `muted` | `#5B6B80` | Texto secundario y subtítulos |
| `line` | `#E2E8F0` | Bordes y separadores |
| `bg` | `#F5F7FB` | Fondo de las pantallas. Reemplaza al verde pálido `#F0F8E8` |
| `surface` | `#FFFFFF` | Tarjetas, campos, barra inferior y hojas |

### 2.2 Niveles de saturación

| Nivel | Texto (`fg`) | Fondo (`bg`) | Pin y gráfico (`dot`) | Barras | Descripción |
|---|---|---|---|---|---|
| Tranquilo | `#15803D` | `#DCFCE7` | `#22C55E` | 1 de 3 | Hay espacio, poca gente |
| Moderado | `#B45309` | `#FEF3C7` | `#F59E0B` | 2 de 3 | Algo concurrido |
| Saturado | `#B91C1C` | `#FEE2E2` | `#EF4444` | 3 de 3 | Lleno, mucha gente |
| Sin reportes | `#5B6B80` | `#F1F5F9` | `#94A3B8` | 0 de 3 | Sin reportes recientes |

Contraste medido del texto sobre su fondo:
- Tranquilo: 4,57:1.
- Moderado: 4,51:1.
- Saturado: 5,30:1.
- Sin reportes: 4,97:1.

Sobre blanco, todos superan 5:1. El gris secundario `muted` da 5,44:1 sobre blanco y 5,07:1 sobre `bg`. Todo cumple el mínimo de 4,5:1 de la norma WCAG AA.

### 2.3 Estados del sistema

| Uso | Color |
|---|---|
| Error y acciones peligrosas (cerrar sesión, rechazar) | texto `#B91C1C` sobre fondo `#FEE2E2`; borde `#FBCACA` |
| Éxito (estado ACTIVO) | `#15803D` con un punto `#22C55E` |
| Ubicación del usuario en el mapa | `#2563EB`, con un halo del mismo color al 18 % |

---

## 3. Tipografía

La letra es **Inter**, con cifras de ancho fijo (`tabular-nums`) en números y horas.

| Estilo | Tamaño / peso | Interlineado | Dónde se usa |
|---|---|---|---|
| Display | 34 / 800, tracking −0,03em | 1,0 | El nivel grande en el detalle del lugar |
| Título de pantalla grande | 27 / 800, tracking −0,025em | 1,2 | «Iniciar sesión» |
| Título de lugar | 24 / 800, tracking −0,02em | 1,2 | El nombre del lugar en el detalle y en validar |
| Título de hoja inferior | 21 / 800 | 1,25 | «¿Qué tan lleno está?» |
| Título de la barra superior | 18 / 700 | 1,3 | Encabezados de pantalla |
| Cuerpo | 15,5 / 400 a 600 | 1,45 | Textos y valores |
| Botón | 16 / 600 | 1 | Todos los botones |
| Secundario | 14 a 14,5 / 400 | 1,45 | Subtítulos y descripciones |
| Etiqueta | 12,5 a 13,5 / 500 a 600 | 1,3 | Chips y etiquetas de campos |
| Título de sección | 12 / 600, MAYÚSCULAS, tracking 0,06em | 1,3 | «INFORMACIÓN», «6 REPORTES POR REVISAR» |

Ningún texto mide menos de 11,5 px. Ese tamaño mínimo es solo para los rótulos del eje del gráfico.

---

## 4. Espaciado, radios y sombras

**Espaciado.** Se usa una escala de 4 px: `4 · 8 · 10 · 12 · 14 · 16 · 20 · 24`.
- Margen lateral de las pantallas: **16 px** (24 px en el inicio de sesión).
- Separación entre tarjetas: 10 a 12 px.
- Relleno interno de las tarjetas: 14 a 20 px.

**Radios.**

| Token | Valor | Uso |
|---|---|---|
| `r-sm` | 10 px | Elementos pequeños |
| `r-md` | 14 px | Botones, campos y avisos |
| `r-lg` | 20 px | Tarjetas y grupos de filas |
| `r-xl` | 28 px | Tarjeta del nivel, tarjeta del tier, hojas inferiores (solo las esquinas de arriba) |
| Pill | la mitad de la altura | Chips, buscador y etiquetas de nivel |

**Sombras.**

| Token | Valor | Uso |
|---|---|---|
| `shadow-1` | `0 1px 2px rgba(15,23,42,.06), 0 1px 1px rgba(15,23,42,.04)` | Tarjetas y chips |
| `shadow-2` | `0 8px 24px rgba(15,23,42,.10), 0 2px 6px rgba(15,23,42,.06)` | Elementos que flotan sobre el mapa |
| `shadow-sheet` | `0 -12px 32px rgba(15,23,42,.16)` | Hojas inferiores |
| Botón principal | `0 6px 16px rgba(26,60,143,.28)` | Solo el botón relleno azul |

---

## 5. Componentes

### Botones (alto 52, radio 14)

| Tipo | Estilo | Uso |
|---|---|---|
| Principal | Fondo `brand`, texto blanco, sombra de botón | La acción principal: «Iniciar sesión», «Reportar saturación», «Enviar reporte», «Confirmar» |
| Secundario | Fondo blanco, texto `brand`, borde 1,5 px `brand-100` | «Ver historial» |
| Tonal | Fondo `brand-50`, texto `brand` | Acciones de apoyo |
| Peligro | Fondo blanco, texto `#B91C1C`, borde `#FBCACA` | «Rechazar» |

Los botones pueden llevar un ícono de 19 px a la izquierda, separado del texto por 10 px.

### Campos de texto (alto 54, radio 14, borde 1,5 px)
- La etiqueta va siempre visible arriba del campo (13,5 / 600, color `ink-2`), nunca solo como texto de ejemplo dentro del campo.
- Llevan un ícono de 19 px a la izquierda, en color `#94A3B8`.
- **Con error:** borde `#F3A6A6`, fondo `#FFFBFB`, y un aviso rojo arriba del formulario. El mensaje es el mismo que hoy sale en el snackbar.

### Etiqueta de nivel (alto 28, pill)
Lleva el medidor de barras más el nombre del nivel, con los colores `fg` y `bg` de su nivel.

### Medidor de barras
- Son 3 barras de 4 px de ancho y de 6, 10 y 14 px de alto, separadas 2 px.
- Las barras llenas tienen opacidad 1 y las vacías 0,25.
- El tamaño se ajusta según el lugar donde aparece: el medidor grande del detalle mide 34 px de alto.

### Pin del mapa
- Es una gota de 34 px (26 px en la versión pequeña) con borde blanco de 2,5 px, rellena con el color `dot` del nivel. Dentro lleva el medidor en blanco.
- Debajo puede llevar el nombre del lugar en una etiqueta blanca (11,5 / 600).
- **Grupo de lugares:** un círculo de 40 px en color `brand`, con el número de lugares en blanco.

### Chips de filtro (alto 36, pill)
- Sin elegir: fondo blanco con `shadow-1`.
- Elegido: fondo `brand` y texto blanco. En la fila de niveles, el chip «Todos los niveles» elegido usa fondo `ink`.
- Los chips de nivel llevan su medidor, así que también sirven de leyenda.

### Tarjetas y filas de lista
- **Tarjeta:** fondo blanco, radio 20, borde `line` y `shadow-1`.
- **Fila:** alto mínimo de 56 px. Lleva un ícono de 36 px con fondo `brand-50` y radio 11, después el texto y al final una flecha (chevron) `#94A3B8` si lleva a otra pantalla.
- **Fila de peligro** (Cerrar sesión): ícono y texto en rojo.

### Hoja inferior (reportar)
- Radio de 28 arriba, con una asa de 40 × 4 px.
- Detrás, un velo negro azulado al 45 %.
- **Opciones:** tarjetas con borde de 1,5 px.
- **Opción elegida:** borde con el color `dot` del nivel, un halo de 4 px y un check dentro del círculo.

### Barra de navegación inferior
- Alto de 88 px (incluye el espacio de la barra de gestos) y fondo blanco con borde superior.
- El ítem activo lleva una píldora de 60 × 30 en `brand-100`, con el ícono y el texto en `brand` y en negrita.
- Se mantienen los mismos ítems de hoy: Mapa, Validar, Favoritos y Perfil. En el panel del administrador: Reportes y Usuarios.

### Gráfico del historial
- Muestra 24 barras, una por hora, con radio de 4 arriba.
- Las horas con reportes usan el color `dot` de su nivel. Las horas sin reportes van como una barra corta de 6 px en `line`.
- La hora actual lleva un contorno de 2 px en `ink`.
- La leyenda usa cuadritos de 10 px.

---

## 6. Íconos

- Se usa **Lucide**, con trazo de 2 px y tamaño de 20 px (en las filas, 18 px).
- No se usan emojis como íconos. Hoy `emojiCategoria()` usa 🛍️, 🌳, etc.

| Categoría | Ícono |
|---|---|
| Parque | `trees` |
| Centro comercial | `shopping-bag` |
| Mercado | `store` |
| Transporte | `bus` |
| Plaza | `landmark` |
| Playa | `umbrella` |
| Otro | `map-pin` |

En Flutter se pueden usar los Material Symbols (Outlined) equivalentes, o el paquete `lucide_icons_flutter`.

---

## 7. Pantallas (qué cambia en cada una)

| Pantalla | Cambio |
|---|---|
| Inicio de sesión | Subtítulo explicativo, etiquetas sobre los campos y el error arriba del formulario (mismo mensaje) |
| Mapa | Mapa a pantalla completa, buscador flotante, filtros de nivel que sirven de leyenda y pines con medidor |
| Detalle del lugar | Tarjeta grande del nivel (nivel, descripción, hace cuánto se actualizó y cuántos reportes). «Reportar saturación» pasa a ser el botón principal |
| Reportar | Opciones grandes con medidor y check. Una nota recuerda la regla de 30 minutos |
| Validar | Pregunta «¿Está así ahora mismo?», barra de avance y botones Rechazar y Confirmar con ícono |
| Historial | Las 24 horas visibles, un resumen arriba y «Comparar periodos» y «Mejor horario» como filas de lista |
| Perfil | Iniciales, tarjeta de tier con los puntos que manda la API, datos en una cuadrícula y acciones en una lista |
| Moderación | Filas compactas con el nivel, las denuncias y el botón «Revisar» |

---

## 8. Cómo pasarlo a Flutter

Los cambios se concentran en tres lugares:
- `lib/theme/app_colors.dart`
- `lib/theme/app_theme.dart`
- en `lib/core/widgets`, los archivos `chip_saturacion.dart` y `pin_saturacion.dart`

Antes de unir los cambios hay que correr `flutter test`, porque algunas pruebas de widget buscan textos o íconos concretos.

```dart
// lib/theme/app_colors.dart (propuesta)
class AppColors {
  const AppColors._();

  static const Color primary = Color(0xFF1A3C8F);      // brand
  static const Color primaryPressed = Color(0xFF142F72);
  static const Color primaryContainer = Color(0xFFDCE4F7);
  static const Color primarySoft = Color(0xFFEEF2FB);
  static const Color bg = Color(0xFFF5F7FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color text = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF334155);
  static const Color textMuted = Color(0xFF5B6B80);
  static const Color border = Color(0xFFE2E8F0);
  static const Color danger = Color(0xFFB91C1C);
  static const Color dangerBg = Color(0xFFFEE2E2);

  // Saturation levels: text, background and pin/chart.
  static const Color tranquilo = Color(0xFF15803D);
  static const Color tranquiloBg = Color(0xFFDCFCE7);
  static const Color tranquiloDot = Color(0xFF22C55E);
  static const Color moderado = Color(0xFFB45309);
  static const Color moderadoBg = Color(0xFFFEF3C7);
  static const Color moderadoDot = Color(0xFFF59E0B);
  static const Color saturado = Color(0xFFB91C1C);
  static const Color saturadoBg = Color(0xFFFEE2E2);
  static const Color saturadoDot = Color(0xFFEF4444);
  static const Color sinDatos = Color(0xFF5B6B80);
  static const Color sinDatosBg = Color(0xFFF1F5F9);
  static const Color sinDatosDot = Color(0xFF94A3B8);
}
```

**Medidas para `app_theme.dart`:**
- `ElevatedButton`: `minimumSize: Size.fromHeight(52)`, radio 14, texto 16 / w600.
- `OutlinedButton`: borde 1,5 px con `primaryContainer`.
- `InputDecorationTheme`: radio 14, borde 1,5 px con `border`; al enfocar, `primary`.
- `CardTheme`: radio 20, `elevation: 0`, borde con `border`.
- `NavigationBarTheme`: `indicatorColor: primaryContainer`, alto 64 más el espacio inferior seguro.
- `fontFamily: 'Inter'`: hay que agregar la letra en `pubspec.yaml`, o usar el paquete `google_fonts`.

---

## 9. Lista de control antes de entregar

- [ ] El texto tiene un contraste de al menos 4,5:1 (el texto grande de 24 px o más, al menos 3:1).
- [ ] Ningún nivel depende solo del color: siempre lleva el medidor y el texto.
- [ ] Los elementos tocables miden al menos 44 × 44 px y están separados al menos 8 px.
- [ ] No hay emojis como íconos.
- [ ] Los textos de los botones son los mismos de hoy.
- [ ] `flutter test` pasa completo.
