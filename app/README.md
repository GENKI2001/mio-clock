# ミオと百年時計 — Flutter試作版

このフォルダは、隣の「企画書.md」「仕様書.md」をもとにしたiOS/Web向けFlutter試作です。元の仕様書の技術欄はTypeScriptによるWeb版を想定しています。物語と謎1「カレンダーの丸」の答え・条件・文面を引き継ぎ、実装だけFlutterに置き換えています。

## 今遊べる範囲

- タイトルから開始、1926年と2126年の切替
- 1926年のカレンダーから4月13日の手がかりを発見
- 2126年の引き出しで3桁の錠を解き、ねじ巻き鍵とミオの手紙を入手
- 手帳、3段階ヒント、端末内オートセーブ

謎2以降、エンディング、音、課金は未実装です。

## 起動と確認

```sh
flutter pub get
flutter devices
flutter run -d <表示されたiPhoneシミュレータのID>
```

Webで画面を素早く確認するときは `flutter run -d chrome` を使えます。iPhone向けのビルド確認は `flutter build ios --simulator --no-codesign`、コードの確認は `flutter analyze && flutter test` です。

背景2枚とミオの立ち絵はAIで制作し、`assets/images/` に同梱しています。カレンダーの数字、錠、手紙など正確さが必要な文字はFlutterで描画しています。
