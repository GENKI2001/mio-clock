import '../game_progress.dart';

class DialogueLine {
  const DialogueLine(this.text, {this.speaker, this.expression});

  final String text;
  final String? speaker;
  final String? expression;
}

const noteText = <String, String>{
  'n_watchMT': '懐中時計の裏蓋に「M.T.」の刻印。',
  'n_calendar': '1926年のカレンダー:4月13日に赤丸「ミオ 誕生日!」。大正十五年=1926年。',
  'n_missingGear': '大時計(2026):歯車が一枚足りない。',
  'n_tin': 'ミオが歯車を宝物缶に入れ、蝋で封じて作業台に置いた。百年後も同じ場所にあるはず。',
  'n_waxSeal': '2026年の宝物缶:ふたが固い蝋で封じられている。温めれば、やわらかくなりそう。',
  'n_heightStart': '背比べの柱:ミオは毎年誕生日に背を測って刻むつもり。',
  'n_pillar': '柱(2026):1926 142/1927 145/1928 151/1929 153/1930 154。',
  'n_boxLock': '黒板横の棚の小箱(4桁の錠):「ミオの背が、前の年から いちばん伸びた年を 西暦で」',
  'n_blankLetter': '小箱の白紙の手紙:かすかにみかんの匂い。ひみつのインク?',
  'n_fire': '2026年の暖炉に火をつけた。',
  'n_favoritePlace': 'ミオのいちばん好きな場所は、お父様の椅子。',
  'n_screwedBoard': '2026年の椅子の真下:床板が一枚だけ、小さなねじで留めてある。',
  'n_rustySpring': '大時計のぜんまいが錆びついて回らない。時計油があれば……。',
  'n_boardFaded': '2026年の黒板:ミオが書いた番号は、煤に埋もれて読めない。',
  'n_codeOnWindow': 'ミオが、台座の錠の番号を窓の左下のガラスに刻んでくれる。',
  'n_windowCode': '窓の左下のガラス:「2 7 5」。',
  'n_oil': 'ミオが時計油を瓶に詰めて蝋で封じ、大時計の台座の引き出しにしまった。',
  'n_clockRunning': '大時計が動き出した。扉のくぼみが光っている。',
  'n_door': '扉:中央に懐中時計の形のくぼみ。ミオの胸元の懐中時計にそっくり。',
  'n_clockStopped': '大時計(2026):止まっている。歯車・振り子・ねじ巻き鍵が足りない。',
  'n_watchPromise': 'ミオが約束した。「この懐中時計、あなたの時代まで届くように、大切に受け継いでいく。必ず受け取ってね」',
  'n_mioWatch': 'ミオの懐中時計は、あなたのものと傷の位置まで同じ。',
};

const documentTitles = <String, String>{
  'memo1': '未来のお客さまへ（一通目）',
  'memo2': '未来のお客さまへ（二通目）',
  'memo3': '未来のお客さまへ（三通目）',
  'memo4': '未来のお客さまへ（最後の手紙）',
  'newspaper': '東都日日新聞',
};

String documentText(String id, GameProgress progress) {
  switch (id) {
    case 'memo1':
      return '未来のお客さまへ\n\n'
          'ほんとうに、来てくれたんだね。\n'
          'お父様の鍵は、あなたのために、ここへしまっておきます。\n'
          'マッチもいっしょに。夜の部屋は、暗いでしょう?\n\n'
          '大事なものは、百年もつ場所に。\n'
          'それが、時計屋の娘の心得です。\n\n'
          '大正十五年 四月十三日 夜  ミオ';
    case 'memo2':
      return '未来のお客さまへ\n\n'
          '歯車、ちゃんと届いた?\n'
          'ひとりで缶を開けるのは、ちょっとずるい気がします。\n'
          'つぎの手紙は、ひみつのインクで書きます。読むときは、暖炉であたためてね。\n'
          '開けるところ、見たかったな。\n\n'
          '昭和二年 四月十三日  ミオ';
    case 'memo3':
      return '未来のお客さまへ\n\n'
          '背がぐんと伸びた年なので、書いています。\n'
          '……えへへ、見たでしょう、柱。\n\n'
          '振り子は大事だから、もっと奥にかくしました。\n'
          '私のいちばん好きな場所の、真下です。\n'
          'ねじは、この小さなドライバーで。\n\n'
          '昭和三年 四月十三日  ミオ';
    case 'memo4':
      return '未来のお客さまへ\n\n'
          'これで部品は、ぜんぶです。\n'
          '時計が動いたら、扉のくぼみを見てね。\n'
          '鍵は、きっともう、あなたの手の中にあります。\n\n'
          '……ねえ。\n'
          '今夜、百年時計の部品が、ぜんぶ仕上がりました。\n'
          '組み立ては、あなたにまかせるね。\n\n'
          '百年後のあなたに、この音が届きますように。\n'
          '……またね。\n\n'
          '昭和五年 四月十三日  ミオ(十八さい)';
    case 'newspaper':
      return '東都日日新聞  昭和五年四月十四日\n\n$newspaperHeadline\n\n$newspaperBody';
  }
  return '';
}

