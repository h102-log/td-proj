# AI 관찰 플레이 하네스(play.gd)에 명령을 보내고 캡처가 나올 때까지 기다린다(WBS 3.4·5.5용 도구).
#   python tools/play/send.py <폴더> ["명령" ...]   — 명령 없이 부르면 지금 화면만 다시 찍는다
# 캡처 PNG 경로를 출력하고, 하네스가 못 알아들은 명령이 있으면 그 아래에 출력한다. 명령 목록은 play.gd 머리 주석에 있다.
import sys
import time
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8")
d = Path(sys.argv[1])
done = d / "done"
done.unlink(missing_ok=True)
(d / "cmd.tmp").write_text("\n".join(sys.argv[2:]), encoding="utf-8")
(d / "cmd.tmp").replace(d / "cmd.txt")  # 하네스가 반쯤 쓴 명령을 읽지 않게 이름을 바꿔 넣는다
deadline = time.monotonic() + 120  # ponytail: 고정 120초. 긴 wait 한 번이 넘치면 늘린다
while not done.exists():
    if time.monotonic() > deadline:
        sys.exit("응답 없음: 하네스 창이 닫혔거나 Godot이 멈췄다")
    time.sleep(0.05)
name, *errors = done.read_text(encoding="utf-8").splitlines()
print(d / f"{name}.png")
for e in errors:
    print(e)
