import '../foundation/primitives.dart';

import 'package:flutter/services.dart';
import 'package:forui_lucide/forui_lucide.dart';

import '../controls/controls.dart';
import '../inputs/inputs.dart';

@immutable
class DetentTab<T> {
  const DetentTab(this.value, this.label, {this.dirty = false, this.onClose});
  final T value;
  final String label;
  final bool dirty;
  final VoidCallback? onClose;
}

class DetentTabs<T> extends StatefulWidget {
  const DetentTabs({
    super.key,
    required this.tabs,
    required this.value,
    this.onChanged,
    this.manualActivation = false,
  });
  final List<DetentTab<T>> tabs;
  final T value;
  final ValueChanged<T>? onChanged;
  final bool manualActivation;
  @override
  State<DetentTabs<T>> createState() => _DetentTabsState<T>();
}

class _DetentTabsState<T> extends State<DetentTabs<T>> {
  final Map<T, FocusNode> nodes = {};
  @override
  void dispose() {
    for (final n in nodes.values) {
      n.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: DetentTheme.of(context).border),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          spacing: 4,
          children: [
            for (final tab in widget.tabs)
              Focus(
                onKeyEvent: (_, e) {
                  if (e is KeyUpEvent) return KeyEventResult.ignored;
                  final i = widget.tabs.indexOf(tab), k = e.logicalKey;
                  int? next;
                  if (k == LogicalKeyboardKey.arrowRight) {
                    next = (i + 1) % widget.tabs.length;
                  }
                  if (k == LogicalKeyboardKey.arrowLeft) {
                    next = (i - 1) % widget.tabs.length;
                  }
                  if (k == LogicalKeyboardKey.home) next = 0;
                  if (k == LogicalKeyboardKey.end) {
                    next = widget.tabs.length - 1;
                  }
                  if (next == null) return KeyEventResult.ignored;
                  final target = widget.tabs[next];
                  nodes[target.value]?.requestFocus();
                  if (!widget.manualActivation) {
                    widget.onChanged?.call(target.value);
                  }
                  return KeyEventResult.handled;
                },
                child: Semantics(
                  selected: widget.value == tab.value,
                  // A tab is a destination: the lamp marks the open one and
                  // the shared bottom rule is the only frame (§5.10).
                  child: DetentInk(
                    focusNode: nodes.putIfAbsent(tab.value, FocusNode.new),
                    selected: widget.value == tab.value,
                    onTap: widget.onChanged == null
                        ? null
                        : () => widget.onChanged!(tab.value),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: DetentTheme.of(context).controlHeight + 4,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            DetentSelectionLamp(
                              lit: widget.value == tab.value,
                              enabled: widget.onChanged != null,
                            ),
                            const SizedBox(
                              width: DetentTokens.selection_lamp_gap,
                            ),
                            // Unsaved is an asterisk, so it never reads
                            // as a second lamp.
                            Text(
                              '${tab.label}${tab.dirty ? ' *' : ''}',
                              semanticsLabel: tab.dirty
                                  ? '${tab.label}（未保存）'
                                  : null,
                              style: TextStyle(
                                fontWeight: widget.value == tab.value
                                    ? FontWeight.w600
                                    : null,
                                color: widget.value == tab.value
                                    ? DetentTheme.of(context).ink
                                    : DetentTheme.of(context).muted,
                              ),
                            ),
                            if (tab.onClose != null) ...[
                              const SizedBox(width: 8),
                              DetentIconAction(
                                icon: const Icon(FLucideIcons.x, size: 16),
                                tooltip: '${tab.label}を閉じる',
                                padding: const EdgeInsets.all(2),
                                constraints: const BoxConstraints(
                                  minWidth: 24,
                                  minHeight: 24,
                                ),
                                onPressed: tab.onClose,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class DetentNavigationRail<T> extends StatelessWidget {
  const DetentNavigationRail({
    super.key,
    required this.options,
    required this.value,
    this.onChanged,
  });
  final List<DetentOption<T>> options;
  final T value;
  final ValueChanged<T>? onChanged;
  @override
  Widget build(BuildContext context) {
    final t = DetentTheme.of(context);
    // Flat destinations with a visible label under each icon; the lamp at the
    // left marks the current one (DESIGN_SYSTEM.md §5.10).
    return Container(
      color: t.surface,
      padding: const EdgeInsets.all(4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          for (final o in options)
            Semantics(
              selected: value == o.value,
              label: o.label,
              excludeSemantics: true,
              child: DetentInk(
                selected: value == o.value,
                onTap: onChanged == null || !o.enabled
                    ? null
                    : () => onChanged!(o.value),
                child: SizedBox(
                  width: 76,
                  height: t.controlHeight + 16,
                  child: Row(
                    children: [
                      const SizedBox(width: 6),
                      DetentSelectionLamp(
                        lit: value == o.value,
                        enabled: onChanged != null && o.enabled,
                      ),
                      Expanded(
                        child: Opacity(
                          opacity: o.enabled ? 1 : .45,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                o.icon ?? FLucideIcons.circle,
                                size: 16,
                                color: value == o.value ? t.ink : t.muted,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                o.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: t.textTheme.caption.copyWith(
                                  color: value == o.value ? t.ink : t.muted,
                                  fontWeight: value == o.value
                                      ? FontWeight.w600
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class DetentSidebarItem extends StatelessWidget {
  const DetentSidebarItem({
    super.key,
    required this.label,
    this.icon,
    this.selected = false,
    this.depth = 0,
    this.count,
    this.trailing,
    this.onPressed,
  });
  final String label;
  final IconData? icon;
  final bool selected;
  final int depth;
  final int? count;
  final Widget? trailing;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) {
    final t = DetentTheme.of(context);
    // The lamp alone marks the current destination; no surface, no chevron
    // or check (DESIGN_SYSTEM.md §5.10).
    return DetentTile(
      dense: true,
      lamp: true,
      contentPadding: EdgeInsets.only(left: 8 + depth * 16, right: 8),
      minTileHeight: t.controlHeight,
      selected: selected,
      leading: icon == null ? null : Icon(icon, size: 16),
      title: Text(label),
      trailing:
          trailing ??
          (count == null
              ? null
              : Text(
                  '$count',
                  style: t.textTheme.caption.copyWith(color: t.muted),
                )),
      onTap: onPressed,
    );
  }
}

class DetentBreadcrumb extends StatelessWidget {
  const DetentBreadcrumb({super.key, required this.items, this.maxVisible = 4});
  final List<DetentBreadcrumbItem> items;
  final int maxVisible;
  @override
  Widget build(BuildContext context) {
    final collapse = items.length > maxVisible && maxVisible >= 2;
    final visible = collapse
        ? [items.first, ...items.skip(items.length - maxVisible + 1)]
        : items;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      children: [
        for (var i = 0; i < visible.length; i++) ...[
          if (i > 0)
            Text('/', style: TextStyle(color: DetentTheme.of(context).muted)),
          if (collapse && i == 1)
            DetentDropdownMenu(
              label: '途中の階層',
              items: [
                for (final o in items.skip(1).take(items.length - maxVisible))
                  DetentMenuItem(label: o.label, onPressed: o.onPressed),
              ],
            ),
          DetentPlainButton(
            onPressed: visible[i].onPressed,
            child: Text(visible[i].label),
          ),
        ],
      ],
    );
  }
}

@immutable
class DetentBreadcrumbItem {
  const DetentBreadcrumbItem(this.label, {this.onPressed});
  final String label;
  final VoidCallback? onPressed;
}

@immutable
class DetentMenuItem {
  const DetentMenuItem({
    required this.label,
    this.onPressed,
    this.icon,
    this.shortcut,
    this.checked,
    this.children = const [],
    this.danger = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final String? shortcut;
  final bool? checked;
  final List<DetentMenuItem> children;
  final bool danger;
}

List<Widget> detentMenuWidgets(
  BuildContext context,
  List<DetentMenuItem> items,
) => [
  for (final item in items)
    if (item.children.isNotEmpty)
      _DetentSubmenu(label: item.label, items: item.children)
    else
      Builder(
        builder: (context) => DetentTile(
          title: Text(
            item.label,
            style: TextStyle(
              color: item.danger ? DetentTheme.of(context).danger : null,
            ),
          ),
          leading: item.checked != null
              ? Icon(
                  item.checked! ? FLucideIcons.check : FLucideIcons.circle,
                  size: 16,
                )
              : item.icon == null
              ? null
              : Icon(item.icon, size: 16),
          trailing: item.shortcut == null
              ? null
              : Text(
                  item.shortcut!,
                  style: DetentTheme.of(context).textTheme.caption
                      .copyWith(color: DetentTheme.of(context).muted),
                ),
          onTap: item.onPressed == null
              ? null
              : () {
                  DetentPopupController.maybeOf(context)?.closeAll();
                  item.onPressed!();
                },
        ),
      ),
];

class _DetentSubmenu extends StatelessWidget {
  const _DetentSubmenu({
    required this.label,
    required this.items,
    this.topLevel = false,
  });
  final bool topLevel;
  final String label;
  final List<DetentMenuItem> items;
  @override
  Widget build(BuildContext context) => DetentPopupAnchor(
    focusMenu: true,
    menuChildren: detentMenuWidgets(context, items),
    builder: (ctx, c, _) => DetentPlainButton(
      onPressed: () => c.isOpen ? c.close() : c.open(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (!topLevel) ...[
            const SizedBox(width: 8),
            const Icon(FLucideIcons.chevronRight, size: 16),
          ],
        ],
      ),
    ),
  );
}

class DetentMenuBar extends StatelessWidget {
  const DetentMenuBar({super.key, required this.menus});
  final List<DetentMenuItem> menus;
  @override
  Widget build(BuildContext context) => DetentSurface(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(DetentRadius.control),
      side: BorderSide(color: DetentTheme.of(context).border),
    ),
    child: ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: DetentTheme.of(context).controlHeight + 2,
      ),
      child: Wrap(
        spacing: 8,
        children: [
          for (final m in menus)
            _DetentSubmenu(label: m.label, items: m.children, topLevel: true),
        ],
      ),
    ),
  );
}

class DetentDropdownMenu extends StatefulWidget {
  const DetentDropdownMenu({
    super.key,
    required this.label,
    required this.items,
    this.icon,
  });
  final String label;
  final List<DetentMenuItem> items;
  final IconData? icon;
  @override
  State<DetentDropdownMenu> createState() => _DetentDropdownMenuState();
}

class _DetentDropdownMenuState extends State<DetentDropdownMenu> {
  final focus = FocusNode();
  @override
  void dispose() {
    focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DetentPopupAnchor(
    focusMenu: true,
    childFocusNode: focus,
    menuChildren: detentMenuWidgets(context, widget.items),
    builder: (context, controller, child) => Focus(
      onKeyEvent: (_, e) {
        if (e is KeyDownEvent &&
            e.logicalKey == LogicalKeyboardKey.escape &&
            controller.isOpen) {
          controller.close();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: DetentButton(
        label: widget.label,
        focusNode: focus,
        icon: widget.icon ?? FLucideIcons.chevronDown,
        onPressed: () {
          focus.requestFocus();
          controller.isOpen ? controller.close() : controller.open();
        },
      ),
    ),
  );
}

class DetentContextMenu extends StatefulWidget {
  const DetentContextMenu({
    super.key,
    required this.items,
    required this.child,
  });
  final List<DetentMenuItem> items;
  final Widget child;
  @override
  State<DetentContextMenu> createState() => _DetentContextMenuState();
}

class _DetentContextMenuState extends State<DetentContextMenu> {
  final controller = DetentPopupController();
  final focus = FocusNode();
  @override
  void dispose() {
    focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DetentPopupAnchor(
    controller: controller,
    focusMenu: true,
    childFocusNode: focus,
    menuChildren: detentMenuWidgets(context, widget.items),
    builder: (context, c, _) => Focus(
      focusNode: focus,
      onKeyEvent: (_, e) {
        if (e is KeyDownEvent &&
            (e.logicalKey == LogicalKeyboardKey.contextMenu ||
                (e.logicalKey == LogicalKeyboardKey.f10 &&
                    HardwareKeyboard.instance.isShiftPressed))) {
          c.open();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onSecondaryTapDown: (e) {
          focus.requestFocus();
          c.open(position: e.localPosition);
        },
        child: widget.child,
      ),
    ),
  );
}

@immutable
class DetentCommand {
  const DetentCommand({
    required this.id,
    required this.label,
    required this.onPressed,
    this.group = '',
    this.shortcut,
    this.icon,
  });
  final String id, label, group;
  final VoidCallback onPressed;
  final String? shortcut;
  final IconData? icon;
}

class DetentCommandPalette extends StatefulWidget {
  const DetentCommandPalette({
    super.key,
    required this.commands,
    this.onDismiss,
  });
  final List<DetentCommand> commands;
  final VoidCallback? onDismiss;
  static Future<void> show(
    BuildContext context, {
    required List<DetentCommand> commands,
  }) => showDetentDialog<void>(
    context: context,
    builder: (ctx) => DetentDialogFrame(
      child: SizedBox(
        width: 560,
        height: 420,
        child: DetentCommandPalette(
          commands: commands,
          onDismiss: () => Navigator.pop(ctx),
        ),
      ),
    ),
  );
  @override
  State<DetentCommandPalette> createState() => _DetentCommandPaletteState();
}

class _DetentCommandPaletteState extends State<DetentCommandPalette> {
  String query = '';
  int selected = 0;
  final focus = FocusNode();
  final scroll = ScrollController();
  List<DetentCommand> get filtered => widget.commands
      .where(
        (c) =>
            '${c.label} ${c.group}'.toLowerCase().contains(query.toLowerCase()),
      )
      .toList();
  @override
  void dispose() {
    focus.dispose();
    scroll.dispose();
    super.dispose();
  }

  void run(DetentCommand c) {
    widget.onDismiss?.call();
    c.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final results = filtered;
    return Focus(
      onKeyEvent: (_, e) {
        if (e is KeyUpEvent) return KeyEventResult.ignored;
        if (e.logicalKey == LogicalKeyboardKey.escape) {
          widget.onDismiss?.call();
          return KeyEventResult.handled;
        }
        if (e.logicalKey == LogicalKeyboardKey.arrowDown ||
            e.logicalKey == LogicalKeyboardKey.arrowUp) {
          if (results.isNotEmpty) {
            setState(
              () => selected =
                  (selected +
                      (e.logicalKey == LogicalKeyboardKey.arrowDown ? 1 : -1)) %
                  results.length,
            );
            if (scroll.hasClients) {
              scroll.jumpTo(
                (selected * 56.0).clamp(0, scroll.position.maxScrollExtent),
              );
            }
          }
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            DetentTextField(
              focusNode: focus,
              autofocus: true,
              hintText: 'コマンドを検索',
              prefix: const Icon(FLucideIcons.search),
              onChanged: (v) => setState(() {
                query = v;
                selected = 0;
              }),
              onSubmitted: (_) {
                if (results.isNotEmpty) {
                  run(results[selected.clamp(0, results.length - 1)]);
                }
              },
            ),
            const SizedBox(height: 8),
            Expanded(
              child: results.isEmpty
                  ? const Center(child: Text('一致するコマンドがありません'))
                  : ListView.builder(
                      controller: scroll,
                      itemExtent: 56,
                      itemCount: results.length,
                      itemBuilder: (context, i) {
                        final c = results[i];
                        return DetentTile(
                          // The active command is a keyboard highlight,
                          // not a selection, so it keeps a surface and no lamp.
                          selected: i == selected,
                          leading: c.icon == null ? null : Icon(c.icon),
                          title: Text(c.label),
                          subtitle: c.group.isEmpty ? null : Text(c.group),
                          trailing: c.shortcut == null
                              ? null
                              : Text(c.shortcut!),
                          onTap: () => run(c),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
