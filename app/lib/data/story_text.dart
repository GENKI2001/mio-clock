import '../game_progress.dart';

class DialogueLine {
  const DialogueLine(this.text, {this.speaker, this.expression});

  final String text;
  final String? speaker;
  final String? expression;
}

const noteText = <String, String>{
  'n_watchMT': '懐中時計の裏蓋に「M.T.」の刻印。',
  'n_promise': 'ミオとの約束:さよならは言わない。帰るときは「またね」。',
  'n_calendar': '1926年のカレンダー:4月13日に赤丸「ミオ 誕生日!」。大正十五年=1926年。',
  'n_missingGear': '大時計(2126):歯車が一枚足りない。',
  'n_niche': 'ミオの宝物缶は、暖炉の横の隠し棚(外れるレンガ)にしまってある。',
  'n_heightStart': '背比べの柱:大正十五 142cm。ミオは毎年誕生日に測るつもり。',
  'n_pillar': '柱(2126):大正十五 142/昭和二 145/昭和三 151/昭和四 153/昭和五 154。「つづきは みらいで」',
  'n_backPanelLock': '背面の錠(4桁):「ミオの背が、前の年から いちばん伸びた年を 西暦で」',
  'n_cipher': 'ミオ式 時計暗号:短い針=行、長い針が指す数字=段。',
  'n_example': '黒板の「れい」:[1:25][2:05][1:20][9:10]「わたしの いちばん すきな ことば」',
  'n_clockRunning': '大時計が動き出した。扉の文字盤が光っている。',
  'n_door': '扉:「約束の言葉を、時の針で」',
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
          'お父様の鍵は、あなたのために、ここへしまっておきます。\n\n'
          '大事なものは、百年もつ場所に。\n'
          'それが、時計屋の娘の心得です。\n\n'
          '大正十五年 四月十三日 夜  ミオ';
    case 'memo2':
      final heightText = progress.heightMarked
          ? '柱の印を見てね。\nあなたが最初に測ってくれたから、毎年つづけています。'
          : '背比べの柱、あの日あなたと測りそびれちゃった。\n……まだ、間に合う?';
      return '未来のお客さまへ\n\n'
          '歯車、ちゃんと届いた?\n'
          'ひとりで缶を開けるのは、ちょっとずるい気がします。\n'
          '開けるところ、見たかったな。\n\n'
          '今日で十五歳。背は、ちょっとだけ伸びました。\n'
          '$heightText\n\n'
          '昭和二年 四月十三日  ミオ';
    case 'memo3':
      return '未来のお客さまへ\n\n'
          '背がぐんと伸びた年なので、書いています。\n'
          '……えへへ、見たでしょう、柱。\n\n'
          '振り子は大事だから、もっと奥にかくしました。\n'
          '場所は、ミオ式で。';
    case 'memo4':
      return '未来のお客さまへ\n\n'
          'これで部品は、ぜんぶです。\n'
          '時計が動いたら、扉は開きます。\n'
          '扉の言葉は、あの日の約束の言葉。それで、あなたは帰れます。\n\n'
          '……ねえ。\n'
          '今夜、百年時計の部品が、ぜんぶ仕上がりました。\n'
          '組み立ては、あなたにまかせるね。\n\n'
          '私ね、あなたに会いに行ってみようと思うの。\n'
          'お母様の懐中時計が、時をまたぐって、本当だったから。\n\n'
          'もしも、私が迷子になっていたら――\n'
          'あなたにだけ教えた、私のいちばん好きな言葉で、呼んでね。\n\n'
          '昭和五年 四月十三日  ミオ(十八さい)';
    case 'newspaper':
      return '東都日日新聞  昭和五年四月十四日\n\n'
          '時計店の娘 忽然と消ゆ\n\n'
          '十三日夜、下町の時任時計店にて、同店主・時任宗一郎氏の長女ミオ(十八)が'
          '二階の工房より姿を消した。\n'
          '家人の話によれば、同夜ミオは「完成した」と声を上げたのち、'
          '室内には止まった大時計のそばで、懐中時計の音だけが響き、'
          '戸を開けた時には誰もいなかったという。\n'
          '窓は内から閉ざされ、履物も残されたまま。\n'
          '警察は神隠しとも失踪ともつかぬとして、行方を捜している。';
  }
  return '';
}

const hintText = <String, List<String>>{
  's1': [
    '引き出しの錠は3桁で、「たいせつな ひ」。百年前の部屋に、大切な日の印がないかな?',
    '1926年の壁のカレンダーを見てみて。赤い丸がついてるよ。',
    '4月13日で「413」。',
  ],
  's2': [
    '大時計の歯車が一枚足りないみたい。1926年の作業台に予備の歯車があるよ。……でも、物は時を越えられない。',
    '越えられないなら、百年そこに置いておけばいい。窓辺は雨、暖炉は煤……百年もつ場所はどこ?',
    '1926年で歯車を持って「ミオの宝物缶」に入れる。2126年で暖炉の横の隠し棚を調べる。',
  ],
  's3': [
    '背面の錠は「ミオの背がいちばん伸びた年」。ミオの背の記録って、どこにあるんだろう?',
    '1926年の柱でミオと背比べをすると、2126年の柱に5年分の印が残る。印は毎年ひとつ。大正十五年は1926年だよ。',
    '昭和三年(1928年)に+6cm。答えは「1928」。',
  ],
  's4': [
    'メモ3の時計の絵は、ミオ式の暗号。1926年の黒板に書き方があるよ。',
    '短い針が「行」、長い針が指す数字が「段」。1時10分なら、あ行のい段で「い」。',
    '「いすのした」。2126年の椅子の下の床板を調べて、振り子を大時計に取り付けよう。',
  ],
  's5': ['歯車と振り子が揃ったら、最後はねじを巻くだけ。', '引き出しから出てきた鍵、まだ持ってる?', 'ねじ巻き鍵を大時計に使う。'],
  's6': [
    '扉は「約束の言葉」で開くみたい。ミオとした約束、覚えてる?',
    '帰るとき、ミオはいつも何て言ってた? それを時計暗号で刻もう。',
    '「またね」。7時5分・4時5分・5時20分。',
  ],
  'sTrue': [
    'ミオは、どこへ行ってしまったんだろう。新聞とメモ4を読み返してみて。',
    'ミオが「あなたにだけ」教えたこと。口に出しちゃだめって言われたもの、あったよね?',
    '黒板の「れい」を解くと「おかえり」。1時25分・2時5分・1時20分・9時10分。',
  ],
};

