import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Main bottom bar (design-system §5): white with a top border; the active
/// tab carries a 60×30 `primaryContainer` pill and reads in bold `primary`.
class CrBottomNav extends StatelessWidget {
  /// Counts above this read "99+" on the badge.
  static const int insigniaMaxima = 99;

  /// Size of the pill behind the active tab's icon.
  static const Size tamPildora = Size(60, 30);

  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Unread alerts, shown as a badge on the Favoritos tab (hidden at zero).
  final int alertasNoLeidas;

  const CrBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.alertasNoLeidas = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('nav-principal'),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _item(context, 0, Icons.map_outlined, 'Mapa'),
              _item(context, 1, Icons.shield_outlined, 'Validar'),
              _item(
                context,
                2,
                Icons.favorite_border,
                'Favoritos',
                insignia: alertasNoLeidas,
              ),
              _item(context, 3, Icons.person_outline, 'Perfil'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context,
    int index,
    IconData icon,
    String label, {
    int insignia = 0,
  }) {
    final bool active = index == currentIndex;
    final Color color = active ? AppColors.primary : AppColors.textMuted;
    final Widget icono = Icon(icon, size: 22, color: color);

    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Fixed size: neither the pill nor the badge changes the height.
            Container(
              key: active ? const ValueKey('nav-indicador-activo') : null,
              width: tamPildora.width,
              height: tamPildora.height,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? AppColors.primaryContainer : null,
                borderRadius: BorderRadius.circular(tamPildora.height / 2),
              ),
              child: insignia > 0
                  ? Badge(
                      key: const Key('insignia-favoritos'),
                      label: Text(
                        insignia > insigniaMaxima
                            ? '$insigniaMaxima+'
                            : '$insignia',
                      ),
                      child: icono,
                    )
                  : icono,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                color: color,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
