# Detent Design System

Flutter デスクトップ向けの UI パッケージ。`ui_design.pen` の48部品（C01–C48）を
`Nui` 接頭辞の Widget として実装しています。デザイン版は0.4、実装版は0.7.0です。通常の操作部品でRiveアニメーションを既定で使用します。

## ギャラリー

白・グレー・黒の面に、黄色の選択表示と控えめな厚みを組み合わせた、道具らしいデスクトップUIです。
ボタンやノブは操作部として立体的に、一覧や文章は読みやすく平面的に表現します。
以下はデザイン画像ではなく、実装したFlutterギャラリーのスクリーンショットです（1440×1000px）。

### ライト：基本の操作部品

ボタン、キーキャップ、排他的な選択、チェックボックス、スイッチ、スライダー、ノブ、数値入力。
黄色は主要操作や選択に使い、細い輪郭と底面で操作面の構造を示します。

![ライトテーマの操作部品ギャラリー](example/screenshots/light.png)

### ダーク：同じ部品を暗い作業環境へ

背景・操作面・文字の色を役割ごとに切り替え、黄色の選択表示を維持します。
ギャラリー上部からテーマ、高コントラスト、動きの抑制、表示密度を切り替えられます。

![ダークテーマの操作部品ギャラリー](example/screenshots/dark.png)

### 作業領域：情報を整理する部品

アプリのシェル、ヘッダー付きパネル、ツールバー、リサイズできる分割領域、ステータスバー、ツリー、データ表。
これらを組み合わせて、一覧と詳細を並べるデスクトップ画面を構成します。

![シェル・パネル・ツリー・データ表のギャラリー](example/screenshots/workspace.png)

### フィードバック：値と処理状態を伝える部品

ドット数字、メーター、進捗、通知、エラー、空状態、読み込み表示、タスク状態。
状態は色に加えて文字やアイコンでも伝えます。

![進捗・通知・エラー・タスク状態のギャラリー](example/screenshots/feedback.png)

通常部品の操作面・機構はRive、文字と入力・フォーカス・読み上げはFlutterが担当します。
ギャラリー上部の「Rive」で従来のFlutter描画と比較できます。

### Riveの動き

ボタンの押し込みとスイッチの切り替えを、実際の `.riv` からフレーム書き出ししたサンプルです。
通常の部品では、この描画にFlutterの文字・入力・キーボード操作が重なります。

![Riveによるボタン押下とスイッチ切り替えのアニメーション](example/screenshots/rive-motion.gif)

## 基本的な使い方

```dart
import 'package:flutter/widgets.dart';
import 'package:detent_ui/detent_ui.dart';

NuiApp(
  home: NuiAppShell(
    body: NuiPanel(
      header: const Text('プロジェクト'),
      child: NuiButton(
        label: '保存',
        variant: NuiButtonVariant.primary,
        onPressed: save,
      ),
    ),
  ),
)
```

全コンポーネントは `package:flutter/widgets.dart` の基礎 Widget で構成しています。
`NuiApp` も `WidgetsApp` を使用します。入力・メニュー・通知・ダイアログを含め、
MaterialApp、Scaffold、Material、Theme の祖先は必要ありません。
既存の `WidgetsApp` では、対象領域を `NuiTheme(data: data, child: ...)` で包んでください。
ポップアップやダイアログを使う場合は Navigator / Overlay が必要です（WidgetsApp の home / routes で用意されます）。

```dart
WidgetsApp(
  color: const Color(0xFFE9CF48),
  pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
    settings: settings,
    pageBuilder: (context, animation, secondaryAnimation) => builder(context),
  ),
  home: NuiTheme(
    data: const NuiThemeData(),
    child: NuiBox(body: YourScreen()),
  ),
)
```

テーマ切替は `NuiThemeMode`、範囲値は `NuiRangeValues` を使います。
0.6 以前の `materialTheme` は削除しました。`NuiToast.show` の戻り値は `NuiToastHandle` で、
`close()` で通知を閉じられます。値とイベントはアプリ側で管理します。

### Keycap の幅

```dart
Row(children: const [
  NuiKeycap(label: 'K'),                 // 1u（既定）
  SizedBox(width: 8),
  NuiKeycap(label: 'Shift', units: 1.5),
  SizedBox(width: 8),
  NuiKeycap(label: 'Enter', units: 2),
])
```

`units` はキー間隔を含めたピッチの倍率です。標準密度では 1u = 40px、1.5u = 64px、
2u = 88px、6.25u = 292px。幅は `(controlHeight + 8) * units - 8`、高さは `controlHeight + 2` です。
0.5u 以上の有限値を指定でき、押下状態や Rive の読み込みで配置寸法は変わりません。

### Select / ComboBox

入力枠・候補パネル・行・チェック表示・スクロールを共通実装にしています。
Select はホストが値を管理する選択専用、ComboBox は文字入力で候補を絞り込めます。
上下キー、Home / End、Enter、Escape、無効候補のスキップに対応します。
候補面は `.pen` に合わせて角丸6px、行高36px（拡大文字では伸長）、入力枠との間隔8pxです。

![共通の候補面を使うSelect](example/screenshots/select.png)

[ComboBoxの候補面](example/screenshots/combobox.png)・[Rive無効時の同寸描画](example/screenshots/static.png)も確認できます。

## 実装内容

