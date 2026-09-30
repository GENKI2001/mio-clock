# フェーズ 03: 時計暗号と振り子

## 🎯 目的 (Objective)
暗号の規則を自分で理解し、振り子を発見して大時計を動かせるようにする。

## 🛠️ 技術的な方針 (Technical Approach)
- 暗号のencode/decodeを純粋関数にする。
- 時計図形と入力文字盤はFlutterのCustomPainterで描く。

## 📂 作成・修正ファイル
- [x] app/lib/puzzles/clock_cipher.dart (新規)
- [x] app/lib/widgets/clock_glyph.dart (新規)
- [x] app/lib/game_room.dart (修正)
- [x] app/lib/game_progress.dart (修正)

## 📝 ステップバイステップ
1. [x] 黒板、メモ3、台座に同じ規則の時計図形を表示する。
2. [x] 椅子の下の取得条件と振り子の取り付けを実装する。
3. [x] ねじ巻き鍵による大時計起動と部屋の変化を実装する。

## ✅ 受け入れ条件
- [x] メモ3は「いすのした」と解ける。
- [x] 無効な時計の組み合わせは文字にならない。
- [x] 部品不足では鍵が消費されない。

## 🧪 テスト・検証方法
- encode/decodeの往復、無効値、仕様書§12.2のT6〜T9を検証する。
