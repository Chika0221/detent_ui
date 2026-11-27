import 'package:flutter/semantics.dart';

import '../foundation/primitives.dart';
import '../controls/controls.dart';
import '../feedback/feedback.dart';
import '../perforation/perforation.dart';

import 'package:flutter/services.dart';
import 'package:forui_lucide/forui_lucide.dart';

class DetentListRow extends StatelessWidget {
  const DetentListRow({
    super.key,
    required this.label,
    this.description,
    this.leading,
    this.trailing,
    this.selected = false,
    this.onPressed,
    this.onMoveUp,
    this.onMoveDown,
  });
  final String label;
  final String? description;
  final Widget? leading, trailing;
  final bool selected;
  final VoidCallback? onPressed;

  /// Reordering. When either is set the row shows a P1 grip at its start
  /// (DESIGN_SYSTEM.md §5.8): drag it vertically one row at a time, or press
  /// Alt+↑ / Alt+↓ while the row has focus. The host owns the order; pass
  /// null at the ends of the list.
  final VoidCallback? onMoveUp, onMoveDown;

  bool get _reorderable => onMoveUp != null || onMoveDown != null;

  @override
  Widget build(BuildContext context) {
    final t = DetentTheme.of(context);
    Widget row = DetentSurface(
      // Rows sit flat on their container; only the selection gets a surface,
      // matching SidebarItem and TreeView (DESIGN_SYSTEM.md §5.6).
      color: selected ? t.selectionSurface : DetentColors.transparent,
      borderRadius: BorderRadius.circular(DetentRadius.control),
      child: DetentTile(
        dense: true,
        selected: selected,
        selectedColor: t.selectionForeground,
        leading: _reorderable
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _RowGrip(onMoveUp: onMoveUp, onMoveDown: onMoveDown),
                  if (leading != null) ...[const SizedBox(width: 8), leading!],
                ],
              )
            : leading,
        trailing: trailing,
        title: Text(label),
        subtitle: description == null
            ? null
            : Text(
                description!,
                style: t.textTheme.caption.copyWith(color: t.muted),
              ),
        onTap: onPressed,
        contentPadding: const EdgeInsets.all(8),
      ),
    );
    if (_reorderable) {
      row = Semantics(
        customSemanticsActions: {
          const CustomSemanticsAction(label: '上へ移動'): ?onMoveUp,
          const CustomSemanticsAction(label: '下へ移動'): ?onMoveDown,
        },
        child: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.arrowUp, alt: true):
                ?onMoveUp,
            const SingleActivator(LogicalKeyboardKey.arrowDown, alt: true):
                ?onMoveDown,
          },
          child: row,
        ),
      );
    }
    return row;
  }
}

/// The grip at the start of a reorderable row. A vertical drag moves the row
/// one place each time it passes a row's height.
class _RowGrip extends StatefulWidget {
  const _RowGrip({this.onMoveUp, this.onMoveDown});
  final VoidCallback? onMoveUp, onMoveDown;
  @override
  State<_RowGrip> createState() => _RowGripState();
}

class _RowGripState extends State<_RowGrip> {
  bool hovered = false, dragging = false;
  double travel = 0;

  @override
  Widget build(BuildContext context) {
    final step = DetentTheme.of(context).controlHeight;
    return MouseRegion(
      cursor: dragging ? SystemMouseCursors.grabbing : SystemMouseCursors.grab,
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: (_) => setState(() {
          dragging = true;
          travel = 0;
        }),
        onVerticalDragUpdate: (e) {
          travel += e.delta.dy;
          if (travel <= -step && widget.onMoveUp != null) {
            travel += step;
            widget.onMoveUp!();
          } else if (travel >= step && widget.onMoveDown != null) {
            travel -= step;
            widget.onMoveDown!();
          }
        },
        onVerticalDragEnd: (_) => setState(() => dragging = false),
        onVerticalDragCancel: () => setState(() => dragging = false),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: DetentGrip(length: 3, active: hovered || dragging),
        ),
      ),
    );
  }
}

@immutable
class DetentTreeNode<T> {
  const DetentTreeNode({
    required this.id,
    required this.label,
    this.children = const [],
    this.icon,
  });
  final T id;
  final String label;
  final List<DetentTreeNode<T>> children;
  final IconData? icon;
}