/// The 1930 article about the finished clock, shared by the close-up and
/// the notebook.
const newspaperHeadline = '百年動く大時計 下町の時計店で完成';

const newspaperBody =
    '十三日、下町の時任時計店にて、同店主・時任宗一郎氏と長女ミオ(十八)が'
    '五年がかりで作り続けてきた大時計が完成した。\n'
    'ねじを一度巻けば百年動くといい、父娘は「百年時計」と呼んでいる。\n'
    'ミオは「百年後の友だちに、この音を届けたい」と笑った。\n'
    '大時計は二階の工房に据えられ、扉のからくりと連動する仕掛けも施されている。';

const hintText = <String, List<String>>{
  's1': [
    '引き出しの錠は3桁で、「たいせつな ひ」。百年前の部屋に、大切な日の印がないかな?',
    '1926年の壁のカレンダーを見てみて。赤い丸がついてるよ。',
    '4月13日で「413」。',
  ],
  's2': [
    '大時計の歯車が一枚足りない。1926年の作業台をのぞいてみて。……でも、透けた体では物を持てない。',
    '予備の歯車を見たら、となりのミオの宝物缶も調べてみよう。ミオが百年もつようにしまってくれる。',
    '2026年の作業台の缶は蝋で封じてある。引き出しのマッチで蝋をあぶって開け、歯車を大時計に使う。',
  ],
  's3': [
    '黒板横の棚の小箱の錠は「ミオの背がいちばん伸びた年」。ミオの背の記録って、どこにあるんだろう?',
    '1926年でミオに背比べをたのむか、柱を調べよう。毎年の誕生日の印と年が、2026年の柱に彫られて残る。',
    '昭和三年(1928年)に+6cm。答えは「1928」。',
  ],
  's4': [
    '小箱の白紙の手紙は、かすかにみかんの匂い。二通目の手紙に「ひみつのインク」「暖炉であたためて」とあったね。',
    '2026年の暖炉にマッチで火をつけて、白紙の手紙をあぶろう。浮かんだ文字によると、振り子は「ミオのいちばん好きな場所の真下」。',
    'ミオに好きな場所を聞くと「お父様の椅子」。2026年の椅子の下の床板を、ドライバーで外す。出てきた振り子を大時計に。',
  ],
  's5': [
    'ぜんまいが錆びついている。1926年のミオに話すと、時計油を大時計の台座にしまってくれる。',
    '台座の錠の番号は、ミオが黒板に書いてくれた……けれど2026年の黒板では読めない。もう一度ミオに相談しよう。',
    '窓の左下のガラスに刻まれた「275」で台座の錠を開け、時計油を大時計に使ってから、ねじ巻き鍵で巻く。',
  ],
  's6': [
    '扉のくぼみは懐中時計の形。……この形、どこかで見なかった?',
    'ミオが胸元に下げている懐中時計にそっくり。1926年のミオに、扉のくぼみのことを話してみよう。',
    'ミオは懐中時計を受け継いで、あなたに届けると約束してくれる。2026年の扉を調べたまま、右下の懐中時計を押す。',
  ],
};

