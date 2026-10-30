# detent_ui — デスクトップUIパッケージ仕様書

> 実装追記（0.8.0）: 人が操作するUIの動きはFlutterで実装。RiveはProgress・Meter・Skeleton・TaskStatusの処理表示に限定し、実値を保った光・ドット波・掃引を使用します。以下の旧Rive分類は設計時の記録で、現行APIはREADME.mdを参照してください。


> 実装追記（0.5.0）: C01–C48のFlutter Widget、トークン生成、16 Riveアートボード、ギャラリーを追加しました。以下はデザイン版0.4策定時の記録です。現在のAPI・実装範囲・検証上の制限はREADME.mdを参照してください。
> 実装追記（0.6.0）: 通常の操作部へRiveを既定接続。39アートボード、可変数字、画面外／背景停止、reduced motion代替描画、Rive比較ギャラリーを追加。APIと検証範囲はREADME.mdを参照してください。
> 実装追記（0.7.0）: Material Widget依存を除去しWidgetsAppのみで利用可能にしました。Select / ComboBoxの候補パネルを共通化し、Keycapにunits（1u / 1.5u / 2u等）を追加。使用例と移行点はREADME.mdを参照してください。
作成日: 2026-10-30 / 版: 0.4（デザインシステムへ拡張）


本書は48部品の詳細仕様です。全体の判断基準・テーマ・トークン・画面パターン・運用は `DESIGN_SYSTEM.md`、値の正本は `design_tokens.json` を参照してください。`.pen` は既存8ボード＋システム9ボードの計17ボードです。

## 1. 目的と合意事項

Flutter製アプリケーション ATELIER-STUDIO で利用する、新しい独立したUIパッケージを設計する。デスクトップの長時間作業に適し、精密な道具を操作する手触りと、幾何学的な遊び心を併せ持つ部品群を提供する。

合意済みの要件は、Flutter、デスクトップ専用、新規UIパッケージ、Riveの積極的な活用、豪華さを目指さない表現、提示された機器・Rive作例・Nothingへの親和性である。それ以外の寸法、色、API名、対応OS、優先順位は、本書による初期提案とする。

成果物は本書と `ui_design.pen`。`.pen` は編集可能な静的デザイン・状態見本であり、再生できる `.riv` やFlutter実装は含まない。本書を実装契約の出発点とする。

## 2. デザインコンセプト

**触覚的なインダストリアルUI — 精密な機器の構造を、軽快なデスクトップ操作へ。**

白・グレー・黒の面、明確な輪郭、細い目盛り、控えめな厚みを組み合わせる。Riveを通じて、押し込み・回転・切り替え・進捗に手応えを与える。静止中は整っており、操作すると部品の仕組みが感じられる。

Nothingからは、構造を見せる考え方、モノクロを中心とした構成、ドットによる情報表現、機能に結びついた光を参考にする。ロゴ、固有の書体、Glyphの形状、製品外観は複製せず、本パッケージ独自の形へ翻訳する。

### 2.1 表現の原則

1. **構造が見える。** 操作面・表示面・筐体の役割を、枠や溝、区切りで示す。
2. **触れる部品に厚みを与える。** 立体表現はキー・ノブ・スイッチなどに集中し、文章や表は平面的に保つ。
3. **少ない色を機能に割り当てる。** 黄色は主要操作・選択、赤は危険・エラー。色だけで状態を伝えない。
4. **動きは入力に結びつく。** 押下中に沈む、ドラッグに追従する、実進捗に同期する。待ち時間を演出で増やさない。
5. **文字を読めるままにする。** ドット表現は短い数値や状態に限定し、本文・入力・エラーは通常の文字にする。
6. **機器らしさに意味を持たせる。** 目盛りは値、ランプは状態、区切りは領域を示す。無意味なネジや疑似配線を増やさない。

避ける表現: 多色発光、常時点滅、金属の強い反射、全面のガラスぼかし、全カードへの大きな影、画面全体の3D化、操作ごとの長いバウンド。

### 2.2 参考と抽出する要素

| 参考 | 採用する考え方 |
|---|---|
| AULA NEOS75 | 整列したキー、操作モジュール、白黒の表示面、局所的な差し色 |
| Rive Audio Player | 操作部と表示部の分離、ノブと目盛り、押し込めるボタン |
| Rive Interactive Car UI | 罫線・計器・数値の秩序、実データと表示の連携 |
| Rive Mini Keyboard | 厚みと沈み込みによる押下の理解しやすさ |
| Rive RISKOXIDE | 円と文字の明快な構成、入力に対する大胆だが局所的な変形 |
| Nothing | 構造の可視化、ドット、抑制された色、状態を示す光 |

