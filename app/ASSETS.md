# 素材の出所

本作の画像は、2026年9月30日に本プロジェクト用としてAIで新規生成したものです。部屋の1926年版を基準に2126年版と朝の版を制作し、ミオの立ち絵は同じ原画から表情・年齢差分を制作しました。小物、結末画、アイコンも本作向けに生成しています。既存ゲームやストック素材を複製していません。

寄りの絵（`close_*_1926.jpg` / `close_*_2126.jpg`）は、各時代の部屋の絵から `lib/data/hotspots.dart` の `closeUpZones` の範囲を切り出し、同じ構図のまま細部を描き込み直したものです（2026年10月1日、AI生成）。部屋の絵と同じ位置に重ねるため、範囲を変えるときは絵も作り直してください。

UI画像（`ui_button_title.png` タイトルのボタン、`ui_pocketwatch.png` 懐中時計ボタン、`ui_frame_choice.jpg` 選択肢の額縁）と、`item_tin_2026.png`（百年後の宝物缶）も、2026年10月1日に本作向けにAIで生成しました。ボタンや額縁の文字は画像に焼き込まず、Flutterで重ねています。

- 背景・立ち絵・小物・結末画: `assets/images/`
- アイコン原画: `branding/app_icon.png`
- iOS/Webアイコン生成: `tools/generate_icons.sh`

BGMと効果音は本作向けに設計した音階・音色を `tools/generate_audio.py` で合成したオリジナル素材です。生成済みファイルは `assets/audio/` にあります。1926年、2126年、トゥルーエンドの曲は同じ旋律と拍の配置を使っています。

カレンダーの日付、文書、時計暗号の針と数字は画像に焼き込まずFlutterで描画しています。

場面の寄り絵（`scene_workbench_*.jpg` 作業台を上から、`scene_lock.jpg` 引き出しのダイヤル錠、`scene_calendar.jpg` カレンダー、`scene_newspaper.jpg` 古新聞、`scene_pillar_*.jpg` 背比べの柱）、上から見た宝物缶（`item_tin_top_*.png`）、持ち物のアイコン（`item_windKey.png` ほか）も、2026年10月1日に本作向けにAIで生成しました。数字・日付・新聞の文面・柱の印はFlutterで重ねて描いています。2026年の部屋の絵（`room_2126.png`）には、壁の古新聞と扉の懐中時計のくぼみを同じ画風で描き足しています。

物語の進行で変わる部屋の部分（`patch_*.png`：柱の印の有無、大時計の歯車と振り子、暖炉の火）と、宝物缶のコマ絵（`item_tin_top_1926_open.png` など）、`item_blankLetter.png` も、2026年10月1日にAIで元の絵を編集して作りました。差分は部屋の絵と同じ位置に重ねて表示します。

ミオの手紙の便箋（`letter_memo1〜4.jpg`）も2026年10月1日にAIで生成しました。手紙の文字は画像に焼き込まず、手書き風フォントで重ねています。14〜16歳の手紙は Yomogi（`assets/fonts/Yomogi-Regular.ttf`）、18歳の最後の手紙は Klee One（`assets/fonts/KleeOne-Regular.ttf`）で、どちらも SIL Open Font License 1.1 です（同じフォルダの `OFL-*.txt`）。

扉のくぼみの寄り絵（`scene_door.jpg` 空のくぼみ、`scene_door_watch.jpg` 懐中時計がはまった状態）と小箱の錠（`scene_boxlock.jpg`）も、2026年10月1日にAIで生成しました。

大時計の台座の引き出し（`scene_base_locked.jpg` 錠つき、`scene_base_open.jpg` 開いた状態）と、明るくした選択肢の枠（`ui_frame_choice.jpg`）も、2026年10月1日にAIで生成しました。窓ガラスの番号はFlutterで重ねています。

ミオの声（`assets/voice/*.m4a`）は、Aratako/Irodori-TTS-v4.1-Small（MITライセンス）で、文章による声の指定から新しく作ったものです。実在の人物の声は使っていません。台詞を変えたら `tools/extract_mio_lines.py` → `tools/make_voice_jobs.py` → `tools/voice_batch.py`（Irodori-TTS の環境で実行）→ `tools/convert_voice.py`（AAC化・1.15倍速）の順で作り直します。読み間違える言葉は `tools/make_voice_jobs.py` の `READINGS` で読みを指定します。
