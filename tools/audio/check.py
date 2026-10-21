"""WAV마다 길이·최대값·RMS·직류·처음과 끝 값을 출력하고, 스펙트로그램을 한 장으로 그린다. python check.py <폴더> <png>"""
import sys
import wave
import pathlib
import numpy as np
from scipy import signal
from PIL import Image, ImageDraw

folder = pathlib.Path(sys.argv[1])
rows = []
for p in sorted(folder.glob("*.wav")):
    with wave.open(str(p)) as w:
        sr = w.getframerate()
        x = np.frombuffer(w.readframes(w.getnframes()), "<i2").astype(float) / 32768
    rms = np.sqrt(np.mean(x ** 2))
    print(f"{p.name:22s} {len(x) / sr:6.2f}s peak {np.max(np.abs(x)):.2f} rms {rms:.3f} dc {np.mean(x):+.4f} "
          f"first {x[0]:+.3f} last {x[-1]:+.3f} silent-tail {np.mean(np.abs(x[-sr // 2:]) < 0.01) if len(x) > sr else 0:.2f}")
    f, tt, s = signal.spectrogram(x, sr, nperseg=1024, noverlap=768)
    s = 10 * np.log10(s + 1e-10)
    keep = f < 8000
    img = np.clip((s[keep] + 100) / 80, 0, 1)[::-1]
    im = Image.fromarray((img * 255).astype(np.uint8)).resize((min(1200, max(200, img.shape[1])), 160))
    rows.append((p.name, im))
W = max(im.width for _, im in rows)
sheet = Image.new("L", (W, sum(im.height + 16 for _, im in rows)), 0)
d = ImageDraw.Draw(sheet)
y = 0
for name, im in rows:
    d.text((2, y), name, fill=255)
    sheet.paste(im, (0, y + 14))
    y += im.height + 16
sheet.save(sys.argv[2])
