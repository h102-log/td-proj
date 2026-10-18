# SVG → PNG. Chromium 계열 브라우저의 헤드리스 --screenshot으로 찍는다(Node·Playwright 없이 Chrome·Edge만 있으면 된다)
# 사용: python tools/art/concept/shot.py 그림.svg 출력.png [--scale 4]
# 브라우저는 환경 변수 CHROME이 먼저다. 없으면 Playwright headless_shell → PATH의 chromium·chrome → Windows Chrome·Edge 순으로 찾는다
import argparse
import glob
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image

PAD = 200  # 새 헤드리스(--headless=new)는 --window-size보다 짧은 화면을 칠한다(아래 약 90px이 흰 띠). 창을 키워 찍고 자른다
TILE = 2_200_000  # 한 번에 찍는 장치 픽셀 상한. 8K를 한 번에 찍으면 타일 메모리 한도를 넘어 대부분이 빈 채로 찍혔다
ROOT = re.compile(r'<svg\b[^>]*>')


def browser():
    if os.environ.get("CHROME"):
        return os.environ["CHROME"]
    pw = os.environ.get("PLAYWRIGHT_BROWSERS_PATH", "")
    found = sorted(glob.glob(os.path.join(pw, "chromium_headless_shell-*", "*", "headless_shell"))) if pw else []
    if found:
        return found[-1]
    for name in ("chromium", "chromium-browser", "google-chrome", "chrome", "msedge"):
        if shutil.which(name):
            return shutil.which(name)
    for p in (r"C:\Program Files\Google\Chrome\Application\chrome.exe",
              r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
              r"C:\Program Files\Microsoft\Edge\Application\msedge.exe"):
        if os.path.exists(p):
            return p
    sys.exit("Chromium 계열 브라우저를 못 찾았다. CHROME 환경 변수에 실행 파일 경로를 넣는다")


def size(text):
    """svg 루트의 width·height(px)"""
    head = ROOT.search(text).group(0)
    return tuple(int(float(re.search(rf'\b{k}="([\d.]+)"', head).group(1))) for k in ("width", "height"))


def _one(exe, svg, w, h, scale, td):
    shell = "headless_shell" in Path(exe).name
    tmp = Path(td) / "shot.png"
    args = [exe, "--disable-gpu", "--hide-scrollbars", "--run-all-compositor-stages-before-draw",
            f"--window-size={w},{h if shell else h + PAD}", f"--force-device-scale-factor={scale}",
            f"--screenshot={tmp}", Path(svg).resolve().as_uri()]
    if not shell:
        args.insert(1, "--headless=new")
    if hasattr(os, "geteuid") and os.geteuid() == 0:
        args.insert(1, "--no-sandbox")  # 리눅스 root에서는 샌드박스가 뜨지 않는다
    r = subprocess.run(args, capture_output=True, text=True, errors="replace", timeout=600)
    if r.returncode or "tile memory limits exceeded" in r.stderr:
        sys.exit(f"찍기 실패({w}×{h} ×{scale}): {r.stderr[-400:]}")
    return Image.open(tmp).convert("RGB").crop((0, 0, w * scale, h * scale))


def shot(svg, png, scale=1):
    exe = browser()
    text = Path(svg).read_text(encoding="utf-8")
    w, h = size(text)
    nx = ny = 1
    while (w / nx) * (h / ny) * scale * scale > TILE:  # 긴 쪽부터 나눈다
        if w / nx >= h / ny:
            nx += 1
        else:
            ny += 1
    xs = [round(w * i / nx) for i in range(nx + 1)]
    ys = [round(h * j / ny) for j in range(ny + 1)]
    root = ROOT.search(text).group(0)
    vb = re.search(r'\bviewBox="([^"]*)"', root)
    vx, vy, vw, vh = map(float, vb.group(1).replace(",", " ").split()) if vb else (0, 0, w, h)
    out = Image.new("RGB", (w * scale, h * scale))
    with tempfile.TemporaryDirectory() as td:
        for j in range(ny):
            for i in range(nx):
                x, y, tw, th = xs[i], ys[j], xs[i + 1] - xs[i], ys[j + 1] - ys[j]
                box = f"{vx + x * vw / w:g} {vy + y * vh / h:g} {tw * vw / w:g} {th * vh / h:g}"  # 타일 = 원래 viewBox의 그 부분
                sub = re.sub(r'\bheight="[^"]*"', f'height="{th}"', re.sub(r'\bwidth="[^"]*"', f'width="{tw}"', root))
                sub = re.sub(r'\bviewBox="[^"]*"', f'viewBox="{box}"', sub) if vb else sub.replace("<svg", f'<svg viewBox="{box}"', 1)
                tile = Path(td) / "tile.svg"
                tile.write_text(text.replace(root, sub, 1), encoding="utf-8")
                out.paste(_one(exe, tile, tw, th, scale, td), (x * scale, y * scale))
    out.save(png)
    return png


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("svg")
    ap.add_argument("png")
    ap.add_argument("--scale", type=int, default=1)
    a = ap.parse_args()
    print(shot(a.svg, a.png, a.scale))
