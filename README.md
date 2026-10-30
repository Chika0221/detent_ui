# Detent Design System

Flutter デスクトップ向けの UI パッケージ。`ui_design.pen` の48部品（C01–C48）を
`Nui` 接頭辞の Widget として実装しています。デザイン版は0.4、初期実装版は0.5.0です。

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

この4枚は通常コンポーネントのFlutter描画です。Rive素材のプレビューは、実行したギャラリーの末尾にあります。

## 基本的な使い方

```dart
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

既存アプリでは `NuiTheme(data: data, child: Theme(data: data.materialTheme, child: ...))`
を対象領域へ配置します。値とイベントはアプリ側で管理します。状態管理ライブラリへの依存はありません。

## 実装内容

- 全48 Widget: controls / inputs / navigation / layout / data / feedback。
- 正本JSONから生成した271トークン。4色テーマ、3密度、OSに追従するreduced motion。
- Manrope、IBM Plex Sans JP（400 / 500 / 600）をライセンスと共に同梱。
- Lucide 16px。`forui_lucide` はアイコン資産だけを供給し、ForuiのUI部品には依存しません。
- ボタンの配置領域は標準50px（操作面40＋底面2＋上下フォーカス余白8）。
- メニュー、検索、ショートカット記録、数値入力、ノブ、ツリー、リサイズ境界の操作。
- 表は固定ヘッダー＋遅延行構築。行の安定ID・選択・ソート通知をホストが管理。
- 通知のhover/focus中のタイマー停止、ダイアログの安全な初期フォーカスを指定するAPI。
- `example/lib/main.dart` に48部品、テーマ・密度・motionの切替、Riveプレビュー。

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

`assets/rive/detent.riv` は Rive CLI 1.8.0 で生成した、スクリプトを含まない実際のランタイムファイルです。
`rive/detent/scene.rml` は編集可能な制作ソース、`manifest.json` は16アートボードとプロパティの契約です。
Button / IconButton / ToggleButton / Keycap / SegmentedControl / Checkbox / RadioGroup /
Switch / Slider / RangeSlider / RotaryKnob / Tabs / Progress / DotMatrix / Meter / TaskStatus を含みます。

通常のWidgetはFlutter描画で単独動作します。Riveは `NuiRiveArtwork` で明示的に組み込めます。
現時点では通常の48 Widgetが内部でRiveを自動使用する構成ではなく、ギャラリー末尾に独立したRiveプレビューを配置しています。
CLIでRMLから素材を制作し、Flutter用アダプターから状態を渡すところまで実装しています。
Buttonはpressed、Switch等はselected、ノブ等はvalue、進捗系はprogress（いずれも0…1）を渡します。
Riveにはラベルや業務イベントを置かず、Flutter側に保持してください。
DotMatrixのRive見本は68%の固定図形です。可変文字には `NuiDotMatrix(text: ...)` を使います。
hover/focus/enabled/motionScaleは契約を用意していますが、全状態をRive内で演出するものではありません。
高コントラスト・reduced motion・非表示・読込失敗は指定したFlutter fallbackを使います。

```dart
SizedBox(
  width: 96, height: 96,
  child: NuiRiveArtwork(
    artboard: 'RotaryKnob',
    state: NuiSkinState(value: zoom / 100),
    fallback: NuiRotaryKnob(value: zoom, onChanged: setZoom),
  ),
)
```

RiveArtworkは装飾専用（IgnorePointer / ExcludeSemantics）です。操作を持つ場合はホストの
Focus / GestureDetector / Semanticsで囲むか、Flutter Widgetを使ってください。
ファイルは使用中共有し、各インスタンスのcontroller / view modelは分離・破棄します。
`rive` runtimeは0.14.11に固定。Linuxの初回テスト前は `dart run rive_native:setup --platform linux` を実行します。

```sh
python3 tool/generate_tokens.py
python3 tool/generate_rive.py
rive rive/detent --verify
rive inspect rive/detent --json
rive rive/detent --once
rive rive/detent --artboard=Switch --data=selected=true --screenshot=/tmp/switch.png --advance=20
```

`rive push` / publishは実行していません。ローカルの未署名・スクリプトなしファイルです。

## 検証

パッケージルートから実行します（RiveのLinuxテストライブラリ探索の基準位置です）。

```sh
flutter analyze
flutter test
flutter test example/test/gallery_test.dart
```

テスト範囲: 押下cancel・二重発火抑制・外部値更新・キーボード・数値制約・通知タイマー・
表の遅延構築・メニュー終了・Rive障害時代替・16アートボードの実runtime読込とdata binding。
ギャラリーは4テーマと文字200%、幅1024 / 1440 / 1920を確認します。
OS実機のIME・スクリーンリーダー・DPI・性能測定は別途必要で、Verified認定ではありません。

設計の根拠: `DESIGN_SYSTEM.md`、`SPECIFICATION.md`、`ui_design.pen`、`component_registry.json`。