const introLines = <DialogueLine>[
  DialogueLine('廃墟を歩くのが、ひそかな趣味だった'),
  DialogueLine('今夜の目当ては、下町のはずれに百年前から残る、古い時計店の跡'),
  DialogueLine('崩れかけた階段を上り、二階の書斎へ。懐中電灯の光に、止まった大時計が浮かび上がる'),
  DialogueLine('――ばたん!'),
  DialogueLine('背後で、扉が閉まった'),
  DialogueLine('え……? うそ、開かない……!', speaker: 'あなた'),
  DialogueLine('鍵穴がない。押しても、引いても、びくともしない。扉の真ん中に、懐中時計の形のくぼみがあるだけだ'),
  DialogueLine('誰か! 誰かいませんか!', speaker: 'あなた'),
  DialogueLine('返事はない。スマホは圏外。懐中電灯の光も、じわじわと弱くなっていく'),
  DialogueLine('どうしよう、どうしよう……!', speaker: 'あなた'),
  DialogueLine('そのとき――ポケットの中が、ほのかに温かくなった'),
  DialogueLine('祖母の形見として受け継いだ、傷だらけの真鍮の懐中時計。裏蓋に「M.T.」と彫られている'),
  DialogueLine('止まっていたはずのその時計が、淡く光りながら、ちくたくと鳴りはじめた'),
];

const meetOpening = <DialogueLine>[
  DialogueLine('……へ?', speaker: 'ミオ', expression: 'surprise'),
  DialogueLine('ゆ、幽霊さん……? 透けてる……!', speaker: 'ミオ', expression: 'surprise'),
  DialogueLine('自分の手を見る。確かに、うっすらと向こうが透けていた'),
  DialogueLine('あ、あなた、だれ? どこから入ってきたの?', speaker: 'ミオ', expression: 'surprise'),
];

/// After the player says the watch flung them here.
const meetWatch = <DialogueLine>[
  DialogueLine('時計をいじっていたら、変な部屋にワープして……', speaker: 'あなた'),
  DialogueLine('ミオの目が、あなたの手の中の懐中時計に吸い寄せられる'),
  DialogueLine('その時計……私が持っているものと同じ', speaker: 'ミオ', expression: 'surprise'),
  DialogueLine('ミオは胸元の鎖をたぐって、そっくりな懐中時計を取り出した'),
  DialogueLine('私の時計は、時間を渡ることができるの。だから、それで過去に戻ってきたんじゃないかな?', speaker: 'ミオ'),
  DialogueLine('今は1926年。あなたの時代は?', speaker: 'ミオ'),
];

const meetWelcome = <DialogueLine>[
  DialogueLine('2026年', speaker: 'あなた'),
  DialogueLine(
    'なら、100年後だ! いらっしゃい、未来のお客さん!',
    speaker: 'ミオ',
    expression: 'smile',
  ),
  DialogueLine(
    '私はミオ。時任ミオ。この時計屋の娘で、今日で十四歳!',
    speaker: 'ミオ',
    expression: 'proud',
  ),
  DialogueLine('ここは時計屋さんの、ときわけ書斎。……ねえ、100年後のうちはどんな感じ?', speaker: 'ミオ'),
];

/// How the player describes the house a hundred years on.
const meetFutureAnswers = <DialogueLine>[
  DialogueLine('ぼろぼろの廃墟になってる。窓も割れて、蔦だらけで……', speaker: 'あなた'),
  DialogueLine('誰も住んでいなくて、真っ暗で、埃だらけだった', speaker: 'あなた'),
];

const meetStuck = <DialogueLine>[
  DialogueLine('そ、そっか。……悲しいね', speaker: 'ミオ', expression: 'sad'),
  DialogueLine('それに……100年後の未来のこの場所から、出られなくなっちゃった', speaker: 'あなた'),
  DialogueLine('出られなくなっちゃった?! え、なんでぇ?!', speaker: 'ミオ', expression: 'surprise'),
  DialogueLine('入ったら扉が急に閉まって、開かなくなっちゃって', speaker: 'あなた'),
  DialogueLine('扉が急に……? あの、鍵穴のない扉のこと?', speaker: 'ミオ'),
  DialogueLine('お父様の扉はね、ふつうの鍵じゃ開かないの。中にからくりが入ってて……', speaker: 'ミオ'),
  DialogueLine('からくり?', speaker: 'あなた'),
  DialogueLine(
    'うん。扉の中の歯車が、部屋のほかの何かとつながってるって、お父様が言ってた。えっと、何とだっけ……',
    speaker: 'ミオ',
  ),
  DialogueLine('ミオは腕を組んで、うーん、と天井を見上げた'),
  DialogueLine(
    '……そうだ、思い出した! もしかして……大時計、壊れてる?',
    speaker: 'ミオ',
    expression: 'surprise',
  ),
  DialogueLine('大時計? 何それ', speaker: 'あなた'),
  DialogueLine('あれだよ、あれ', speaker: 'ミオ', expression: 'proud'),
];

