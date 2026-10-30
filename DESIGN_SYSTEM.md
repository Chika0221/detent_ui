# Detent Design System


> 実装追記（0.5.0）: C01–C48のFlutter Widget、トークン生成、16 Riveアートボード、ギャラリーを追加しました。以下はデザイン版0.4策定時の記録です。現在のAPI・実装範囲・検証上の制限はREADME.mdを参照してください。
版: 0.4 / 2026-10-30 / 状態: 設計基盤ドラフト

## 1. システムの目的

Flutterのデスクトップアプリで、一貫した画面を継続して設計・実装・改善するための共通基盤とする。既存の「触覚的なインダストリアルUI」、Manrope＋IBM Plex Sans JP、基本padding 8pxを継承する。見た目だけでなく、選び方、組み合わせ方、振る舞い、変更方法を定義する。

DS名は **Detent Design System**、Flutterパッケージ名は **`detent_ui`** に確定した。保存先は既存の `~/dev/flu/packages/new_ui_pack/` とする。

今回の成果物は設計・トークン・パターン・運用仕様。Flutter Widget、実行可能な `.riv`、コード生成パイプライン、OS実機検証は未実装である。「デザインシステムとしての設計基盤」と「利用可能な実装ライブラリ」を区別する。

## 2. システムの5層

| 層 | 定義するもの | 利用者が判断すること |
|---|---|---|
| Foundations | 色、書体、余白、形、アイコン、動き | どの表現がこのシステムらしいか |
| Semantic tokens | 役割とテーマに応じた値 | その色や寸法は何を意味するか |
| Components | 再利用可能な部品と状態・操作契約 | どの部品を選ぶか |
| Patterns | 複数部品で構成する画面・タスク | 部品をどう組み合わせるか |
| Governance | 変更、審査、版、移行、品質 | 一貫性をどう維持するか |

部品を追加する前に、既存の部品・variant・パターンで解けるか確認する。業務データやアプリ独自の状態はホスト側に置く。

## 3. 設計原則と判断基準

1. **構造を見せる。** 操作面、表示面、領域の境界に意味を持たせる。
2. **入力に応える。** 動きは操作や実状態に同期し、待ち時間を作らない。
3. **色を役割に割り当てる。** 黄色は主要操作・選択、赤は危険・失敗、緑は完了。形・文字を併用する。
4. **読めることを優先する。** 通常の文字をドットや装飾書体に置き換えない。
5. **密度を選べる。** デスクトップの情報量と、読みやすい操作領域を両立する。
6. **仕組みを共有する。** 新しい画面ごとに色・角丸・動きの規則を作らない。

Nothingの構造美、AULAの操作モジュール、提示されたRive作例の反応性を着想源とする。固有のロゴ・書体・製品形状をコピーしない。

## 4. トークンの構造と正本

正本は `design_tokens.json`。`design_tokens.resolved.json` は参照を解決した確認用スナップショット。`.pen` の共通変数・部品は、これらの値に対応させる。

```text
primitive.color.yellow
       ↓
semantic.light.color.action.primary
       ↓
component.light.button.primary.background
       ↓
DS/Button/Primary → Settings / Task / Workspace
```

| 名前空間 | 役割 | 例 |
|---|---|---|
| primitive | 素材となる値 | space.s8、font.latin、color.yellow |
| semantic.light / dark | 標準テーマの用途 | color.text.primary、color.border.control |
| semantic.highLight / highDark | 高コントラストテーマの用途 | color.bg.raised、color.focus.ring |
| component | 部品に適用する役割 | button.primary.background、input.padding |
| density | 密度ごとの寸法 | standard.controlHeight、compact.controlHeight |
| motion | 動きを減らす場合を含む方針 | reduced.duration、full.loopWhenVisible |
| layer | 重なりの相対順序 | popover、menu、dialog、tooltip |

`$type`・`$value`・`{path.to.token}` の参照にはDTCG 2025.10の語彙を用いる。色はsRGBオブジェクト、寸法は値とpx、時間は値とmsで保持する。テーマの切り替えは本プロジェクトの明示的な名前空間による。外部ツールのテーマ解決や仕様の全機能を実装したと主張しない。

値の変更は正本→参照解決→`.pen`反映→スクリーンショット比較の順で行う。現段階では自動同期のCIはなく、添付スナップショットとレポートを更新する運用とする。`.pen` だけを変更して正本へ戻さない変更を避ける。

## 5. Foundations

### 5.1 色とコントラスト

- canvas / surface / raised / displayで背景の役割を分ける。
- border.subtleは非操作の区切り。入力枠や選択の識別にはborder.controlを使う。
- text.primary / secondary / inverseを用途で選ぶ。disabled用の低コントラスト文字を補足本文へ流用しない。
- primaryの黄色上には濃色の文字を使う。黄色だけの線をフォーカス表示にしない。
- 状態色をグラフのカテゴリ色へ無条件に流用しない。データ可視化を追加する際は系列用トークンと凡例・線種を別途定義する。
- 本文は4.5:1、操作の識別に必要な境界・状態・フォーカスは3:1以上を基準に確認する。