## 3. 対象環境と責任範囲

- 対象OSの初期案: Windows / macOS / Linux。対応を名乗るOSは実機またはCIで検証する。
- マウス、トラックパッド、キーボードを第一の入力手段とする。
- 表示倍率100–200%、複数DPI、ライト／ダーク、高コントラスト、動きを減らす設定を想定する。
- 1024×720以上を代表的なサンプル画面の基準とする。個々の部品はウィンドウ幅に追従し、狭い領域では明示的な最小幅・スクロールを使う。
- モバイル用画面、ルーティング、DB、認証、業務状態、ファイル操作、ネットワーク処理はパッケージに含めない。
- OSのウィンドウ枠、ドラッグ領域、ネイティブメニュー、システムトレイはホストアプリのアダプターに分離する。
- 他アプリでも利用できるよう、ATELIER固有のモデルや状態管理ライブラリに依存しない。

## 4. 基礎トークン

### 4.1 色（初期案）

| 意味 | ライト | ダーク |
|---|---|---|
| canvas | #F3F3F1 | #151719 |
| surface / 筐体 | #E5E6E3 | #24272A |
| raised / 操作面 | #FAFAF8 | #353A3E |
| display / 表示窓 | #171A1C | #0B0D0F |
| textPrimary | #202426 | #F2F4F1 |
| textSecondary | #5F6765 | #ADB6BC |
| border / 非操作の区切り | #C4C9C5 | #555D62 |
| controlBorder / 操作境界 | #707974 | #8A959A |
| accent | #E9CF48 | #E9CF48 |
| accentInk | #202426 | #202426 |
| danger | #B83238 | #FF858A |
| success | #2E6B50 | #8DD2AB |
| focus | #5F6765 | #C4CBC7 |

黄色上の文字は常に濃色。弱い区切り線は操作部の識別に使わない。実装時に本文4.5:1、主要操作境界・フォーカス3:1を検証する。数値は設計目標であり、この時点で適合認証を意味しない。

### 4.2 文字・形・寸法

- UIのラテン文字・数値・ショートカット: Manrope。日本語: IBM Plex Sans JP。通常UIでの等幅フォントの使用を廃止し、英数字と日本語の役割を固定する。配布時に実際のフォントファイルとライセンスを確認・同梱する。
- 本文・操作ラベル14px、補足12px、部品見出し14px/600、ページ見出し32px/600、代表値20–48px。説明文は過度に小さくしない。
- ドット文字は独自の5×7グリッドを短い数字に使用する。通常フォントによる同じ値をSemanticsで提供する。
- 基本の内部paddingと要素間gapは8px。ボタン・入力欄・メニュー項目のレイアウトに共通トークンとして適用する。領域を分ける余白は16 / 24 / 32 / 48pxの8px刻みとする。1pxの境界線、2pxの押下量、円形ノブの目盛りなどは機能・光学上の例外であり、paddingとして扱わない。標準の操作面・入力欄・メニュー項目は高さ40px。厚み付きボタンは本体42px、フォーカス余白込みの配置領域50pxとする。密度compactは32px、comfortableは44pxとする。小さいアイコンも操作領域は最低28×28。
- 角丸: 入力・ボタン6、メニュー8、パネル10、筐体14。ピル形状はノブ、スイッチ、状態表示に用途を絞る。
- 標準ストローク1px。押下部の見かけの厚みは2px。キーボードフォーカスは外周2px＋隙間2px。
- 影は操作部とオーバーレイの階層を示す用途に限定する。

## 5. コンポーネント一覧

接頭辞は暫定で `Nui`。P0は最初の利用に必要、P1はデスクトップ体験の充実、P2は用途に応じて追加する。Rive区分は、A=標準の動的スキン、B=任意の拡張、F=Flutter主体。すべてのA部品にも静的な代替表現を用意する。以下の48項目をデザイン対象とする。

