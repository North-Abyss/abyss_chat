import 'dart:ui';
import 'package:flutter/material.dart';

class FloatingDockItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final VoidCallback onTap;

  FloatingDockItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.onTap,
  });
}

class FloatingDock extends StatelessWidget {
  final List<FloatingDockItem> items;
  final int selectedIndex;
  final bool isVertical;

  const FloatingDock({
    super.key,
    required this.items,
    required this.selectedIndex,
    this.isVertical = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget buildItem(int index, FloatingDockItem item) {
      final isSelected = index == selectedIndex;
      return Tooltip(
        message: item.label,
        preferBelow: !isVertical,
        verticalOffset: isVertical ? 0 : 30,
        child: InkWell(
          onTap: item.onTap,
          customBorder: const CircleBorder(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? cs.primaryContainer : Colors.transparent,
            ),
            child: Icon(
              isSelected ? item.selectedIcon : item.icon,
              color: isSelected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
              size: 24,
            ),
          ),
        ),
      );
    }

    final dockContent = Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: cs.surfaceContainer.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isVertical
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  buildItem(i, items[i]),
                  if (i < items.length - 1) const SizedBox(height: 8),
                ]
              ],
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  buildItem(i, items[i]),
                  if (i < items.length - 1) const SizedBox(width: 8),
                ]
              ],
            ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: dockContent,
      ),
    );
  }
}