32組の代表的な前景／背景の組み合わせを計算し、`token_validation.json` に記録した。これは指定した色の組み合わせの確認であり、全画面のWCAG適合やスクリーンリーダー対応の認証ではない。標準の補足文字色を#5F6765、操作境界を#707974へ調整し、面の色との組み合わせを確保する。

### 5.2 文字

| 役割 | 英数字 | 日本語 | サイズ / weight |
|---|---|---|---|
| Page | Manrope | IBM Plex Sans JP | 32 / 600 |
| Section | Manrope | IBM Plex Sans JP | 20 / 500 |
| Component title | Manrope | IBM Plex Sans JP | 14 / 600 |
| Body | Manrope | IBM Plex Sans JP | 14 / 400 |
| Control | Manrope | IBM Plex Sans JP | 14 / 500 |
| Caption | Manrope | IBM Plex Sans JP | 12 / 400 |
| Instrument value | Manrope / 独自ドット | 通常は英数字 | 20–48 / 500 |

単位、ショートカット、数字にも同じ書体を使う。ドット文字は短い数値や状態に限定する。実装ではテキスト倍率200%でも操作と内容を失わず、フォントのライセンスを配布物へ含める。

### 5.3 余白・形・アイコン

- 基本paddingとgapは8px。セクション間24px、パネル間16px、ページ内側24pxを標準案とする。
- 標準操作高さ40px、compact32px、comfortable44px。compactはキーボード・マウス中心の密な領域で明示的に選ぶ。
- 入力・ボタンの角丸6、メニュー8、パネル10、筐体14。円やピルは機構・選択に用途を絞る。
- 線幅1、キーの見かけの厚み2、フォーカス幅2＋offset2。これらは8px刻みの対象外。
- Lucide 16pxを基準にする。文字記号の「＋」「歯車」等でアイコンを代用しない。
- アイコンのみの操作にはtooltipとsemantic labelを設ける。

### 5.4 フォーカスの色

フォーカスは青を使わず、ライトでは#5F6765、ダークでは#C4CBC7のニュートラルなグレーを使う。高コントラストでは明るい背景に黒、暗い背景に白を使う。2pxの輪郭と2pxのoffsetを維持し、黄色の選択面と区別する。意味のあるフォーカス表示を消したり、色だけを極端に薄くしたりしない。

### 5.5 Elevationと配置領域

厚みのある部品は、操作面、描画される本体、フォーカスを含む配置領域を分ける。

| 領域 | 標準ボタン | 用途 |
|---|---|---|
| Surface | 高さ40px | 文字・アイコンの中央揃え、押下する面 |
| Physical body | 高さ42px | 操作面40px＋下方向の底面2px |
| Layout bounds | 高さ50px | 本体42px＋上下各4pxのフォーカス領域 |

幅にも左右各4pxを加える。操作面幅144pxのボタンなら配置幅は152px。4pxはfocus stroke 2px＋offset 2pxであり、内容のpadding 8pxとは別の領域である。

通常・hover・押下・フォーカスで配置領域を変えない。押下中は面だけを2px動かし、底面と周囲の部品を動かさない。親のpaddingやgapは50pxの配置領域の外側から測り、フォーカス時だけmarginを追加しない。

横並びでは操作面の中央を揃え、親の行の高さには最大の配置領域を確保する。入力欄の40pxと、厚み付きボタンの配置領域50pxを同じ高さとして扱わない。

`component.*.button.height` は配置高さ50pxを表し、操作面には `button.surfaceHeight`、本体には `button.physicalHeight` を使う。`semantic.*.dimension.control.height` は既存の操作面・入力の40pxとして保持する。

ノブとスライダーは、底面・目盛り・つまみの実外形の和集合を取り、フォーカス領域を加える。将来blur shadowを追加するときも、操作面だけの寸法でclip・配置を決めない。装飾の影をhit test領域として扱うかは入力契約と分離する。

DS08に、上の部品→厚み付きボタン→下の部品をgap 8pxで縦積みした確認用パターンを追加した。pen.dev実測で3状態とも子要素のy位置が8 / 56 / 114px、高さが40 / 50 / 40pxで一致することを確認した。Flutter実装での検証は別途必要である。

## 6. テーマ・密度・重なり

| 軸 | 値 | 振る舞い |
|---|---|---|
| Appearance | light / dark / system | 色の役割を維持し、OSへの追従を選べる |
| Contrast | normal / high | 不要な陰影を減らし、境界と文字を明確にする |
| Density | compact / standard / comfortable | 文字を小さくして密度を上げず、領域の寸法を変える |
| Motion | full / reduced / system | reducedは位置変化・ループを止め、状態を即時表示 |

