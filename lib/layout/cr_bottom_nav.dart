import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class CrBottomNav extends StatelessWidget {
  /// Counts above this read "99+" on the badge.
  static const int insigniaMaxima = 99;

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
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.borderNav, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
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
    final Color color = active ? AppColors.secondary : AppColors.textMuted;

    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Fixed height: the badge must not make the tab taller.
            SizedBox(
              height: 23,
              child: insignia > 0
                  ? Badge(
                      key: const Key('insignia-favoritos'),
                      label: Text(
                        insignia > insigniaMaxima
                            ? '$insigniaMaxima+'
                            : '$insignia',
                      ),
                      child: Icon(icon, size: 23, color: color),
                    )
                  : Icon(icon, size: 23, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: active ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
