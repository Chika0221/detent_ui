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
  const NuiSelect({super.key,required this.options,this.value,this.onChanged,this.hintText});
  final List<NuiOption<T>> options;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final String? hintText;
  @override Widget build(BuildContext context)=>_NuiOptionPicker<T>(options:options,value:value,
    editable:false,enabled:onChanged!=null,onPick:onChanged,hintText:hintText??'選択してください');
}

class NuiComboBox<T extends Object> extends StatelessWidget {
  const NuiComboBox({super.key,required this.options,this.onSelected,this.onChanged,
    this.initialText='',this.loading=false,this.hintText='選択または入力'});
  final List<NuiOption<T>> options;
  final ValueChanged<T>? onSelected;
  final ValueChanged<String>? onChanged;
  final String initialText,hintText;
  final bool loading;
  @override Widget build(BuildContext context)=>_NuiOptionPicker<T>(options:options,editable:true,
    initialText:initialText,loading:loading,hintText:hintText,onPick:onSelected,onChanged:onChanged);
}

/// Both controls share their anchor, field decoration, list and row states.
/// A Select has a host-owned value; a ComboBox retains native text editing.
class _NuiOptionPicker<T> extends StatefulWidget {
  const _NuiOptionPicker({required this.options,required this.editable,required this.hintText,
    this.enabled=true,this.value,this.onPick,this.onChanged,this.initialText='',this.loading=false});
  final List<NuiOption<T>> options;
  final bool editable,enabled,loading;
  final T? value;
  final ValueChanged<T>? onPick;
  final ValueChanged<String>? onChanged;
  final String hintText,initialText;
  @override State<_NuiOptionPicker<T>> createState()=>_NuiOptionPickerState<T>();
}
class _NuiOptionPickerState<T> extends State<_NuiOptionPicker<T>> {
  final menu=MenuController(),focus=FocusNode(),scroll=ScrollController();
  late final text=TextEditingController(text:widget.editable?widget.initialText:selected?.label??'');
  NuiOption<T>? picked;
  int highlighted=-1;
  NuiOption<T>? get selected {
    if(widget.editable)return picked?.label==text.text?picked:null;
    for(final o in widget.options){if(o.value==widget.value)return o;}
    return null;
  }
  List<NuiOption<T>> get candidates=>widget.loading?[]:widget.options.where((o)=>
    !widget.editable||o.label.toLowerCase().contains(text.text.toLowerCase())).toList();
  @override void initState(){super.initState();focus.addListener(onFocus);}
  void onFocus(){if(!focus.hasFocus&&menu.isOpen)menu.close();}
  @override void didUpdateWidget(_NuiOptionPicker<T> old){
    super.didUpdateWidget(old);
    if(!widget.editable){final label=selected?.label??'';if(text.text!=label)text.text=label;}
    if(!widget.enabled&&menu.isOpen){WidgetsBinding.instance.addPostFrameCallback((_){if(mounted)menu.close();});}
    final rows=candidates;if(highlighted>=rows.length)highlighted=rows.indexWhere((o)=>o.enabled);
  }
  @override void dispose(){focus.removeListener(onFocus);focus.dispose();text.dispose();scroll.dispose();super.dispose();}
  double rowHeight(BuildContext context){final scaled=MediaQuery.textScalerOf(context).scale(14)*1.5+16;
    return scaled>NuiTheme.of(context).controlHeight?scaled:NuiTheme.of(context).controlHeight;}
  void open(){
    if(!widget.enabled)return;
    final rows=candidates;final current=selected;
    highlighted=current==null?-1:rows.indexWhere((o)=>o.value==current.value&&o.enabled);
    if(highlighted<0)highlighted=rows.indexWhere((o)=>o.enabled);
    focus.requestFocus();menu.open();reveal();
  }
  void reveal(){WidgetsBinding.instance.addPostFrameCallback((_){
    if(mounted&&scroll.hasClients&&highlighted>=0){final height=rowHeight(context),top=highlighted*rowHeight(context);
      final bottom=top+height,offset=scroll.offset,viewport=scroll.position.viewportDimension;
      if(top<offset)scroll.jumpTo(top.clamp(0.0,scroll.position.maxScrollExtent));
      else if(bottom>offset+viewport)scroll.jumpTo((bottom-viewport).clamp(0.0,scroll.position.maxScrollExtent));
    }
  });}
  void move(int direction,{bool boundary=false}){
    final rows=candidates;if(rows.isEmpty)return;
    var next=boundary?(direction>0?rows.length-1:0):highlighted;
    for(var i=0;i<rows.length;i++){
      if(!boundary||i>0)next=(next+direction)%rows.length;
      if(rows[next].enabled){setState(()=>highlighted=next);reveal();return;}
    }
  }
  void choose(NuiOption<T> option){
    if(!widget.enabled||!option.enabled)return;
    if(widget.editable){picked=option;text.value=TextEditingValue(text:option.label,selection:TextSelection.collapsed(offset:option.label.length));}
    menu.close();focus.requestFocus();widget.onPick?.call(option.value);
  }
  KeyEventResult key(FocusNode node,KeyEvent event){
    if(!widget.enabled||event is KeyUpEvent||text.value.composing.isValid)return KeyEventResult.ignored;
    final k=event.logicalKey;
    if(k==LogicalKeyboardKey.arrowDown||k==LogicalKeyboardKey.arrowUp){
      if(menu.isOpen)move(k==LogicalKeyboardKey.arrowDown?1:-1);else open();return KeyEventResult.handled;}
    if(menu.isOpen&&(k==LogicalKeyboardKey.home||k==LogicalKeyboardKey.end)){
      move(k==LogicalKeyboardKey.end?1:-1,boundary:true);return KeyEventResult.handled;}
    if(k==LogicalKeyboardKey.escape&&menu.isOpen){menu.close();focus.requestFocus();return KeyEventResult.handled;}
    if(k==LogicalKeyboardKey.tab){if(menu.isOpen)menu.close();return KeyEventResult.ignored;}
    if(k==LogicalKeyboardKey.enter||(!widget.editable&&k==LogicalKeyboardKey.space)){
      if(!menu.isOpen){if(!widget.editable){open();return KeyEventResult.handled;}return KeyEventResult.ignored;}
      final rows=candidates;if(highlighted>=0&&highlighted<rows.length)choose(rows[highlighted]);return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }
  @override Widget build(BuildContext context){
    final theme=NuiTheme.of(context),rows=candidates;
    return LayoutBuilder(builder:(context,bounds){
      final width=bounds.hasBoundedWidth?bounds.maxWidth:320.0;
      return Focus(canRequestFocus:false,skipTraversal:true,onKeyEvent:key,
        child:MenuAnchor(controller:menu,childFocusNode:focus,alignmentOffset:const Offset(0,4),
          style:MenuStyle(padding:const WidgetStatePropertyAll(EdgeInsets.zero),
            backgroundColor:WidgetStatePropertyAll(theme.raised),surfaceTintColor:const WidgetStatePropertyAll(Colors.transparent),
            elevation:const WidgetStatePropertyAll(4),shape:WidgetStatePropertyAll(RoundedRectangleBorder(
              borderRadius:BorderRadius.circular(8),side:BorderSide(color:theme.controlBorder)))),
          menuChildren:[TextFieldTapRegion(child:SizedBox(width:width,height:rows.isEmpty?rowHeight(context)+16:(rows.length*rowHeight(context)+16).clamp(0.0,256.0),child:Padding(padding:const EdgeInsets.all(8),
            child:ConstrainedBox(constraints:const BoxConstraints(maxHeight:240),child:rows.isEmpty?
              Padding(padding:const EdgeInsets.all(8),child:Text(widget.loading?'読み込み中':'候補がありません',style:TextStyle(color:theme.muted))):
              Scrollbar(controller:scroll,child:ListView.builder(controller:scroll,padding:EdgeInsets.zero,
                itemExtent:rowHeight(context),itemCount:rows.length,itemBuilder:(context,i){
                  final option=rows[i],isSelected=selected?.value==option.value;
                  return MouseRegion(onEnter:(_){if(option.enabled)setState(()=>highlighted=i);},
                    child:ExcludeFocus(child:ListTile(dense:true,enabled:option.enabled,selected:isSelected,
                      contentPadding:const EdgeInsets.symmetric(horizontal:8),
                      tileColor:highlighted==i?theme.surface:theme.raised,
                      selectedTileColor:highlighted==i?theme.surface:theme.raised,selectedColor:theme.ink,
                      shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(4)),
                      title:Tooltip(message:option.label,excludeFromSemantics:true,child:Text(option.label,maxLines:1,overflow:TextOverflow.ellipsis,
                        style:Theme.of(context).textTheme.bodyMedium!.copyWith(color:option.enabled?theme.ink:theme.muted))),
                      trailing:isSelected?Icon(FLucideIcons.check,size:16,color:theme.ink):const SizedBox(width:16),
                      onTap:option.enabled?()=>choose(option):null)));
                }))))))],
          builder:(context,controller,_)=>TextField(controller:text,focusNode:focus,enabled:widget.enabled,
            readOnly:!widget.editable,showCursor:widget.editable,enableInteractiveSelection:widget.editable,
            style:Theme.of(context).textTheme.bodyMedium,
            onTap:open,onChanged:widget.editable?(value){picked=null;highlighted=candidates.indexWhere((o)=>o.enabled);
              setState((){});if(!menu.isOpen)menu.open();widget.onChanged?.call(value);}:null,
            decoration:InputDecoration(hintText:widget.hintText,constraints:BoxConstraints(minHeight:theme.controlHeight),
              suffixIconConstraints:const BoxConstraints.tightFor(width:28,height:28),suffixIcon:IconButton(
                tooltip:widget.loading?'読み込み中':'候補を表示',padding:const EdgeInsets.all(6),constraints:const BoxConstraints(minWidth:28,minHeight:28),
                icon:Icon(widget.loading?FLucideIcons.loader:FLucideIcons.chevronDown,size:16),
                onPressed:widget.enabled?(){if(controller.isOpen)controller.close();else open();}:null)),
          )));
    });
  }
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
