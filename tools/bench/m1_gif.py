# tools/bench/m1.gd가 찍은 프레임 → GIF. 저장소용 1배(art/trial/preview/<m1|m6>_<안>.gif)와 3배(<출력 폴더>/<m1|m6>_<안>_x3.gif).
# Gemini 판정용 mp4(<출력 폴더>/<이름>_x3_slow10.mp4)도 쓴다: 웹 업로드가 GIF를 정지 JPG 한 장으로 바꿔서(2026-10-20) 영상으로 보내고, 10배 느리게(1초 = 게임 0.1초) 둔다.
# 영상은 3배 화면의 가운데 960×540(주인공 둘레 약 10×5.6칸)만 쓴다. 전체 화면이면 10MB 업로드 한도를 넘는다. 주인공 발밑은 영상 좌표 (480, 270)이다
# 사용: python tools/bench/m1_gif.py <m1.gd 출력 폴더>
import sys
from pathlib import Path

import cv2
import numpy as np
from PIL import Image

root = Path(sys.argv[1])
pv = Path(__file__).resolve().parents[2] / "art" / "trial" / "preview"
for d in sorted(p for p in root.iterdir() if p.is_dir()):
    frames = [Image.open(f).convert("RGB") for f in sorted(d.glob("*.png"))]
    dur = ([30, 30, 40] * len(frames))[:len(frames)]  # 30fps(33.3ms)를 GIF의 10ms 단위로
    big = [f.resize((f.width * 3, f.height * 3), Image.NEAREST) for f in frames]
    for seq, out in ((frames, pv / f"{d.name}.gif"), (big, root / f"{d.name}_x3.gif")):
        seq[0].save(out, save_all=True, append_images=seq[1:], duration=dur, loop=0)
        print(out, out.stat().st_size // 1024, "KB")
    mp4 = root / f"{d.name}_x3_slow10.mp4"
    big = [f.crop((480, 270, 1440, 810)) for f in big]
    w = cv2.VideoWriter(str(mp4), cv2.VideoWriter_fourcc(*"avc1"), 3, big[0].size)
    if not w.isOpened():  # H.264 인코더가 없는 OpenCV 빌드
        w = cv2.VideoWriter(str(mp4), cv2.VideoWriter_fourcc(*"mp4v"), 3, big[0].size)
    for f in big:
        w.write(cv2.cvtColor(np.asarray(f), cv2.COLOR_RGB2BGR))
    w.release()
    print(mp4, mp4.stat().st_size // 1024, "KB")