const meetClockExplain = <DialogueLine>[
  DialogueLine('大時計と扉は連動してて、大時計が壊れてると、扉が開かなくなっちゃうんだよね', speaker: 'ミオ'),
  DialogueLine('ちょっと未来に戻って、大時計を確認してきて!', speaker: 'ミオ', expression: 'smile'),
];

/// Looking at the 2026 clock for the first time, at Mio's request.
const clockCheckLines = <DialogueLine>[
  DialogueLine('止まった大時計。針は動かない'),
  DialogueLine('文字盤の下の小窓の奥で、歯車が一枚抜けている'),
  DialogueLine('ガラスの奥に吊るすはずの振り子もない。ねじを巻く鍵も、どこにも見当たらない'),
  DialogueLine('……壊れている。ミオに知らせよう'),
];

const meetReport = <DialogueLine>[
  DialogueLine('おかえり! どうだった?', speaker: 'ミオ', expression: 'smile'),
  DialogueLine('壊れてたかー……。直さなきゃいけないねー', speaker: 'ミオ', expression: 'sad'),
  DialogueLine(
    '部品とかはこの部屋にいっぱいあるから、いくらでもあげるよー',
    speaker: 'ミオ',
    expression: 'proud',
  ),
];

const meetPlan = <DialogueLine>[
  DialogueLine('でも、過去だと体が透けちゃって物を受け取れない', speaker: 'あなた'),
  DialogueLine('あっ、確かに。どうやって100年後のあなたに渡せば……', speaker: 'ミオ', expression: 'sad'),
  DialogueLine('まぁ、とりあえず一緒に考えようか', speaker: 'ミオ'),
  DialogueLine('足りないパーツはどれだった?', speaker: 'ミオ'),
];

const meetTeam = <DialogueLine>[
  DialogueLine('足りないのは、歯車・振り子・ねじ', speaker: 'あなた'),
  DialogueLine('わかった! 一緒に頑張ろう!', speaker: 'ミオ', expression: 'proud'),
];

const farewellLines = <DialogueLine>[
  DialogueLine('またね! 絶対戻ってきてね!', speaker: 'ミオ', expression: 'smile'),
  DialogueLine('またね!', speaker: 'ミオ', expression: 'smile'),
  DialogueLine(
    'またね。未来で待ってる……じゃなくて、ここで待ってる!',
    speaker: 'ミオ',
    expression: 'proud',
  ),
  DialogueLine('またね。気をつけて行ってきてね!', speaker: 'ミオ', expression: 'smile'),
  DialogueLine(
    'ま、またね! 早く戻ってきてもいいんだからね!',
    speaker: 'ミオ',
    expression: 'embarrassed',
  ),
];

/// The door opens on Mio, who crossed the years with her own watch. The
/// last line gives way to the closing picture.
const normalEndingLines = <DialogueLine>[
  DialogueLine('扉が、ゆっくりと開いた'),
  DialogueLine('――扉の向こうに、誰かが立っている'),
  DialogueLine('えへへ……来ちゃった!', speaker: 'ミオ', expression: 'smile'),
  DialogueLine(
    '私の懐中時計で、時を渡ってきたの。扉が開く、ちょうどこの時間をめがけて',
    speaker: 'ミオ',
    expression: 'proud',
  ),
  DialogueLine('ミオ……!', speaker: 'あなた'),
  DialogueLine(
    '一緒に頑張ろうって言ったでしょ? 最後まで一緒じゃなきゃ、ね',
    speaker: 'ミオ',
    expression: 'smile',
  ),
  DialogueLine('ねえ、見せて。100年後の街!', speaker: 'ミオ', expression: 'surprise'),
  DialogueLine('ふたりで、扉の外へ歩き出した'),
];
