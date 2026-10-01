"""List every line Mio speaks: each DialogueLine(...) in lib/ whose speaker
is 'ミオ'. Prints JSON [{"text": ..., "expression": ...}] in source order,
without duplicates."""

import json
import re
import sys
from pathlib import Path

LIB = Path(__file__).resolve().parent.parent / "lib"
STRING = re.compile(r"'((?:[^'\\]|\\.)*)'")


def calls(source: str):
    """Yield the argument text of every DialogueLine( ... ) call."""
    for match in re.finditer(r"DialogueLine\(", source):
        depth, i = 1, match.end()
        while depth and i < len(source):
            ch = source[i]
            if ch == "'":
                i = source.index("'", i + 1) if "\\'" not in source[i:i+2] else i + 1
                while source[i - 1] == "\\":
                    i = source.index("'", i + 1)
            elif ch == "(":
                depth += 1
            elif ch == ")":
                depth -= 1
            i += 1
        yield source[match.end() : i - 1]


def main() -> None:
    seen, lines = set(), []
    for path in sorted(LIB.rglob("*.dart")):
        for args in calls(path.read_text()):
            if "speaker: 'ミオ'" not in args:
                continue
            head = args.split("speaker:")[0]
            text = "".join(m.group(1) for m in STRING.finditer(head))
            text = text.replace("\\n", "\n").replace("\\'", "'")
            expr = re.search(r"expression: '(\w+)'", args)
            if text and text not in seen:
                seen.add(text)
                lines.append({"text": text, "expression": expr.group(1) if expr else "normal"})
    json.dump(lines, sys.stdout, ensure_ascii=False, indent=1)


if __name__ == "__main__":
    main()