| ID | コンポーネント | 主な用途・バリエーション | 優先 | Rive |
|---|---|---|---|---|
| C01 | NuiButton | primary / secondary / quiet / danger、loading | P0 | A |
| C02 | NuiIconButton | tooltip付き、丸／角、toggle可能 | P0 | A |
| C03 | NuiToggleButton | ツールのon/off、選択固定 | P0 | A |
| C04 | NuiKeycap | ショートカット表示／押下入力の可視化 | P1 | A |
| C05 | NuiSegmentedControl | 排他的な表示モードの切り替え | P0 | A |
| C06 | NuiCheckbox | off / on / mixed | P0 | A |
| C07 | NuiRadioGroup | 単一選択、グループ単位のフォーカス | P0 | A |
| C08 | NuiSwitch | 即時に適用される設定のon/off | P0 | A |
| C09 | NuiSlider | 連続／離散値、目盛り／値表示 | P0 | A |
| C10 | NuiRangeSlider | 上下限の指定、2つのつまみ | P2 | A |
| C11 | NuiRotaryKnob | ズーム・強度などの数値調整 | P1 | A |
| C12 | NuiNumberStepper | 数値入力、増減、単位、上下限 | P0 | F |
| C13 | NuiTextField | 一行入力、prefix/suffix、clear | P0 | F |
| C14 | NuiTextArea | 複数行、伸縮、カウンター | P0 | F |
| C15 | NuiSearchField | 検索、clear、ショートカット表示 | P0 | F |
| C16 | NuiSelect | 固定候補から選択、ポップアップ | P0 | F |
| C17 | NuiComboBox | 入力と候補選択、空／loading | P1 | F |
| C18 | NuiShortcutRecorder | キー組み合わせの記録と競合表示 | P1 | F |
| C19 | NuiFormField | ラベル、説明、必須、エラーの関連付け | P0 | F |
| C20 | NuiTabs | content / document、閉じる、未保存表示 | P0 | A |
| C21 | NuiNavigationRail | コンパクトな主要画面移動 | P1 | B |
| C22 | NuiSidebarItem | 階層、選択、件数、補助操作 | P0 | B |
| C23 | NuiBreadcrumb | 階層移動、長いパスの折り畳み | P1 | F |
| C24 | NuiMenuBar | File/Edit/View等、OS向け差し替え口 | P1 | F |
| C25 | NuiDropdownMenu | actions / checkbox / radio / submenu | P0 | F |
| C26 | NuiContextMenu | 右クリック／Shift+F10、選択に対応 | P1 | F |
| C27 | NuiCommandPalette | コマンド検索、分類、キー表示 | P1 | B |
| C28 | NuiAppShell | メニュー、ナビ、本文、補助領域、status | P0 | F |
| C29 | NuiPanel | header / content / footer、inset / raised | P0 | F |
| C30 | NuiToolbar | 操作群、区切り、overflow | P0 | F |
| C31 | NuiSplitView | リサイズ、最小幅、折り畳み | P1 | F |
| C32 | NuiStatusBar | 保存・接続・処理状態、クリック可能項目 | P1 | B |
| C33 | NuiListRow | 選択、補足、末尾操作、密な一覧 | P0 | F |
| C34 | NuiTreeView | 展開、複数選択、キーボード探索 | P1 | B |
| C35 | NuiDataTable | sort、選択、固定ヘッダー、仮想化 | P1 | F |
| C36 | NuiBadge | 件数／状態、icon＋text | P0 | F |
| C37 | NuiTooltip | hover／focus、ショートカット補足 | P0 | F |
| C38 | NuiProgress | linear / circular、確定／不確定 | P0 | A |
| C39 | NuiDotMatrix | 数字・短い状態、静的／遷移 | P1 | A |
| C40 | NuiMeter | 信号、稼働、値の範囲、目盛り | P2 | A |
| C41 | NuiToast | 完了／失敗／取り消し可能操作 | P0 | B |
| C42 | NuiInlineAlert | エラー・注意・情報と回復操作 | P0 | F |
| C43 | NuiDialog | 確認／フォーム／危険操作 | P0 | B |
| C44 | NuiPopover | 補助設定、アンカーに追従 | P0 | F |
| C45 | NuiEmptyState | 状況、説明、次の操作 | P0 | B |
| C46 | NuiSkeleton | 読み込み時のレイアウト確保 | P1 | F |
| C47 | NuiTaskStatus | idle / running / success / error / canceled | P1 | A |
| C48 | NuiScrollArea | 常時／自動スクロールバー、大量データ | P0 | F |

