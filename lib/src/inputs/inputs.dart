// Keep compatibility with Flutter's Material re-export during SDK extraction.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui_lucide/forui_lucide.dart';
import 'package:intl/intl.dart';

import '../controls/controls.dart';
import '../foundation/theme.dart';

class NuiTextField extends StatelessWidget {
  const NuiTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.hintText,
    this.prefix,
    this.suffix,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.obscureText = false,
    this.maxLines = 1,
    this.maxLength,
    this.errorText,
    this.semanticLabel,
    this.keyboardType,
    this.inputFormatters,
  });
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged, onSubmitted;
  final String? hintText, errorText, semanticLabel;
  final Widget? prefix, suffix;
  final bool enabled, readOnly, autofocus, obscureText;
  final int? maxLines, maxLength;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticLabel,
    child: TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      enabled: enabled,
      readOnly: readOnly,
      autofocus: autofocus,
      obscureText: obscureText,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: prefix,
        suffixIcon: suffix,
        errorText: errorText,
        constraints: BoxConstraints(
          minHeight: NuiTheme.of(context).controlHeight,
        ),
      ),
    ),
  );
}

class NuiTextArea extends StatelessWidget {
  const NuiTextArea({
    super.key,
    this.controller,
    this.onChanged,
    this.hintText,
    this.maxLength,
    this.minLines = 3,
    this.maxLines = 8,
    this.readOnly = false,
  });
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String? hintText;
  final int? maxLength;
  final int minLines, maxLines;
  final bool readOnly;
  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    onChanged: onChanged,
    minLines: minLines,
    maxLines: maxLines,
    maxLength: maxLength,
    readOnly: readOnly,
    decoration: InputDecoration(hintText: hintText),
  );
}

class NuiSearchField extends StatefulWidget {
  const NuiSearchField({
    super.key,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.hintText = '検索',
    this.shortcut,
  });
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged, onSubmitted;
  final String hintText;
  final String? shortcut;
  @override
  State<NuiSearchField> createState() => _NuiSearchFieldState();
}

class _NuiSearchFieldState extends State<NuiSearchField> {
  late TextEditingController _own;
  TextEditingController get c => widget.controller ?? _own;
  @override
  void initState() {
    super.initState();
    _own = TextEditingController();
  }

  @override
  void dispose() {
    _own.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<TextEditingValue>(
        valueListenable: c,
        builder: (context, value, _) => NuiTextField(
          controller: c,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          hintText: widget.hintText,
          semanticLabel: widget.hintText,
          prefix: const Icon(FLucideIcons.search),
          suffix: value.text.isNotEmpty
              ? IconButton(
                  tooltip: '検索をクリア',
                  icon: const Icon(FLucideIcons.x),
                  onPressed: () {
                    c.clear();
                    widget.onChanged?.call('');
                  },
                )
              : widget.shortcut == null
              ? null
              : Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    widget.shortcut!,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
        ),
      );
}

class NuiSelect<T> extends StatelessWidget {
  const NuiSelect({
    super.key,
    required this.options,
    this.value,
    this.onChanged,
    this.hintText,
  });
  final List<NuiOption<T>> options;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final String? hintText;
  @override
  Widget build(BuildContext context) => DropdownButtonFormField<T>(
    initialValue: value,
    key: ValueKey(value),
    isExpanded: true,
    hint: hintText == null ? null : Text(hintText!),
    onChanged: onChanged,
    items: [
      for (final o in options)
        DropdownMenuItem<T>(
          value: o.value,
          enabled: o.enabled,
          child: Text(o.label),
        ),
    ],
    icon: const Icon(FLucideIcons.chevronDown, size: 16),
  );
}

class NuiComboBox<T extends Object> extends StatelessWidget {
  const NuiComboBox({
    super.key,
    required this.options,
    this.onSelected,
    this.onChanged,
    this.initialText = '',
    this.loading = false,
    this.hintText = '選択または入力',
  });
  final List<NuiOption<T>> options;
  final ValueChanged<T>? onSelected;
  final ValueChanged<String>? onChanged;
  final String initialText, hintText;
  final bool loading;
  @override
  Widget build(BuildContext context) => Autocomplete<NuiOption<T>>(
    initialValue: TextEditingValue(text: initialText),
    displayStringForOption: (o) => o.label,
    optionsBuilder: (v) => loading
        ? const Iterable.empty()
        : options.where(
            (o) =>
                o.enabled &&
                o.label.toLowerCase().contains(v.text.toLowerCase()),
          ),
    onSelected: (o) => onSelected?.call(o.value),
    fieldViewBuilder: (ctx, c, f, submit) => NuiTextField(
      controller: c,
      focusNode: f,
      onChanged: onChanged,
      hintText: hintText,
      onSubmitted: (_) => submit(),
      suffix: loading
          ? const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(FLucideIcons.loader),
            )
          : null,
    ),
    optionsViewBuilder: (ctx, select, values) => Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 240),
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            shrinkWrap: true,
            itemCount: values.length,
            itemBuilder: (ctx, i) {
              final o = values.elementAt(i);
              final highlight = AutocompleteHighlightedOption.of(ctx) == i;
              return ListTile(
                selected: highlight,
                title: Text(o.label),
                onTap: () => select(o),
              );
            },
          ),
        ),
      ),
    ),
  );
}

