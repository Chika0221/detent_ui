// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:detent_ui/detent_ui.dart';

const options=[NuiOption(0,'Atelier'),NuiOption(1,'Disabled',enabled:false),NuiOption(2,'Detent')];
Future<void> host(WidgetTester t,Widget widget,{NuiThemeData data=const NuiThemeData(riveEnabled:false)})=>t.pumpWidget(
  MaterialApp(theme:data.materialTheme,home:NuiTheme(data:data,child:Scaffold(body:Center(child:SizedBox(width:300,child:widget))))));
void main(){
  testWidgets('Select and ComboBox share field height, popup width and list style',(t) async {
    for(final editable in [false,true]){
      await host(t,editable?const NuiComboBox(options:options):NuiSelect(options:options,value:0,onChanged:(_){}));
      final field=find.byType(TextField);expect(t.getSize(field).height,40);
      await t.tap(field);await t.pumpAndSettle();
      final list=find.byType(ListView);expect(list,findsOneWidget);expect(t.getSize(list).width,284);
      final tiles=t.widgetList<ListTile>(find.byType(ListTile));expect(tiles.length,3);
      expect(tiles.first.contentPadding,const EdgeInsets.symmetric(horizontal:8));
      final menu=t.widget<Material>(find.ancestor(of:list,matching:find.byType(Material)).first);
      expect(menu.elevation,4);
      await t.sendKeyEvent(LogicalKeyboardKey.escape);await t.pumpAndSettle();expect(find.byType(ListView),findsNothing);
    }
  });
  testWidgets('Select skips disabled options and follows its controlled value',(t) async {
    var value=0;
    await host(t,StatefulBuilder(builder:(ctx,set)=>NuiSelect(options:options,value:value,onChanged:(v)=>set(()=>value=v!))));
    await t.tap(find.byType(TextField));await t.pumpAndSettle();
    await t.sendKeyEvent(LogicalKeyboardKey.arrowDown);await t.sendKeyEvent(LogicalKeyboardKey.enter);await t.pumpAndSettle();
    expect(value,2);expect(t.widget<TextField>(find.byType(TextField)).controller!.text,'Detent');
    await t.tap(find.byType(TextField));await t.pumpAndSettle();expect(find.byType(ListView),findsOneWidget);
    await t.sendKeyEvent(LogicalKeyboardKey.home);await t.sendKeyEvent(LogicalKeyboardKey.enter);await t.pumpAndSettle();expect(value,0);
  });
  testWidgets('ComboBox filters, selects via keyboard and reopens after a choice',(t) async {
    int? selected;String? changed;
    await host(t,NuiComboBox(options:options,onSelected:(v)=>selected=v,onChanged:(v)=>changed=v));
    await t.enterText(find.byType(TextField),'Det');await t.pumpAndSettle();
    expect(changed,'Det');expect(find.text('Atelier'),findsNothing);expect(find.text('Detent'),findsOneWidget);
    await t.sendKeyEvent(LogicalKeyboardKey.enter);await t.pumpAndSettle();expect(selected,2);
    expect(t.widget<TextField>(find.byType(TextField)).controller!.text,'Detent');
    await t.tap(find.byTooltip('候補を表示'));await t.pumpAndSettle();expect(find.byType(ListView),findsOneWidget);
    await t.sendKeyEvent(LogicalKeyboardKey.escape);await t.pumpAndSettle();expect(find.byType(ListView),findsNothing);
  });
  testWidgets('outside click closes and mouse selection keeps the field focus',(t) async {
    int? value;
    await host(t,NuiSelect(options:options,value:0,onChanged:(v)=>value=v));
    await t.tap(find.byType(TextField));await t.pumpAndSettle();
    await t.tap(find.text('Detent'));await t.pumpAndSettle();expect(value,2);expect(find.byType(ListView),findsNothing);
    expect(t.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus,true);
    await t.tap(find.byType(TextField));await t.pumpAndSettle();await t.tapAt(const Offset(2,2));await t.pumpAndSettle();
    expect(find.byType(ListView),findsNothing);
  });
  testWidgets('loading and no-results use the same bounded popup',(t) async {
    await host(t,const NuiComboBox<int>(options:[],loading:true));
    await t.tap(find.byType(TextField));await t.pumpAndSettle();expect(find.text('読み込み中'),findsOneWidget);
    await host(t,const NuiComboBox<int>(options:[]));await t.pumpAndSettle();
    expect(find.text('候補がありません'),findsOneWidget);
  });
  testWidgets('popup remains in the viewport at 200 percent text scale',(t) async {
    t.view.physicalSize=const Size(400,320);t.view.devicePixelRatio=1;
    addTearDown(t.view.resetPhysicalSize);addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(MaterialApp(home:MediaQuery(data:const MediaQueryData(size:Size(400,320),textScaler:TextScaler.linear(2)),
      child:NuiTheme(data:const NuiThemeData(riveEnabled:false),child:Scaffold(body:Align(alignment:Alignment.bottomCenter,child:SizedBox(width:300,
        child:NuiSelect(options:options,value:0,onChanged:(_){}))))))));
    await t.tap(find.byType(TextField));await t.pumpAndSettle();
    final rect=t.getRect(find.byType(ListView));expect(rect.top,greaterThanOrEqualTo(0));expect(rect.bottom,lessThanOrEqualTo(320));
    expect(t.takeException(),isNull);
  });
}