Theme、Typography、Icon、Divider、FocusRing、MotionPolicyは共通基盤とし、上記48部品を支える。業務固有のチャット、エディター、再生エンジン、ファイル管理は追加層で構成する。

### 5.1 見た目の共通契約（v0.3）

- UIアイコンはLucideの16pxへ統一する。文字の記号でアイコンを代用しない。
- 英数字はManrope、日本語はIBM Plex Sans JP。通常400、操作ラベル500、部品・ページ見出し600を基準にする。
- 一般の操作ラベルは14px、補足は12px。行高は操作面1.35、通常1.4–1.5とする。
- ボタンは文字＋アイコンを一つのまとまりとして中央へ配置する。ノブの値は実際の円の中心へ置く。
- 選択表示は黄色、危険操作は赤に役割を統一する。ノブの位置マークは濃色で視認性を確保する。
- 目盛りの最小・中間・最大値は独立した要素で配置し、空白文字による位置合わせを使わない。
- 8pxの基本paddingを維持し、ボタンと入力の高さ、文字サイズ、角丸を用途ごとに統一する。

### Elevationの寸法契約

標準の厚み付きボタンは操作面40px、本体42px、フォーカス余白込みの配置領域50pxとする。通常・押下・フォーカスで配置領域を変えず、親のpadding/gapはこの外側から確保する。詳細と確認例はDESIGN_SYSTEM.mdの5.5節とDS08を参照。

## 6. 共通の状態と操作契約

- 入力状態: idle / hovered / pressed / focused / disabled。
- 値の状態: selected / checked / mixed / expanded。入力状態と独立に保持する。
- 処理状態: idle / loading / success / error。loading中の重複実行を抑止し、レイアウト幅を維持する。
- disabledは操作を受けず、フォーカス順から除外する。readOnlyは選択・コピー・フォーカスを維持する。
- フォーカスはホバーや選択の色で上書きしない。各状態の組み合わせを確認する。
- ボタンのpointer downは描画のみ変更し、操作の確定は有効領域内のpointer up。cancelやドラッグアウトで元に戻す。
- Space / Enterによる操作にも同等の視覚フィードバックを与え、完了アニメーション前に業務アクションを通知する。
- 長いラベル、空ラベル、アイコンのみ、RTL、テキスト倍率200%、日本語IMEを設計時から考慮する。

### 6.1 部品ごとの重要な挙動

| 部品 | 契約 |
|---|---|
| Switch / Checkbox | 値をホストが保持。外部更新でも表示が追従し、アニメーション終了を待たず再操作できる |
| Segmented / Tabs | 左右キーで移動。内容ロードが重いタブはEnterで確定するmanual activationも提供 |
| Slider / Range | 矢印・Home/End・PageUp/Down、値の読み上げ。Rangeのつまみは交差を防ぎフォーカスを区別 |
| RotaryKnob | 上方向ドラッグで増加、下で減少。矢印と数値入力でも変更できる。円周ドラッグは任意 |
| NumberStepper | 文字入力を許し、確定時に範囲検証。locale対応。マイナス・小数の入力途中を壊さない |
| Text input | Flutterの編集・IME・選択・undo・clipboardを保持。テキストをRiveキャンバスに置き換えない |
| Menu / Palette | 矢印移動、Enter確定、Escapeで閉じる。閉じたら起点へフォーカスを戻す |
| Dialog | modal時のみフォーカスを閉じ込める。Escape・外側クリックの可否は明示指定。危険操作は初期フォーカスを安全な操作へ |
| Tree | 上下で移動、右で展開／子へ、左で折り畳み／親へ。選択とフォーカスを分ける |
| Table | ヘッダーのsort semantics、行選択、空／loading／error。大規模一覧は可視行を構築 |
| Toast | 重要な失敗は永続的なInlineAlertも併用。hover/focusでタイマー停止。読み上げを過剰に繰り返さない |
| Scroll / Split | ドラッグ以外の操作も提供。Splitはキーボードでサイズ調整、Scrollはページ移動とホイールを受ける |

## 7. Riveの設計とFlutterとの境界

### 7.1 責任の分離

Flutterが値・アクション・入力イベント・Focus・Semantics・テキスト編集・ヒット領域・オーバーレイ配置を管理する。Riveは与えられた状態の描画と遷移を担当する。操作イベントの経路を二重にせず、一度のクリックで一度だけコールバックを発火する。