class NuiFormField extends StatelessWidget {
  const NuiFormField({
    super.key,
    required this.label,
    required this.child,
    this.description,
    this.error,
    this.required = false,
  });
  final String label;
  final Widget child;
  final String? description, error;
  final bool required;
  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: '$label${required ? ' 必須' : ''}',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label${required ? ' *' : ''}',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        child,
        if (description != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              description!,
              style: TextStyle(fontSize: 12, color: NuiTheme.of(context).muted),
            ),
          ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Semantics(
              liveRegion: true,
              child: Text(
                error!,
                style: TextStyle(color: NuiTheme.of(context).danger),
              ),
            ),
          ),
      ],
    ),
  );
}

class NuiNumberStepper extends StatefulWidget {
  const NuiNumberStepper({
    super.key,
    required this.value,
    this.min = -double.infinity,
    this.max = double.infinity,
    this.step = 1,
    this.onChanged,
    this.unit = '',
    this.label = '値',
    this.locale,
    this.fractionDigits = 0,
  });
  final double value, min, max, step;
  final ValueChanged<double>? onChanged;
  final String unit, label;
  final String? locale;
  final int fractionDigits;
  @override
  State<NuiNumberStepper> createState() => _NuiNumberStepperState();
}

class _NuiNumberStepperState extends State<NuiNumberStepper> {
  final c = TextEditingController();
  final focus = FocusNode();
  String? error;
  NumberFormat get format => NumberFormat.decimalPattern(widget.locale)
    ..minimumFractionDigits = widget.fractionDigits
    ..maximumFractionDigits = widget.fractionDigits;
  void sync() {
    c.text = format.format(widget.value);
  }

  void commit() {
    try {
      final v = format.parse(c.text).toDouble();
      if (!v.isFinite || v < widget.min || v > widget.max) {
        setState(() => error = '${widget.min}〜${widget.max} の値を入力してください');
        return;
      }
      setState(() => error = null);
      widget.onChanged?.call(v);
      c.text = format.format(v);
    } on FormatException {
      setState(() => error = '数値を入力してください');
    }
  }

  @override
  void initState() {
    super.initState();
    sync();
    focus.addListener(() {
      if (!focus.hasFocus) commit();
    });
  }

