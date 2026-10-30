// Keep compatibility with Flutter's Material re-export during SDK extraction.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui_lucide/forui_lucide.dart';

import '../foundation/theme.dart';
import '../controls/controls.dart';
import '../inputs/inputs.dart';

@immutable
class NuiTab<T> {
  const NuiTab(this.value, this.label, {this.dirty = false, this.onClose});
  final T value;
  final String label;
  final bool dirty;
  final VoidCallback? onClose;
}

class NuiTabs<T> extends StatefulWidget {
  const NuiTabs({
    super.key,
    required this.tabs,
    required this.value,
    this.onChanged,
    this.manualActivation = false,
  });
  final List<NuiTab<T>> tabs;
  final T value;
  final ValueChanged<T>? onChanged;
  final bool manualActivation;
  @override
  State<NuiTabs<T>> createState() => _NuiTabsState<T>();
}

class _NuiTabsState<T> extends State<NuiTabs<T>> {
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
    final t = NuiTheme.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
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
                if (k == LogicalKeyboardKey.end) next = widget.tabs.length - 1;
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
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: widget.value == tab.value ? t.accent : t.border,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      NuiButton(
                        label: '${tab.label}${tab.dirty ? ' •' : ''}',
                        focusNode: nodes.putIfAbsent(tab.value, FocusNode.new),
                        variant: NuiButtonVariant.quiet,
                        onPressed: widget.onChanged == null
                            ? null
                            : () => widget.onChanged!(tab.value),
                      ),
                      if (tab.onClose != null)
                        NuiIconButton(
                          icon: FLucideIcons.x,
                          tooltip: '${tab.label}を閉じる',
                          onPressed: tab.onClose,
                        ),
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

class NuiNavigationRail<T> extends StatelessWidget {
  const NuiNavigationRail({
    super.key,
    required this.options,
    required this.value,
    this.onChanged,
  });
  final List<NuiOption<T>> options;
  final T value;
  final ValueChanged<T>? onChanged;
  @override
  Widget build(BuildContext context) => Container(
    color: NuiTheme.of(context).surface,
    padding: const EdgeInsets.all(8),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final o in options)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: NuiIconButton(
              icon: o.icon ?? FLucideIcons.circle,
              tooltip: o.label,
              selected: value == o.value,
              onPressed: onChanged == null || !o.enabled
                  ? null
                  : () => onChanged!(o.value),
            ),
          ),
      ],
    ),
  );
}

class NuiSidebarItem extends StatelessWidget {
  const NuiSidebarItem({
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
    final t = NuiTheme.of(context);
    return Material(
      color: selected ? t.surface : Colors.transparent,
      child: ListTile(
        dense: true,
        contentPadding: EdgeInsets.only(left: 8 + depth * 16, right: 8),
        minTileHeight: t.controlHeight,
        selected: selected,
        selectedColor: t.ink,
        leading: icon == null ? null : Icon(icon, size: 16),
        title: Text(label),
        trailing:
            trailing ??
            (count == null
                ? null
                : Text(
                    '$count',
                    style: TextStyle(color: t.muted, fontSize: 12),
                  )),
        onTap: onPressed,
      ),
    );
  }
}

class NuiBreadcrumb extends StatelessWidget {
  const NuiBreadcrumb({super.key, required this.items, this.maxVisible = 4});
  final List<NuiBreadcrumbItem> items;
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
          if (i > 0) const Icon(FLucideIcons.chevronRight, size: 16),
          if (collapse && i == 1)
            NuiDropdownMenu(
              label: '途中の階層',
              items: [
                for (final o in items.skip(1).take(items.length - maxVisible))
                  NuiMenuItem(label: o.label, onPressed: o.onPressed),
              ],
            ),
          TextButton(
            onPressed: visible[i].onPressed,
            child: Text(visible[i].label),
          ),
        ],
      ],
    );
  }
}

