# detent_ui の作業ガイド

Flutter デスクトップ向け UI パッケージ（Detent Design System）。全体方針は `DESIGN_SYSTEM.md`、部品仕様は `SPECIFICATION.md`、API と使い方は `README.md`。

## デザインの正本はコード

- 値の正本は `design_tokens.json`（DTCG 形式）。`lib/src/foundation/tokens.g.dart` と `design_tokens.resolved.json` は生成物なので直接編集しない。
- 見た目の正本は Flutter 実装とギャラリー（`example/`）、確認はそのスクリーンショット（`example/screenshots/`）で行う。
- `design_system.pen` は旧デザインの記録。更新しない。`component_registry.json` の `legacyPenNodeId` はその記録への参照。
- Pen / pen.dev MCP はデザイン作業に使わない。

## 変更の手順

1. 問題と使う場面を決め、token / variant / component / pattern のどれを変えるか選ぶ。
2. 値の変更は `design_tokens.json` を編集し、`python3 tool/generate_tokens.py` で再生成する。
3. 部品とギャラリーを直す。新しい色は `DetentThemeData` のロール経由で使い、部品に直書きしない。
4. 確認する。
   - `flutter analyze`
   - `flutter test`（ルート）、`cd example && flutter test`、`cd packages/detent_ui_omarchy && flutter test`
5. 見た目を変えたら `tool/update_screenshots.sh` でスクリーンショットを撮り直し、`build/screenshots/before/` の変更前と比べる。意匠の方向を決めるときは、同じ画面で二案を撮って比較してから採用する。
6. `DESIGN_SYSTEM.md`（判断の理由）、`README.md`、`SPECIFICATION.md`、`component_registry.json` を同じ版に揃える。

## 環境の注意

- Rive の描画とテストにはネイティブランタイムが要る。未導入だと Rive 関連のテスト（ルート6件、`example/test/component_review_test.dart`）が失敗し、スクリーンショットが静的な代替描画になる。初回に実行する。

  ```sh
  dart run rive_native:setup --verbose --clean --platform linux
  ```

- Rive CLI は `tool/generate_rive.py` で `.riv` を作り直すときだけ必要。テストには不要。
- 色の組み合わせは本文 4.5:1、操作の識別に必要な境界・状態・フォーカスは 3:1 を目安に計算して確かめる。

## バージョン管理

- GitButler（`but`）を使う。ターゲットは `origin/master`（GitHub のデフォルトブランチ）。`main` は存在しない。
- 作業ごとにブランチを切り、依存する作業は `--above` で積んで `but pr new` で PR を出す。