Riveを積極的に使う対象は、ボタンのキー機構、スイッチ、選択インジケーター、ノブ、スライダー、進捗、ドット表示、タスク状態である。表、本文、メニュー項目、入力文字はFlutter主体とし、動的な装飾層だけを差し替えられるようにする。

### 7.2 アセット契約の初期案

実装開始時にFlutter SDKとRive runtimeの安定版を公式資料・対象OSで確認し、版を固定する。Data Bindingを優先し、未対応機能はruntimeアダプター内に閉じ込める。公開WidgetからRive固有の型を露出しない。

| プロパティ案 | 型 | 用途 |
|---|---|---|
| hovered / pressed / focused | bool | 入力状態 |
| enabled | bool | 操作可能性 |
| selected | bool | 二値選択 |
| selectionState | enum相当 | unchecked / checked / mixed |
| value / secondaryValue | number 0…1 | 単一／範囲値 |
| taskState | enum相当 | idle / running / success / error / canceled |
| progress | number 0…1 | 実際の進捗値 |
| indeterminate | bool | 進捗不明の明示 |
| themeMode / contrastMode | enum相当 | テーマ・高コントラスト |
| motionScale | number 0…1 | 動きの抑制度 |

共通のプロパティすべてを全アセットに強制せず、各部品のmanifestに必要な項目を宣言する。artboard名、viewmodel名、入出力、初期値、制約、静的fallback、版番号、所有者、ライセンスを記録する。

文字列や候補数によって横幅が変わる部品はFlutterでレイアウトし、Riveのスキンをstretchしても角や線幅が破綻しないか検証する。できないスキンは規定サイズのアイコン／つまみに限定する。

### 7.3 モーション規則（初期値）

| 変化 | 時間の目安 | 動き |
|---|---|---|
| hover | 70–100ms | 輪郭・面の変化。移動は0–1px |
| press | 50–80ms | 面が約2px沈み、厚みと影が減る |
| release | 100–140ms | 元の高さへ戻る。大きく弾まない |
| checkbox / switch | 120–180ms | 機構が切り替わり、最終状態が明快 |
| segmented / tab | 140–180ms | 選択面が次の位置へ移る |
| knob / slider | 入力へ即時追従 | release後の補間で入力を遅らせない |
| progress | 実データ同期 | 不明な進捗を百分率で捏造しない |
| task completion | 180–240ms | 稼働表示がチェック等へ収束する |
| overlay | 100–160ms | 不透明度と最大4pxの移動。内容の可読性を保つ |

反転・連打時は現在位置から新しい状態へ移る。全遷移にキャンセル経路を用意する。Riveの状態遷移が業務処理の実行条件になってはいけない。

### 7.4 動きを減らす・障害時の代替

- OS設定＋アプリ設定を共通のMotionPolicyへ統合する。
- reduced motionでは移動・拡大・ループを停止し、最終状態を即時表示する。
- 処理中は静的な「処理中」ラベルと進捗値で伝える。点滅に依存しない。
- アセット読み込み失敗／非対応runtime／初期化中は同じ寸法・値・SemanticsのFlutter fallbackを表示する。
- 高コントラストでは装飾的な透明や陰影を減らし、境界・文字・フォーカスを明示する。

## 8. テーマと公開APIの方針

`NuiThemeData` は色・文字・間隔・密度・形・motion・skinを保持する。`NuiTheme` で配布し、各部品で必要な値だけ上書きできるようにする。

代表API案（実装確定ではない）:

```dart
NuiButton(label: '保存', onPressed: save, variant: NuiButtonVariant.primary)
NuiSwitch(value: autoSave, onChanged: setAutoSave)
NuiRotaryKnob(value: zoom, min: 25, max: 200, onChanged: setZoom)
NuiTaskStatus(state: taskState, progress: progress, label: '書き出し')
```

- 値を持つ部品はcontrolledを基本とし、初期値型APIを提供する場合も同時指定を禁止する。
- `FocusNode`、`autofocus`、`semanticLabel`、tooltip、enabled/readOnlyを適切な部品に公開する。
- runtimeや状態管理の差し替えを可能にするが、内部実装を無制限に公開しない。
- 通常の部品は明示的なglobal initなしに使える。重いRiveアセットは必要時に読み込む。

構成案:

