"""Copy rendered voice WAVs into assets/voice as AAC, 1.15x faster (pitch
kept), and drop files no longer listed in lib/data/mio_voice.dart.

    python3 tools/convert_voice.py RENDER_DIR
"""

import re
import subprocess
import sys
from pathlib import Path

APP = Path(__file__).resolve().parent.parent
TEMPO = 1.15
LEAD_MS = 180


def main() -> None:
    render = Path(sys.argv[1])
    out = APP / 'assets/voice'
    out.mkdir(parents=True, exist_ok=True)
    ids = set(re.findall(r"'(mio_[0-9a-f]+)'", (APP / 'lib/data/mio_voice.dart').read_text()))
    for vid in sorted(ids):
        subprocess.run(
            ['ffmpeg', '-loglevel', 'error', '-y', '-i', str(render / f'{vid}.wav'),
             # Trim whatever silence the model left, then a fixed short
             # lead-in so playback never clips the first syllable.
             '-filter:a',
             f'silenceremove=start_periods=1:start_threshold=-50dB,'
             f'atempo={TEMPO},adelay={LEAD_MS}',
             '-ac', '1',
             '-c:a', 'aac', '-b:a', '64k',
             str(out / f'{vid}.m4a')],
            check=True,
        )
    for stale in out.glob('*.m4a'):
        if stale.stem not in ids:
            stale.unlink()
    print(f'{len(ids)} voice files in {out}')


if __name__ == '__main__':
    main()
