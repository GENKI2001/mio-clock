# ミオと百年時計 — Flutter版

このフォルダは、隣の「企画書.md」「仕様書.md」をもとにしたiOS/Web向けの一室型脱出ゲームです。元仕様の技術欄はTypeScript/Web版を想定していますが、物語・謎の答え・判定条件・文面は保持し、実装をFlutterへ置き換えています。

## ゲーム内容

- 1926年と2126年の同じ書斎を往還する4つの謎と終章
- ミオとの会話、5つの文書、手帳、段階別ヒント、端末内オートセーブ
- ノーマルとトゥルーの2エンディング。クリア後は扉の前から再挑戦可能
- 時代で編成の変わる同じ旋律のBGM、効果音、表情差分、結末用の一枚絵

画面は横持ち専用です。部屋の物をタップして調べ、所持品を選んで対象に使います。扉では時計の数字をタップ、または針をドラッグして仮名を刻みます。

## 開発

```sh
flutter pub get
flutter devices
flutter run -d <表示されたiPhoneシミュレータのID>
flutter analyze
flutter test
flutter build ios --simulator --no-codesign
```

Webで画面を確認するときは `flutter run -d chrome`。画像なしの代替表示を検証するときは `flutter run -d chrome --dart-define=MIO_NO_ASSETS=true` を使います。

主要なコード:

- `lib/game_progress.dart` — 状態、進行条件、保存と復元
- `lib/data/` — 会話、文書、メモ、ヒント、ホットスポット
- `lib/puzzles/clock_cipher.dart` — 時計暗号の相互変換
- `lib/game_room.dart` — 部屋の操作と進行
- `lib/widgets/` — 時計文字盤、手帳、パネル、結末
- `lib/soundscape.dart` — 同一旋律の時代間クロスフェード

画像は `assets/images/` に同梱しています。正確な数字・暗号・手紙はFlutterで描画しています。音はこの作品向けに作ったオリジナル素材で、`python3 tools/generate_audio.py` により再生成できます。アイコンの原画は `branding/app_icon.png` にあり、`tools/generate_icons.sh` でiOS/Web用サイズに展開できます。

## 公開前に必要な作業

現状のBundle IDは開発用の `com.example.mioClock` です。App Store提出時には所有する識別子へ変更し、Apple Developer Programのチームで署名します。価格、ストア説明・スクリーンショット、プライバシーポリシーURL、実機試遊、審査提出も必要です。初版は買い切りの設計で、広告・アプリ内課金SDKは入れていません。
