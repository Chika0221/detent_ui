import '../foundation/primitives.dart';

import 'package:flutter/services.dart';
import 'package:forui_lucide/forui_lucide.dart';

import '../controls/controls.dart';
import '../inputs/inputs.dart';
import '../rive/artwork.dart';
import '../rive/skin.dart';

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
                child: _NuiAnimatedTab(
                  selected: widget.value == tab.value,
                  child: NuiInk(
                    focusNode: nodes.putIfAbsent(tab.value, FocusNode.new),
                    onTap: widget.onChanged == null
                        ? null
                        : () => widget.onChanged!(tab.value),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: NuiTheme.of(context).controlHeight + 6,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${tab.label}${tab.dirty ? ' •' : ''}'),
                            if (tab.onClose != null) ...[
                              const SizedBox(width: 8),
                              NuiIconAction(
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
            ),
        ],
      ),
    );
  }
}

class _NuiAnimatedTab extends StatelessWidget {
  const _NuiAnimatedTab({required this.selected, required this.child});
  final bool selected;
  final Widget child;
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Container(
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: selected ? NuiTheme.of(context).raised : null,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: selected
                ? NuiTheme.of(context).controlBorder
                : NuiColors.transparent,
          ),
        ),
        child: child,
      ),
      Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        height: 2,
        child: NuiRiveArtwork(
          artboard: 'TabIndicator',
          stretch: true,
          state: NuiSkinState(selected: selected),
          fallback: ColoredBox(
            color: selected
                ? NuiTheme.of(context).accent
                : NuiTheme.of(context).border,
          ),
        ),
      ),
    ],
  );
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
    return NuiSurface(
      color: selected ? t.surface : NuiColors.transparent,
      child: NuiTile(
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
          if (i > 0)
            Text('/', style: TextStyle(color: NuiTheme.of(context).muted)),
          if (collapse && i == 1)
            NuiDropdownMenu(
              label: '途中の階層',
              items: [
                for (final o in items.skip(1).take(items.length - maxVisible))
                  NuiMenuItem(label: o.label, onPressed: o.onPressed),
              ],
            ),
          NuiPlainButton(
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
      _NuiSubmenu(label: item.label, items: item.children)
    else
      Builder(
        builder: (context) => NuiTile(
          title: Text(
            item.label,
            style: TextStyle(
              color: item.danger ? NuiTheme.of(context).danger : null,
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
                  style: NuiTheme.of(context).textTheme.bodySmall
                      .copyWith(color: NuiTheme.of(context).muted),
                ),
          onTap: item.onPressed == null
              ? null
              : () {
                  NuiPopupController.maybeOf(context)?.closeAll();
                  item.onPressed!();
                },
        ),
      ),
];

class _NuiSubmenu extends StatelessWidget {
  const _NuiSubmenu({
    required this.label,
    required this.items,
    this.topLevel = false,
  });
  final bool topLevel;
  final String label;
  final List<NuiMenuItem> items;
  @override
  Widget build(BuildContext context) => NuiPopupAnchor(
    focusMenu: true,
    menuChildren: nuiMenuWidgets(context, items),
    builder: (ctx, c, _) => NuiPlainButton(
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

class NuiMenuBar extends StatelessWidget {
  const NuiMenuBar({super.key, required this.menus});
  final List<NuiMenuItem> menus;
  @override
  Widget build(BuildContext context) => NuiSurface(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(4),
      side: BorderSide(color: NuiTheme.of(context).border),
    ),
    child: ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: NuiTheme.of(context).controlHeight + 2,
      ),
      child: Wrap(
        spacing: 8,
        children: [
          for (final m in menus)
            _NuiSubmenu(label: m.label, items: m.children, topLevel: true),
        ],
      ),
    ),
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
  Widget build(BuildContext context) => NuiPopupAnchor(
    focusMenu: true,
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
  final controller = NuiPopupController();
  final focus = FocusNode();
  @override
  void dispose() {
    focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => NuiPopupAnchor(
    controller: controller,
    focusMenu: true,
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
  }) => showNuiDialog<void>(
    context: context,
    builder: (ctx) => NuiDialogFrame(
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
                        return NuiTile(
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