class DetentTreeView<T> extends StatefulWidget {
  const DetentTreeView({
    super.key,
    required this.nodes,
    required this.expanded,
    required this.selected,
    required this.onExpandedChanged,
    required this.onSelectionChanged,
    this.multiselect = false,
  });
  final List<DetentTreeNode<T>> nodes;
  final Set<T> expanded, selected;
  final ValueChanged<Set<T>> onExpandedChanged, onSelectionChanged;
  final bool multiselect;
  @override
  State<DetentTreeView<T>> createState() => _DetentTreeViewState<T>();
}

class _DetentTreeViewState<T> extends State<DetentTreeView<T>> {
  final Map<T, FocusNode> focus = {};
  final Map<T, GlobalKey> keys = {};
  @override
  void dispose() {
    for (final n in focus.values) {
      n.dispose();
    }
    super.dispose();
  }

  void toggle(DetentTreeNode<T> n, bool expand) {
    final values = {...widget.expanded};
    expand ? values.add(n.id) : values.remove(n.id);
    widget.onExpandedChanged(values);
  }

  void select(DetentTreeNode<T> n) {
    if (widget.multiselect &&
        (HardwareKeyboard.instance.isControlPressed ||
            HardwareKeyboard.instance.isMetaPressed)) {
      final values = {...widget.selected};
      values.contains(n.id) ? values.remove(n.id) : values.add(n.id);
      widget.onSelectionChanged(values);
    } else {
      widget.onSelectionChanged({n.id});
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = <(DetentTreeNode<T>, int, T?)>[];
    void visit(List<DetentTreeNode<T>> nodes, int depth, T? parent) {
      for (final n in nodes) {
        rows.add((n, depth, parent));
        if (widget.expanded.contains(n.id)) visit(n.children, depth + 1, n.id);
      }
    }

    visit(widget.nodes, 0, null);
    void request(T id) {
      focus[id]?.requestFocus();
      final ctx = keys[id]?.currentContext;
      if (ctx != null) Scrollable.ensureVisible(ctx);
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: rows.length,
      itemBuilder: (context, i) {
        final (n, depth, parent) = rows[i];
        return Focus(
          key: keys.putIfAbsent(n.id, GlobalKey.new),
          focusNode: focus.putIfAbsent(n.id, FocusNode.new),
          onKeyEvent: (_, e) {
            if (e is KeyUpEvent) return KeyEventResult.ignored;
            final k = e.logicalKey;
            if (k == LogicalKeyboardKey.arrowDown && i + 1 < rows.length) {
              request(rows[i + 1].$1.id);
            } else if (k == LogicalKeyboardKey.arrowUp && i > 0) {
              request(rows[i - 1].$1.id);
            } else if (k == LogicalKeyboardKey.arrowRight &&
                n.children.isNotEmpty) {
              if (widget.expanded.contains(n.id)) {
                if (i + 1 < rows.length) request(rows[i + 1].$1.id);
              } else {
                toggle(n, true);
              }
            } else if (k == LogicalKeyboardKey.arrowLeft) {
              if (widget.expanded.contains(n.id)) {
                toggle(n, false);
              } else if (parent != null) {
                request(parent);
              }
            } else if (k == LogicalKeyboardKey.home && rows.isNotEmpty) {
              request(rows.first.$1.id);
            } else if (k == LogicalKeyboardKey.end && rows.isNotEmpty) {
              request(rows.last.$1.id);
            } else if (k == LogicalKeyboardKey.space ||
                k == LogicalKeyboardKey.enter) {
              select(n);
            } else {
              return KeyEventResult.ignored;
            }
            return KeyEventResult.handled;
          },
          child: Builder(
            builder: (ctx) => Semantics(
              selected: widget.selected.contains(n.id),
              expanded: n.children.isEmpty
                  ? null
                  : widget.expanded.contains(n.id),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Focus.of(ctx).hasFocus
                        ? DetentTheme.of(context).focus
                        : DetentColors.transparent,
                    width: 2,
                  ),
                ),
                padding: EdgeInsets.only(left: depth * 16.0),
                child: DetentTile(
                  dense: true,
                  selected: widget.selected.contains(n.id),
                  leading: n.children.isEmpty
                      ? Icon(n.icon ?? FLucideIcons.file, size: 16)
                      : DetentIconAction(
                          tooltip: widget.expanded.contains(n.id)
                              ? '折り畳む'
                              : '展開',
                          icon: SizedBox.square(
                            dimension: 16,
                            child: AnimatedRotation(
                              turns: widget.expanded.contains(n.id) ? .25 : 0,
                              duration: DetentTheme.of(context)
                                  .duration(context, 120),
                              curve: const Cubic(.2, 0, .2, 1),
                              child: const Icon(
                                FLucideIcons.chevronRight,
                                size: 16,
                              ),
                            ),
                          ),
                          onPressed: () =>
                              toggle(n, !widget.expanded.contains(n.id)),
                        ),
                  selectedTileColor: DetentTheme.of(context).surface,
                  selectedColor: DetentTheme.of(context).ink,
                  trailing: widget.selected.contains(n.id)
                      ? Icon(
                          FLucideIcons.check,
                          size: 16,
                          color: DetentTheme.of(context).ink,
                        )
                      : null,
                  title: Text(n.label),
                  onTap: () {
                    request(n.id);
                    select(n);
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

@immutable
class DetentTableColumn {
  const DetentTableColumn({
    required this.label,
    this.flex = 1,
    this.onSort,
    this.ascending,
  });
  final String label;
  final int flex;
  final VoidCallback? onSort;
  final bool? ascending;
}

/// Fixed header and lazily built rows. Supply stable IDs when sort order changes.
class DetentDataTable<T> extends StatelessWidget {
  const DetentDataTable({
    super.key,
    required this.columns,
    required this.rows,
    required this.rowId,
    required this.cells,
    this.selected = const {},
    this.onSelectionChanged,
    this.loading = false,
    this.error,
    this.emptyLabel = '項目がありません',
    this.rowHeight = 48,
  });
  final List<DetentTableColumn> columns;
  final List<T> rows;
  final Object Function(T) rowId;
  final List<Widget> Function(T) cells;
  final Set<Object> selected;
  final ValueChanged<Set<Object>>? onSelectionChanged;
  final bool loading;
  final String? error;
  final String emptyLabel;
  final double rowHeight;
  @override
  Widget build(BuildContext context) {
    final t = DetentTheme.of(context);
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: t.controlBorder)),
          ),
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              if (onSelectionChanged != null) const SizedBox(width: 48),
              for (final c in columns)
                Expanded(
                  flex: c.flex,
                  child: Semantics(
                    sortKey: OrdinalSortKey(columns.indexOf(c).toDouble()),
                    label: c.ascending == null
                        ? c.label
                        : '${c.label} ${c.ascending! ? '昇順' : '降順'}',
                    child: DetentPlainButton(
                      onPressed: c.onSort,
                      child: Row(
                        children: [
                          Flexible(child: Text(c.label)),
                          if (c.ascending != null)
                            Icon(
                              c.ascending!
                                  ? FLucideIcons.arrowUp
                                  : FLucideIcons.arrowDown,
                              size: 16,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (loading) const DetentProgress(),
        Expanded(
          child: error != null
              ? Center(
                  child: Text(error!, style: TextStyle(color: t.danger)),
                )
              : rows.isEmpty
              ? Center(child: Text(loading ? '読み込み中' : emptyLabel))
              : ListView.builder(
                  itemCount: rows.length,
                  itemBuilder: (context, i) {
                    final row = rows[i], id = rowId(row), values = cells(row);
                    assert(
                      values.length == columns.length,
                      'A cell is required for each column.',
                    );
                    // One rule between rows instead of a frame per row.
                    return DecoratedBox(
                      key: ValueKey(id),
                      decoration: BoxDecoration(
                        color: selected.contains(id)
                            ? t.selectionSurface
                            : null,
                        border: Border(bottom: BorderSide(color: t.border)),
                      ),
                      child: DetentInk(
                        onTap: onSelectionChanged == null
                            ? null
                            : () => onSelectionChanged!({id}),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: rowHeight),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              children: [
                                if (onSelectionChanged != null)
                                  SizedBox(
                                    width: 48,
                                    child: DetentCheckbox(
                                      value: selected.contains(id),
                                      onChanged: (checked) {
                                        final next = {...selected};
                                        checked == true
                                            ? next.add(id)
                                            : next.remove(id);
                                        onSelectionChanged!(next);
                                      },
                                    ),
                                  ),
                                for (var j = 0; j < values.length; j++)
                                  Expanded(
                                    flex: columns[j].flex,
                                    child: DefaultTextStyle.merge(
                                      style: TextStyle(
                                        color: selected.contains(id)
                                            ? t.selectionForeground
                                            : t.ink,
                                      ),
                                      child: values[j],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
