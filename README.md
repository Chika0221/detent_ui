# Detent Design System 0.4

Flutterデスクトップアプリ向けのデザインシステム設計基盤です。DS名は **Detent Design System**、パッケージ名は **`detent_ui`** です。触覚的なインダストリアルUI、Manrope＋IBM Plex Sans JP、基本padding 8pxを継承しています。

## まず開くもの

1. `DESIGN_SYSTEM.md` — 全体の方針・トークン・操作・パターン・運用。
2. `ui_design.pen` — pen.devで編集できる全17ボード。
3. `design_system_overview.png` — 追加したシステム9ボードの一覧。

## ファイル

| ファイル | 内容 |
|---|---|
| DESIGN_SYSTEM.md | 5層の体系、テーマ、アクセシビリティ、Rive、画面パターン、変更・移行ルール |
| SPECIFICATION.md | 既存48部品の詳細仕様 |
| design_tokens.json | 271トークンの正本。素材→役割→部品の参照 |
| design_tokens.resolved.json | alias解決済みの確認用値 |
| token_validation.json | alias・型・代表32組の色の確認結果 |
| component_registry.json | 48見本セット、24単一状態シンボル、2画面パターンの対応と状態 |
| ui_design.pen | 元の8ボードと追加9ボード、再利用部品とrefによる構成 |
| design_overview.png | 元の8ボードの一覧 |
| design_system_overview.png | 追加9ボードの一覧 |

## キャンバス

左側2列は既存の8ボードです。部品の状態比較と当初の画面例を保持しています。

右側2列はデザインシステムの9ボードです。

- DS00 — A system for desktop work
- DS01 — Foundations & tokens
- DS02 — Color roles & themes
- DS03 — Core library
- DS04 — Interaction & accessibility
- DS05 — Motion & Rive contracts
- DS06 — Pattern / Settings
- DS07 — Pattern / Master–detail
- DS08 — Elevation & occupied bounds（縦積みと状態変化の確認）

Core libraryには単一状態のシンボル24個を登録しました。既存のC番号付き48セットは比較・レビュー用、`DS/`付き部品は画面への配置用です。パターン画面はrefで部品を参照しています。

## 現在の完成範囲

デザイン・仕様・トークン・参照関係・運用方針の初期基盤です。pen.dev MCPでネイティブ描画を確認し、スキーマ・参照・代表色を検証しました。

FlutterのWidget、動くRive `.riv`、トークンの自動同期CI、OS実機検証は未実装です。デザインの検証結果を、実装済み・アクセシビリティ認証済みという意味では扱いません。

テーマ比較は静的なデザイン見本です。4つの色モードはJSONの明示的な名前空間として定義し、実際のテーマ切り替えは今後のFlutterアダプターで実装します。