- 全48 Widget: controls / inputs / navigation / layout / data / feedback。
- 正本JSONから生成した271トークン。4色テーマ、3密度、OSに追従するreduced motion。
- Manrope、IBM Plex Sans JP（400 / 500 / 600）をライセンスと共に同梱。
- Lucide 16px。`forui_lucide` はアイコン資産だけを供給し、ForuiのUI部品には依存しません。
- ボタンの配置領域は標準50px（操作面40＋底面2＋上下フォーカス余白8）。
- メニュー、検索、ショートカット記録、数値入力、ノブ、ツリー、リサイズ境界の操作。
- 表は固定ヘッダー＋遅延行構築。行の安定ID・選択・ソート通知をホストが管理。
- 通知のhover/focus中のタイマー停止、ダイアログの安全な初期フォーカスを指定するAPI。
- `example/lib/main.dart` に48部品、テーマ・密度・motion・Riveの切替、タスク状態の操作プレビュー。

## ギャラリーを実行

開発環境: Flutter 3.50.0-0.3.pre / Dart 3.14.0-294.0.dev。
この環境のSDKと既存のLucide資産に合わせ、Flutter >=3.47.0-0 / Dart >=3.13.0-0です。

```sh
cd example
flutter pub get
flutter create --platforms=linux,macos,windows .
flutter run -d linux
```

プラットフォームのランナーは実行するホストOSで生成してください。
ATELIER-STUDIO側の既存UIの置き換えは行っていません。

## Rive

`assets/rive/detent.riv` はRive CLI 1.8.0で生成した、スクリプトなしのランタイムファイルです。
編集可能な制作ソースは `rive/detent/scene.rml`、プロパティとアニメーションの一覧は `assets/rive/manifest.json` にあります。
39アートボードに、機構・進捗・状態アイコン・15種の数字／記号を収録しています。

| 部品 | Riveの役割 |
|---|---|
| Button / IconButton / ToggleButton / Keycap | 押下60ms・復帰120ms、hover輪郭90ms。ラベルはFlutter側で保持 |
| Checkbox / RadioGroup / Switch | 選択120–160ms、mixed状態、スイッチのつまみ移動、押下フィードバック |
| SegmentedControl / Tabs | 選択面の追従160ms、タブの選択下線 |
| Slider / RangeSlider / RotaryKnob | 実際の値へ即時追従、操作中のつまみの反応 |
| Progress / Button loading | 実進捗、進捗不明時だけ動く帯・回転弧 |
| DotMatrix | 可変の数字・小数点・%等をDigitアートボードで構成、字形の出現 |
| Meter / TaskStatus | 実値に同期する標準32本のバーと、待機・処理中・成功・失敗・取り消しの機構 |
| InlineAlert / EmptyState / Skeleton / TreeView | 状態アイコン、空状態の初回表示、読み込み中の掃引、展開矢印 |

追加の初期化なしで `NuiApp` / `NuiThemeData` の `riveEnabled: true` が既定です。
Flutter描画へ切り替えるには `NuiApp(riveEnabled: false, home: ...)`、
既存アプリの一部なら `data.copyWith(riveEnabled: false)` を指定します。

Flutterは値・イベント・編集・Focus・Semanticsを保持します。Riveが読み込まれても、
ネイティブ入力の同じelementを保ち、描画だけを切り替えます。アニメーション終了を待たずホストへ通知し、
切り替え途中の反転にも対応します。通常ボタンはSpace / Enterを離した時点で確定し、Escapeで中止できます。

高コントラスト、reduced motion、Rive無効化、読み込み失敗ではFlutter描画へフォールバックします。
ファイルは使用中共有し、controller / view model / bindingは各部品で分離・破棄します。
画面外・TickerMode無効・バックグラウンドではRiveを停止し、復帰時に現在の値を反映します。
待機・完了したタスクでは回転せず、メーターは架空の値を生成しません。

独自の描画にも `NuiRiveArtwork` を利用できます。描画はIgnorePointer / ExcludeSemantics付きで、
ラベルや操作はホスト側に用意してください。

```dart
SizedBox(
  width: 96, height: 96,
  child: NuiRiveArtwork(
    artboard: 'RotaryKnob',
    state: NuiSkinState(value: zoom / 100),
    fallback: Icon(FLucideIcons.circle),
  ),
)
```

`pressed` / `selected` / `hovered` / `focused` / `enabled` は真偽値、
`value` / `secondaryValue` / `progress` は0…1です。mixedは `selectionState: 2`、
`TaskGlyph` の `taskState` はidle=0 / running=1 / success=2 / error=3 / canceled=4 / canceling=5。
操作面の寸法と色はFlutterから供給し、文字数や密度が変わっても角丸や押下量を引き伸ばしません。
メーターのバー本数を標準32以外に指定した場合は、指定本数のFlutter描画を保持します。

`rive` runtimeは0.14.11に固定。Linuxの初回テスト前は `dart run rive_native:setup --platform linux` を実行します。

```sh
python3 tool/generate_tokens.py
python3 tool/generate_rive.py
rive rive/detent --verify
rive inspect rive/detent --json
rive rive/detent --once
python3 tool/render_motion_preview.py  # Rive CLI + ffmpegでGIF再生成
```

Riveアカウントへのpush・publishは行いません。ローカルの未署名・スクリプトなしファイルです。

## 検証

パッケージルートから実行します（RiveのLinuxテストライブラリ探索の基準位置です）。

```sh
flutter analyze
flutter test
flutter test example/test/gallery_test.dart
```

テスト範囲: 押下cancel・二重発火抑制・外部値更新・キーボード・数値制約・通知タイマー・
表の遅延構築・メニュー終了・Rive障害時代替・39アートボードの実runtime読込とdata binding、実際の機構移動・途中反転・画面外／背景停止・フォーカス維持。
ギャラリーは4テーマと文字200%、幅1024 / 1440 / 1920を確認します。
OS実機のIME・スクリーンリーダー・DPI・性能測定は別途必要で、Verified認定ではありません。

設計の根拠: `DESIGN_SYSTEM.md`、`SPECIFICATION.md`、`ui_design.pen`、`component_registry.json`。
