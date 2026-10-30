import 'package:flutter/semantics.dart';
// Keep compatibility with Flutter's Material re-export during SDK extraction.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui_lucide/forui_lucide.dart';

import '../foundation/theme.dart';
import '../rive/artwork.dart';
import '../rive/skin.dart';

class NuiListRow extends StatelessWidget {
  const NuiListRow({
    super.key,
    required this.label,
    this.description,
    this.leading,
    this.trailing,
    this.selected = false,
    this.onPressed,
  });
  final String label;
  final String? description;
  final Widget? leading, trailing;
  final bool selected;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => Material(
    color: selected ? NuiTheme.of(context).surface : Colors.transparent,
    child: ListTile(
      dense: true,
      selected: selected,
      selectedColor: NuiTheme.of(context).ink,
      leading: leading,
      trailing: trailing,
      title: Text(label),
      subtitle: description == null ? null : Text(description!),
      onTap: onPressed,
      contentPadding: const EdgeInsets.all(8),
    ),
  );
}

@immutable
class NuiTreeNode<T> {
  const NuiTreeNode({
    required this.id,
    required this.label,
    this.children = const [],
    this.icon,
  });
  final T id;
  final String label;
  final List<NuiTreeNode<T>> children;
  final IconData? icon;
}

class NuiTreeView<T> extends StatefulWidget {
  const NuiTreeView({
    super.key,
    required this.nodes,
    required this.expanded,
    required this.selected,
    required this.onExpandedChanged,
    required this.onSelectionChanged,
    this.multiselect = false,
  });
  final List<NuiTreeNode<T>> nodes;
  final Set<T> expanded, selected;
  final ValueChanged<Set<T>> onExpandedChanged, onSelectionChanged;
  final bool multiselect;
  @override
  State<NuiTreeView<T>> createState() => _NuiTreeViewState<T>();
}

class _NuiTreeViewState<T> extends State<NuiTreeView<T>> {
  final Map<T, FocusNode> focus = {};
  final Map<T, GlobalKey> keys = {};
  @override
  void dispose() {
    for (final n in focus.values) {
      n.dispose();
    }
    super.dispose();
  }

  void toggle(NuiTreeNode<T> n, bool expand) {
    final values = {...widget.expanded};
    expand ? values.add(n.id) : values.remove(n.id);
    widget.onExpandedChanged(values);
  }

  void select(NuiTreeNode<T> n) {
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
    final rows = <(NuiTreeNode<T>, int, T?)>[];
    void visit(List<NuiTreeNode<T>> nodes, int depth, T? parent) {
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
                        ? NuiTheme.of(context).focus
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                padding: EdgeInsets.only(left: depth * 16.0),
                child: ListTile(
                  dense: true,
                  selected: widget.selected.contains(n.id),
                  leading: n.children.isEmpty
                      ? Icon(n.icon ?? FLucideIcons.file, size: 16)
                      : IconButton(
                          tooltip: widget.expanded.contains(n.id)
                              ? '折り畳む'
                              : '展開',
                          icon: SizedBox.square(
                            dimension: 16,
                            child: NuiRiveArtwork(
                              artboard: 'Chevron',
                              state: NuiSkinState(
                                selected: widget.expanded.contains(n.id),
                              ),
                              fallback: Icon(
                                widget.expanded.contains(n.id)
                                    ? FLucideIcons.chevronDown
                                    : FLucideIcons.chevronRight,
                                size: 16,
                              ),
                            ),
                          ),
                          onPressed: () =>
                              toggle(n, !widget.expanded.contains(n.id)),
                        ),
                  selectedTileColor: NuiTheme.of(context).surface,
                  selectedColor: NuiTheme.of(context).ink,
                  trailing: widget.selected.contains(n.id)
                      ? Icon(
                          FLucideIcons.check,
                          size: 16,
                          color: NuiTheme.of(context).accent,
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
class NuiTableColumn {
  const NuiTableColumn({
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
class NuiDataTable<T> extends StatelessWidget {
  const NuiDataTable({
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
  final List<NuiTableColumn> columns;
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
    final t = NuiTheme.of(context);
    return Column(
      children: [
        Container(
          color: t.surface,
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
                    child: TextButton(
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
        if (loading) const LinearProgressIndicator(),
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
                    return Material(
                      key: ValueKey(id),
                      color: selected.contains(id)
                          ? t.accent.withValues(alpha: t.highContrast ? 1 : .2)
                          : t.raised,
                      child: InkWell(
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
                                    child: Checkbox(
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
                                        color:
                                            selected.contains(id) &&
                                                t.highContrast
                                            ? t.accentInk
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