@immutable
class NuiBreadcrumbItem {
  const NuiBreadcrumbItem(this.label, {this.onPressed});
  final String label;
  final VoidCallback? onPressed;
}

@immutable
class NuiMenuItem {
  const NuiMenuItem({
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
  final List<NuiMenuItem> children;
  final bool danger;
}

List<Widget> nuiMenuWidgets(BuildContext context, List<NuiMenuItem> items) => [
  for (final item in items)
    if (item.children.isNotEmpty)
      SubmenuButton(
        menuChildren: nuiMenuWidgets(context, item.children),
        child: Text(item.label),
      )
    else
      MenuItemButton(
        onPressed: item.onPressed,
        leadingIcon: item.checked != null
            ? Icon(
                item.checked! ? FLucideIcons.check : FLucideIcons.circle,
                size: 16,
              )
            : item.icon == null
            ? null
            : Icon(item.icon, size: 16),
        trailingIcon: item.shortcut == null
            ? null
            : Text(
                item.shortcut!,
                style: TextStyle(
                  fontSize: 12,
                  color: NuiTheme.of(context).muted,
                ),
              ),
        child: Text(
          item.label,
          style: item.danger
              ? TextStyle(color: NuiTheme.of(context).danger)
              : null,
        ),
      ),
];

class NuiMenuBar extends StatelessWidget {
  const NuiMenuBar({super.key, required this.menus});
  final List<NuiMenuItem> menus;
  @override
  Widget build(BuildContext context) => MenuBar(
    children: [
      for (final m in menus)
        SubmenuButton(
          menuChildren: nuiMenuWidgets(context, m.children),
          child: Text(m.label),
        ),
    ],
  );
}

class NuiDropdownMenu extends StatefulWidget {
  const NuiDropdownMenu({
    super.key,
    required this.label,
    required this.items,
    this.icon,
  });
  final String label;
  final List<NuiMenuItem> items;
  final IconData? icon;
  @override
  State<NuiDropdownMenu> createState() => _NuiDropdownMenuState();
}

class _NuiDropdownMenuState extends State<NuiDropdownMenu> {
  final focus = FocusNode();
  @override
  void dispose() {
    focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MenuAnchor(
    childFocusNode: focus,
    menuChildren: nuiMenuWidgets(context, widget.items),
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
      child: NuiButton(
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

class NuiContextMenu extends StatefulWidget {
  const NuiContextMenu({super.key, required this.items, required this.child});
  final List<NuiMenuItem> items;
  final Widget child;
  @override
  State<NuiContextMenu> createState() => _NuiContextMenuState();
}

class _NuiContextMenuState extends State<NuiContextMenu> {
  final controller = MenuController();
  final focus = FocusNode();
  @override
  void dispose() {
    focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MenuAnchor(
    controller: controller,
    childFocusNode: focus,
    menuChildren: nuiMenuWidgets(context, widget.items),
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
class NuiCommand {
  const NuiCommand({
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

class NuiCommandPalette extends StatefulWidget {
  const NuiCommandPalette({super.key, required this.commands, this.onDismiss});
  final List<NuiCommand> commands;
  final VoidCallback? onDismiss;
  static Future<void> show(
    BuildContext context, {
    required List<NuiCommand> commands,
  }) => showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      child: SizedBox(
        width: 560,
        height: 420,
        child: NuiCommandPalette(
          commands: commands,
          onDismiss: () => Navigator.pop(ctx),
        ),
      ),
    ),
  );
  @override
  State<NuiCommandPalette> createState() => _NuiCommandPaletteState();
}

class _NuiCommandPaletteState extends State<NuiCommandPalette> {
  String query = '';
  int selected = 0;
  final focus = FocusNode();
  final scroll = ScrollController();
  List<NuiCommand> get filtered => widget.commands
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

  void run(NuiCommand c) {
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
            NuiTextField(
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
                        return ListTile(
                          selected: i == selected,
                          selectedTileColor: NuiTheme.of(context).surface,
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