appearanceとcontrastの組み合わせは4つの明示的なトークン群で扱う。density・motionは独立した方針とする。

layerの数値はUI内の相対順序であり、OSウィンドウ順序ではない。base → sticky → popover → menu → dialog → toast → tooltip。modal中のtoastはフォーカスを奪わない。tooltipやmenuが画面外へ出る場合は配置を反転・制限し、内容を欠落させない。

## 7. コンポーネントの契約

既存48部品の用途・優先順位は `SPECIFICATION.md` を参照する。`.pen` のC番号付きセットは比較・レビュー用として保持する。追加した `DS/` 部品は単一状態の再利用シンボルとし、パターン画面ではrefを使って配置する。

各部品は、用途、使わない場面、variant、size、state、slot、入力、イベント、Focus、Semantics、motion、fallback、token binding、使用例、変更履歴を持つ。

| 判断 | 選ぶもの |
|---|---|
| 即時の実行 | Button |
| 別の場所へ移動 | Link / Navigation item |
| 即時適用する二値設定 | Switch |
| フォームで送信する複数選択 | Checkbox |
| 少数の排他的な表示モード | Segmented control |
| 内容領域の切り替え | Tabs |
| 選択肢が多い | Select / ComboBox |
| 一時的な補助設定 | Popover |
| 作業を中断して判断が必要 | Dialog |
| 解消するまで残すべき問題 | InlineAlert |
| 完了や取り消し可能な操作 | Toast |

通常・hover・press・focus・disabledは入力状態、selected/checked/mixedは値の状態、loading/success/errorは処理状態として分離する。見た目の組み合わせを確認するだけでなく、実装時には連打・cancel・外部値更新も検証する。

## 8. デスクトップの操作とアクセシビリティ

- Tab / Shift+Tabでグループ間を移動し、矢印キーで複合部品内を移動する。
- Enter / Spaceは部品の意味に応じて確定する。Escapeは一番手前の一時的なレイヤーを閉じる。
- 閉じたmenu・dialog・paletteは起点へフォーカスを戻す。modalだけがフォーカスを閉じ込める。
- 右クリックの操作はShift+F10やmenu buttonからも開けるようにする。
- スライダー・ノブ・分割境界にキーボード操作を用意する。ホイールが値を変えるのはフォーカス時のみを初期方針とする。
- Windows/LinuxのCtrl、macOSのCommandをホストで解決する。表示文字をハードコードして業務ショートカットを固定しない。
- ドラッグだけに依存せず、リストの並べ替え等には代替コマンドを提供する。
- 選択とフォーカスは別の状態であり、片方が片方を隠さない。
- 意味、値、状態、ラベル、エラーの関連付けをFlutter側のSemanticsで提供する。
- 本文の読み上げ・日本語IME・拡大・高コントラストは実装検証項目として残す。

## 9. Riveとモーション

Flutterが真の値・イベント・Focus・Semantics・文字編集を所有し、Riveは描画と遷移を担当する。アニメーション終了が業務処理の条件になってはいけない。

| 用途 | 初期値 | 原則 |
|---|---|---|
| Press | 60ms | 約2px沈む |
| Hover | 90ms | 面と輪郭を変える |
| Release | 120ms | 現在位置から元へ戻る |
| Selection | 160ms | 選択面・機構を移動 |
| Overlay | 140ms | 読める状態を早く出す |
| Complete | 220ms | 実際の完了を表示へ反映 |
| Reduced | 0ms | 最終状態を表示、ループ停止 |

easing.standardは[0.2, 0, 0.2, 1]。指に追従するノブやスライダーの入力値には遅延補間を加えない。非表示・最小化時のループを停止し、初期化失敗時は同寸法・同Semanticsの静的スキンへ切り替える。

Rive manifestにはasset/artboard/viewmodel、型付き入出力、初期値、対応runtime、fallback、ライセンス、所有者、版を記録する。`.pen` のモーション板は制作指示であり、再生可能なRiveファイルではない。

## 10. 画面パターンとテンプレート

### 10.1 デスクトップの領域

ページ内側24、パネル間16。navigationは幅240を基本に200–320、inspectorは288を基本に240–400、作業領域は最低480を目安にする。3領域を保てない幅ではinspectorを明示的に開く補助面へ切り替える。隠した内容や選択を失わない。

代表画面幅1024 / 1440 / 1920で確認する。固定幅のWebページに縮小して当てはめず、パネルの最小幅とスクロールを設計する。

### 10.2 Settings form

