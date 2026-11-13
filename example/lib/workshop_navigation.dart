import 'package:detent_ui/detent_ui.dart';
import 'package:flutter/widgets.dart';

class WorkshopNavigationItem extends StatelessWidget {
  const WorkshopNavigationItem({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onPressed,
    this.description,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onPressed;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final theme = NuiTheme.of(context);
    final foreground = selected ? theme.selectionForeground : theme.ink;
    return IconTheme.merge(
      data: IconThemeData(color: foreground),
      child: NuiTile(
        leading: Icon(icon),
        title: Text(label),
        subtitle: description == null
            ? null
            : Text(
                description!,
                style: theme.textTheme.bodySmall.copyWith(
                  color: selected ? foreground : theme.muted,
                ),
              ),
        trailing: Icon(
          selected ? FLucideIcons.check : FLucideIcons.chevronRight,
        ),
        selected: selected,
        selectedTileColor: theme.selectionSurface,
        hoverColor: selected ? theme.selectionSurface : theme.surface,
        selectedColor: foreground,
        minTileHeight: theme.controlHeight + 8,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        onTap: onPressed,
      ),
    );
  }
}