const introLines = <DialogueLine>[
  DialogueLine('――古道具屋で、ひとつの懐中時計を買った'),
  DialogueLine('真鍮の、傷だらけの時計。裏蓋に『M.T.』と彫られている'),
  DialogueLine('止まっていたはずのその時計が、帰り道でふいに動き出した'),
  DialogueLine('秒針に導かれるように路地を曲がり、崩れかけた時計店の階段を上って――'),
  DialogueLine('気がつくと、扉が閉まっていた'),
  DialogueLine('鍵穴がない。押しても、引いても、びくともしない'),
  DialogueLine('手の中で、懐中時計がちくたくと鳴っている。……竜頭が、押してほしそうに光っている'),
];

const meetOpening = <DialogueLine>[
  DialogueLine('……へ?', speaker: 'ミオ', expression: 'surprise'),
  DialogueLine('ゆ、幽霊さん……? 透けてる……!', speaker: 'ミオ', expression: 'surprise'),
  DialogueLine('自分の手を見る。確かに、うっすらと向こうが透けていた'),
  DialogueLine('ちくたく、ちくたく……。その手の懐中時計、お母様のと同じ……', speaker: 'ミオ'),
  DialogueLine('わかった! あなた、未来のお客さまでしょう!', speaker: 'ミオ', expression: 'smile'),
];

const meetClosing = <DialogueLine>[
  DialogueLine('私はミオ。時任ミオ。この時計屋の娘で、今日で十四歳!', speaker: 'ミオ'),
  DialogueLine('……ねえ、百年後のこの部屋って、どうなってるの?', speaker: 'ミオ'),
  DialogueLine('廃墟になっていること、止まった大時計のこと、閉じ込められたことを話した'),
  DialogueLine('そっか……時計、止まっちゃってるんだ', speaker: 'ミオ', expression: 'sad'),
  DialogueLine(
    'だったら、決めた! 私が手伝う。百年後の時計を、もう一度動かそう!',
    speaker: 'ミオ',
    expression: 'proud',
  ),
  DialogueLine(
    'それから、約束。私、「さよなら」って言葉がきらいなの。だから帰るときは、ちゃんと「またね」って言うこと!',
    speaker: 'ミオ',
    expression: 'smile',
  ),
];

const farewellLines = <DialogueLine>[
  DialogueLine('またね! ぜったいまた来てね!', speaker: 'ミオ', expression: 'smile'),
  DialogueLine('またね!', speaker: 'ミオ', expression: 'smile'),
  DialogueLine(
    'またね。未来で待ってる……じゃなくて、ここで待ってる!',
    speaker: 'ミオ',
    expression: 'proud',
  ),
  DialogueLine('またね。……ちくたく、ちくたく', speaker: 'ミオ'),
  DialogueLine(
    'ま、またね! 早く戻ってきてもいいんだからね!',
    speaker: 'ミオ',
    expression: 'embarrassed',
  ),
];

const normalEndingLines = <DialogueLine>[
  DialogueLine('扉が、ゆっくりと開いた'),
  DialogueLine('階段の下から、百年後の夜風が吹き込んでくる'),
  DialogueLine('振り返る。大時計が、ちくたくと時を刻んでいる'),
  DialogueLine('――またね、ミオ'),
  DialogueLine('……扉が閉まる直前'),
  DialogueLine('大時計の奥で、誰かが小さく「ちくたく」と呟いた気がした'),
  DialogueLine('扉は開いた。けれど、まだ「もっと正解」の言葉があるのかもしれない'),
];

const trueEndingLines = <DialogueLine>[
  DialogueLine('大時計が、歌いはじめた'),
  DialogueLine('聞き覚えのある旋律。……1926年の部屋に、ずっと流れていたワルツだ'),
  DialogueLine('……わっ、わわっ!', speaker: 'ミオ', expression: 'adult_cry'),
  DialogueLine('背が伸びていた。おさげはほどけていた。胸元の鎖の先は空っぽで――あなたの手の中の懐中時計が、ちくたくと鳴った'),
  DialogueLine('……いま、「おかえり」って、言ってくれた?', speaker: 'ミオ', expression: 'adult_cry'),
  DialogueLine(
    'ずっと、真っ暗なところで、ちくたくって音だけ聞いてたの。誰かが時計を動かしてくれて……誰かが、呼んでくれるのを待ってた',
    speaker: 'ミオ',
    expression: 'adult_cry',
  ),
  DialogueLine(
    '……えへへ。あなたにだけ教えたのに、ちゃんと覚えてたんだ',
    speaker: 'ミオ',
    expression: 'adult_normal',
  ),
  DialogueLine(
    'じゃあ、言うね。私のいちばん好きな言葉の、お返事',
    speaker: 'ミオ',
    expression: 'adult_normal',
  ),
  DialogueLine('――ただいま!', speaker: 'ミオ', expression: 'adult_cry'),
  DialogueLine('百年前に止まった約束が、いま、ちくたくと動き出した'),
];