  @override
  void didUpdateWidget(NuiNumberStepper old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value || old.locale != widget.locale) sync();
  }

  @override
  void dispose() {
    focus.dispose();
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: NuiTextField(
          controller: c,
          focusNode: focus,
          enabled: widget.onChanged != null,
          semanticLabel: widget.label,
          errorText: error,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          onSubmitted: (_) => commit(),
          suffix: Padding(
            padding: const EdgeInsets.all(8),
            child: Text(widget.unit),
          ),
        ),
      ),
      const SizedBox(width: 8),
      NuiIconButton(
        icon: FLucideIcons.minus,
        tooltip: '${widget.label}を減らす',
        onPressed: widget.onChanged == null || widget.value <= widget.min
            ? null
            : () => widget.onChanged!(
                (widget.value - widget.step).clamp(widget.min, widget.max),
              ),
      ),
      NuiIconButton(
        icon: FLucideIcons.plus,
        tooltip: '${widget.label}を増やす',
        onPressed: widget.onChanged == null || widget.value >= widget.max
            ? null
            : () => widget.onChanged!(
                (widget.value + widget.step).clamp(widget.min, widget.max),
              ),
      ),
    ],
  );
}

@immutable
class NuiShortcut {
  const NuiShortcut(
    this.key, {
    this.control = false,
    this.meta = false,
    this.alt = false,
    this.shift = false,
  });
  final LogicalKeyboardKey key;
  final bool control, meta, alt, shift;
  SingleActivator get activator => SingleActivator(
    key,
    control: control,
    meta: meta,
    alt: alt,
    shift: shift,
  );
  String get label => [
    if (control) 'Ctrl',
    if (meta) 'Cmd',
    if (alt) 'Alt',
    if (shift) 'Shift',
    key.keyLabel,
  ].join(' + ');
}

class NuiShortcutRecorder extends StatefulWidget {
  const NuiShortcutRecorder({
    super.key,
    this.value,
    this.onChanged,
    this.conflict,
  });
  final NuiShortcut? value;
  final ValueChanged<NuiShortcut>? onChanged;
  final String? conflict;
  @override
  State<NuiShortcutRecorder> createState() => _NuiShortcutRecorderState();
}

class _NuiShortcutRecorderState extends State<NuiShortcutRecorder> {
  bool recording = false;
  final focus = FocusNode();
  @override
  void dispose() {
    focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Focus(
    focusNode: focus,
    onFocusChange: (v) {
      if (!v && recording) setState(() => recording = false);
    },
    onKeyEvent: (_, e) {
      if (!recording || e is! KeyDownEvent) return KeyEventResult.ignored;
      if (e.logicalKey == LogicalKeyboardKey.escape) {
        setState(() => recording = false);
        return KeyEventResult.handled;
      }
      if ([
        LogicalKeyboardKey.controlLeft,
        LogicalKeyboardKey.controlRight,
        LogicalKeyboardKey.shiftLeft,
        LogicalKeyboardKey.shiftRight,
        LogicalKeyboardKey.altLeft,
        LogicalKeyboardKey.altRight,
        LogicalKeyboardKey.metaLeft,
        LogicalKeyboardKey.metaRight,
      ].contains(e.logicalKey)) {
        return KeyEventResult.handled;
      }
      final hw = HardwareKeyboard.instance;
      widget.onChanged?.call(
        NuiShortcut(
          e.logicalKey,
          control: hw.isControlPressed,
          meta: hw.isMetaPressed,
          shift: hw.isShiftPressed,
          alt: hw.isAltPressed,
        ),
      );
      setState(() => recording = false);
      return KeyEventResult.handled;
    },
    child: NuiFormField(
      label: 'ショートカット',
      error: widget.conflict,
      child: NuiButton(
        label: recording
            ? 'キーを押してください（Escで中止）'
            : widget.value?.label ?? '記録を開始',
        variant: recording
            ? NuiButtonVariant.primary
            : NuiButtonVariant.secondary,
        onPressed: widget.onChanged == null
            ? null
            : () {
                setState(() => recording = true);
                focus.requestFocus();
              },
      ),
    ),
  );
}
