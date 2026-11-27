import 'package:detent_ui/detent_ui.dart';
import 'package:flutter/widgets.dart';

/// The gallery's own navigation row. Like every selectable item it marks the
/// current section with the selection lamp only: no surface, chevron or check
/// (DESIGN_SYSTEM.md §5.10).
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
    final theme = DetentTheme.of(context);
    return DetentTile(
      lamp: true,
      leading: Icon(icon),
      title: Text(label),
      subtitle: description == null
          ? null
          : Text(
              description!,
              style: theme.textTheme.caption.copyWith(color: theme.muted),
            ),
      selected: selected,
      minTileHeight: theme.controlHeight + 8,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      onTap: onPressed,
    );
  }
}