```text
lib/detent_ui.dart
lib/src/foundation/  # theme, tokens, focus, semantics, motion
lib/src/controls/
lib/src/inputs/
lib/src/navigation/
lib/src/layout/
lib/src/data/
lib/src/feedback/
lib/src/rive/        # runtime adapter, skin, cache, manifest
assets/rive/
example/            # 全状態を切り替えられるデスクトップギャラリー
test/
```

## 9. 性能・品質の受け入れ条件

- 基準は60Hzで1フレーム16.7ms以内を目標とする。検証機のCPU/GPU/OS/DPIを明記し、profileモードのp95 build/rasterをそれぞれ記録する。現時点で性能達成済みとはしない。
- アニメーションでWidgetツリー全体を再構築しない。非表示・最小化・非アクティブな処理のループを停止する。
- 50個の操作部品を配置した画面、10個の同時進捗、大量行一覧を別シナリオで計測する。
- パース済みアセットを共有し、インスタンスの可変状態は共有しない。listener、controller、rendererをdisposeする。
- 文字倍率100/150/200%、DPI100/150/200%、ライト／ダーク／高コントラスト／reduced motionで確認する。
- 日本語IME・長い文字列・スクリーンリーダー・キーボードのみの操作を対象OSごとに確認する。
- 意味のあるテスト: 状態の組み合わせ、cancel、二重発火防止、外部値更新、フォーカス復帰、値制約、fallback。goldenテストはRiveの時間を固定する。
- 各P0部品に用途・API例・全状態・キーボード操作・Semantics・Rive失敗時の挙動を記載する。

## 10. 段階的な制作順

1. **基盤と試作**: tokens、Theme、Focus、MotionPolicy。Button / Switch / Knobの3部品で見た目・Rive・fallbackを検証する。
2. **P0**: 一覧のP0部品を揃え、フォーム＋一覧＋ダイアログの代表画面を構成する。
3. **P1**: ナビゲーション、ツリー、コマンド、分割、ドット、タスク状態を追加する。
4. **P2**: RangeSlider / Meterを利用用途に合わせて追加する。
5. **統合**: ATELIER-STUDIOの小さい1画面から導入し、旧UIとの併存・段階移行を行う。全画面の一括置換は前提にしない。

## 11. ui_design.pen の収録内容

- Foundations: コンセプト、配色、文字、形、機器としての代表モジュール。
- Controls: C01–C12。通常・押下・選択・フォーカス・無効などの状態比較。
- Inputs: C13–C19。日本語、エラー、検索、候補、ショートカット。
- Navigation: C20–C27。タブ、メニュー、コマンド、階層。
- Workspace: C28–C35、C48。シェル、分割、一覧、ツリー、表の構成例。
- Feedback: C36–C47。進捗、ドット、メーター、toast、dialog等。
- Motion: 代表部品の開始／中間／終了、時間、reduced motion。
- Dark: 同じトークン体系によるダーク画面の構成例。

C番号付き48セットは状態比較用として保持する。単一状態の再利用シンボル24個と、テーマ・操作・モーション・画面パターンをDS00–DS07へ追加する。実行可能なRiveアニメーションは後工程で制作する。

## 12. 未確定事項

DS名はDetent Design System、パッケージ名はdetent_uiに確定。接頭辞の最終名称、Flutter／Riveの固定版、正式サポートOS、配布方法、ATELIER-STUDIOで最初に置き換える画面、Rive制作環境・ライセンス運用は実装開始時に確定する。黄色は初期案であり、Nothingの嗜好を踏まえた赤アクセントのテーマも後から独立して比較できる。

## 13. 参照

- https://www.aulastar.com/mechanical-keyboard/1012.html
- https://www.aulastar.com/uploads/allimg/20261023/1-261023153922K4.jpg
- https://www.aulastar.com/uploads/allimg/20261023/1-261023153923A0.jpg
- https://www.aulastar.com/uploads/allimg/20261023/1-261023153924364.jpg
- https://rive.app/marketplace/28160-53178-audio-player/
- https://rive.app/marketplace/21638-40721-interactive-car-ui/
- https://rive.app/marketplace/20457-38476-mini-keyboard/
- https://rive.app/marketplace/11636-22271-riskoxide/
- https://nothing.tech/
- https://nothing.tech/products/headphone-1-pro
- https://docs.pencil.dev/for-developers/the-pen-format

参考はデザイン分析のために使用する。外部の画像・Riveアセット・ブランドフォントの再配布権を取得したことは意味しない。今回のデザインは外部画像を埋め込まず、独自のベクター部品で作成する。
