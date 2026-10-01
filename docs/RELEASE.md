# App Store 公開・広告収益化の手順

アプリ側の準備（済み）:

- リワード広告（Google AdMob）でヒントを1段ずつ開く。今は Google のテスト用ID。
- 初めてヒントを見るときに、トラッキング許可（ATT）の確認を出す。
- プライバシーマニフェスト `app/ios/Runner/PrivacyInfo.xcprivacy`。
- プライバシーポリシーの下書き `docs/privacy.md`。

## 1. AdMob

1. https://admob.google.com でアカウントを作り、支払い情報（住所・税務情報・銀行口座）を登録する。
2. アプリ「ミオと百年時計（iOS）」を追加し、**アプリID**（`ca-app-pub-XXXX~YYYY`）を控える。
3. 「リワード」の広告ユニットを作り、**広告ユニットID**（`ca-app-pub-XXXX/ZZZZ`）を控える。
4. 開発中に自分の iPhone で本物の広告を見ないこと。テスト端末として登録しておく。

## 2. アプリに本番IDを入れる

- `app/ios/Runner/Info.plist` の `GADApplicationIdentifier` を、1-2 のアプリIDに書き換える。
- 広告ユニットIDは、ビルドのときに渡す（ソースには書かない）:

```
cd app
flutter build ipa --release --dart-define=ADMOB_IOS_REWARDED=ca-app-pub-XXXX/ZZZZ
```

`--dart-define` を付けずにビルドすると、テスト広告のままになる。

## 3. App Store

1. Apple Developer Program（年99ドル）に登録し、Xcode の Team を有料のチームに切り替える。
2. App Store Connect でアプリを作る（バンドルID `com.genki2001.mioclock`）。
3. 「App のプライバシー」で次を申告する（AdMob 利用分）:
   - 識別子（デバイスID）: 第三者広告・トラッキングに使用
   - 使用状況データ（製品の操作、広告データ）: 第三者広告・分析
   - 診断（クラッシュデータ・パフォーマンスデータ）: 分析
   - 位置情報（おおよその場所）: 第三者広告
4. `docs/privacy.md` の日付と連絡先を埋めて、公開ページ（GitHub Pages など）に置き、そのURLを登録する。
5. スクリーンショット、説明文、年齢区分などを入力して、審査に出す。

## 4. 公開後

- AdMob の「アプリ」で App Store のアプリを紐づける。
- 収益は残高が8,000円を超えると、翌月に振り込まれる。

## 注意

- AdMob の本番アプリIDを Info.plist に入れずに広告を出そうとすると、起動時に落ちることがある。IDはセットで差し替える。
- EU・英国の利用者向けに配信する場合は、AdMob の「プライバシーとメッセージ」で同意メッセージ（UMP）を設定する。