説明→関連する項目→操作の順序とし、保存が必要な設定と即時反映の設定を混ぜる場合は明示する。エラーは対象フィールドの近くに置き、内容を維持して最初のエラーへ案内する。「保存」と「キャンセル」の位置・順序を維持する。未保存の変更があるときだけ離脱を確認する。

### 10.3 Master–detail

一覧・選択した内容・補助設定を並べる。選択は安定IDで保持し、sortや読み込みで別項目へ飛ばさない。loading / empty / filtered-empty / error / readyを区別する。フィルターなしの空状態と検索結果なしでは次の操作が異なる。

### 10.4 Long-running task

実状態をidle / running / canceling / canceled / success / errorへ写像する。進捗不明を百分率で偽装しない。処理の取り消しと元に戻す操作を区別する。成功してから完了表示を出す。失敗時には理由、維持された入力、再試行を示す。

### 10.5 Search and command

検索は対象データ、paletteは実行可能な操作を扱う。最近使ったもの・候補なし・権限不足を区別する。画面のボタンと同じ操作名を使い、キーボードだけで選択・確定・終了できるようにする。

### 10.6 Destructive confirmation

対象名・件数・回復可能性を短く示す。「はい」ではなく「削除」のような操作名を使う。初期フォーカスは安全な選択肢へ置く。通常の保存を何度も確認させない。

## 11. コンテンツと状態の伝え方

| 状態 | 文言の型 | 例 |
|---|---|---|
| 成功 | 完了した内容 | 変更を保存しました |
| 失敗 | できなかったこと＋回復操作 | 保存できませんでした。保存先を確認して再試行してください。 |
| 空 | 現状＋最初の操作 | まだ項目がありません。最初の項目を作成します。 |
| 検索なし | 条件＋変更方法 | 一致する項目がありません。検索条件を変更してください。 |
| 処理中 | 実際の作業＋進捗 | 書き出し中 / 17 / 25 files |

操作名を画面・menu・paletteで統一する。理由のない感嘆符、曖昧な「エラーが発生しました」、色だけの通知を避ける。tooltipだけに必須説明を隠さない。

## 12. 品質・成熟度・運用

### 12.1 成熟度

Draft → Design reviewed → Implemented → Verified → Deprecated。

今回追加したDS部品とパターンはDraft。既存48部品も実装済みとは扱わず、設計見本として保持する。`component_registry.json` に設計と実装の状態を別々に記録する。

### 12.2 変更手順

1. 問題・使用場面・既存部品で解けない理由を記録する。
2. token / variant / component / patternのどの変更か選ぶ。
3. 全状態、light/dark/high contrast、keyboard/reduced motionを設計する。
4. スクリーンショットと互換性・移行案を確認する。
5. 正本・`.pen`・仕様・registryを同じ版へ更新する。
6. 実装とOS検証が完了してからVerifiedへ進める。

責任者はプロジェクトのmaintainerが担当し、特定の個人をこの時点で指名しない。

### 12.3 版と互換性

0.xは設計の反復期間。token名・API名・挙動の変更には、変更理由と移行方法を添える。公開後は削除より非推奨と代替を先に示し、原則2回のminor版を経て削除を検討する。これは初期運用案であり、正式配布前に確定する。

### 12.4 リリースの確認条件

- aliasの欠落・循環・型不一致がない。
- 代表色の組み合わせのコントラストを確認し、画面では画像・透明・hover/focusを含めて別途確認する。
- 部品の文字・アイコン・選択面の配置と長い日本語を確認する。
- interaction / semantics / fallback / motion / IMEの実装検証を行う。
- profileモードのフレーム時間とメモリ、controllerの破棄を検証する。
- token・registry・docs・`.pen`・実装の版に食い違いがない。

## 13. 成果物と次の実装単位

| ファイル | 用途 |
|---|---|
| DESIGN_SYSTEM.md | 全体の方針、選択基準、パターン、運用 |
| SPECIFICATION.md | 既存48部品の詳細な初期仕様 |
| design_tokens.json | primitive / semantic / componentの正本 |
| design_tokens.resolved.json | 参照を解決した確認用の値 |
| token_validation.json | aliasと代表色の計算結果 |
| component_registry.json | 部品・patternの対応と成熟度 |
| ui_design.pen | 元の8ボード＋デザインシステムの9ボード |
| design_system_overview.png | 追加したシステムボードの一覧 |

次は、Theme・Focus・MotionPolicyの基盤とButton / TextField / Switchの実装を最小単位として検証する。その後、Settings formとMaster–detailへ広げる。大量の部品を先に実装し、最後にトークンへ寄せる順序を避ける。

## 14. 参照

- DTCG 2025.10: https://www.designtokens.org/TR/2025.10/format/
- W3C Contrast Minimum: https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html
- W3C Non-text Contrast: https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html
- 既存のAULA / Rive / Nothing参照はSPECIFICATION.mdに記載。
