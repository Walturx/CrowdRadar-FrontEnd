import 'package:flutter/material.dart';

import '../../../core/models/nivel_saturacion.dart';
import '../../../core/models/tier_usuario.dart';
import '../../../core/models/validacion.dart';
import '../../../core/widgets/chip_saturacion.dart';
import '../../../core/widgets/medidor_nivel.dart';
import '../../../theme/app_colors.dart';
import 'insignia_confiabilidad.dart';
import 'tier_compacto.dart';

// S24: the pieces of a report card, shared by the Validar card and the report
// detail so both screens read as one design and cannot drift apart.

/// `shadow-1` of the design system (cards and chips).
const List<BoxShadow> _sombra1 = [
  BoxShadow(color: Color(0x0F0F172A), offset: Offset(0, 1), blurRadius: 2),
  BoxShadow(color: Color(0x0A0F172A), offset: Offset(0, 1), blurRadius: 1),
];

/// The card a report sits in: white, radius 20, `line` border and `shadow-1`
/// (design-system §5).
class TarjetaReporte extends StatelessWidget {
  final List<Widget> children;

  const TarjetaReporte({super.key, required this.children});

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('tarjeta-reporte-superficie'),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.border),
      boxShadow: _sombra1,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );
}

/// The place name (24 / 800), with an optional small label above it, an
/// optional line below it ("categoría · distancia"), an optional [estado]
/// beside it (the validation state chip of the detail, the time pill of
/// Validar) and, when the author's tier is known, the "Reportado por" row
/// under it all (S25), so both screens put it in the same place.
class EncabezadoReporte extends StatelessWidget {
  final String lugar;
  final String? antetitulo;
  final String? subtitulo;
  final Widget? estado;

  /// Null (older backend or unknown value) hides the "Reportado por" row.
  final TierUsuario? tierAutor;

  const EncabezadoReporte({
    super.key,
    required this.lugar,
    this.antetitulo,
    this.subtitulo,
    this.estado,
    this.tierAutor,
  });

  @override
  Widget build(BuildContext context) {
    final nombre = Text(
      lugar,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.48,
        height: 1.2,
        color: AppColors.text,
      ),
    );
    final estado = this.estado;
    final antetitulo = this.antetitulo;
    final subtitulo = this.subtitulo;
    final tierAutor = this.tierAutor;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (antetitulo != null) ...[
          Text(
            antetitulo,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 6),
        ],
        if (estado == null)
          nombre
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: nombre),
              const SizedBox(width: 8),
              estado,
            ],
          ),
        if (subtitulo != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitulo,
            style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
          ),
        ],
        if (tierAutor != null) ...[
          const SizedBox(height: 12),
          FilaAutor(tier: tierAutor),
        ],
      ],
    );
  }
}

/// Pill with how long ago the report was made ("hace 12 min").
class PildoraTiempo extends StatelessWidget {
  final String texto;

  const PildoraTiempo(this.texto, {super.key});

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('pildora-tiempo'),
    height: 28,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.schedule, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(
          texto,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: AppColors.textMuted,
          ),
        ),
      ],
    ),
  );
}

/// S25: "Reportado por" and the author's tier, its badge beside its name.
/// Only the tier is shown (no name, id or email), so the report stays
/// anonymous.
class FilaAutor extends StatelessWidget {
  static const String etiqueta = 'Reportado por';

  final TierUsuario tier;

  const FilaAutor({super.key, required this.tier});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Text(
        etiqueta,
        style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary),
      ),
      const SizedBox(width: 8),
      TierCompacto(tier),
    ],
  );
}

/// "Saturación reportada" and the saturation chip.
class SeccionSaturacion extends StatelessWidget {
  static const String etiqueta = 'Saturación reportada';

  final NivelSaturacion nivel;

  const SeccionSaturacion({super.key, required this.nivel});

  @override
  Widget build(BuildContext context) => _Seccion(
    etiqueta: etiqueta,
    children: [ChipSaturacion(nivel: nivel)],
  );
}

/// Validar's question block (design-system §7): "¿Está así ahora mismo?",
/// then the reported level large with its meter and its description, on the
/// level's background. The level never relies on color alone.
class PreguntaNivel extends StatelessWidget {
  static const String pregunta = '¿Está así ahora mismo?';

  final NivelSaturacion nivel;

  const PreguntaNivel({super.key, required this.nivel});

  @override
  Widget build(BuildContext context) {
    final fg = ChipSaturacion.fgDe(nivel);
    return Container(
      key: const ValueKey('pregunta-nivel'),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ChipSaturacion.bgDe(nivel),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            pregunta,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  MedidorNivel(nivel: nivel, color: fg, escala: 22 / 14),
                  const SizedBox(width: 8),
                  Text(
                    ChipSaturacion.etiquetaDe(nivel),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.48,
                      height: 1.0,
                      color: fg,
                    ),
                  ),
                ],
              ),
              Text(
                ChipSaturacion.descripcionDe(nivel),
                style: TextStyle(fontSize: 14, color: fg),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "Confiabilidad del reporte" with the reliability badge (a neutral icon,
/// the percentage and the level, decision D6), then any [detalle] lines the
/// screen adds below them.
class SeccionConfiabilidad extends StatelessWidget {
  static const String etiqueta = 'Confiabilidad del reporte';

  final Confiabilidad confiabilidad;
  final List<Widget> detalle;

  const SeccionConfiabilidad({
    super.key,
    required this.confiabilidad,
    this.detalle = const [],
  });

  @override
  Widget build(BuildContext context) => _Seccion(
    etiqueta: etiqueta,
    children: [
      InsigniaConfiabilidad(confiabilidad: confiabilidad),
      ...detalle,
    ],
  );
}

class _Seccion extends StatelessWidget {
  final String etiqueta;
  final List<Widget> children;

  const _Seccion({required this.etiqueta, required this.children});

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        etiqueta,
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
      const SizedBox(height: 6),
      ...children,
    ],
  );
}
