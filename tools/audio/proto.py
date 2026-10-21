"""5.3 소리 시제품(2026-10-22): 코드로 합성한 효과음 12개와 음악 두 곡(준비 약 43초·전투 약 27초)을 WAV로 쓴다.
사용자가 아직 듣지 않았다. 들은 뒤 방향이 정해지면 이 파일을 바탕으로 효과음·음악 도구를 나눈다(next/2026-10-22/r2.md).
음악은 끝에 메아리 꼬리가 붙어 이음매 없이 반복되지 않는다.
python tools/audio/proto.py <출력 폴더>"""
import sys
import wave
import pathlib
import numpy as np
from scipy import signal

SR = 44100
rng = np.random.default_rng(7)


def t(sec):
    return np.arange(int(SR * sec)) / SR


def phase(freq):
    """주파수 배열(또는 수) → 0..1 위상"""
    f = np.broadcast_to(np.asarray(freq, dtype=float), (len(freq),) if np.ndim(freq) else (1,))
    return np.cumsum(f) / SR % 1.0


def osc(kind, freq, n=None, duty=0.5):
    if np.ndim(freq) == 0:
        freq = np.full(n, float(freq))
    p = np.cumsum(freq) / SR % 1.0
    if kind == "square":
        return np.where(p < duty, 1.0, -1.0)
    if kind == "saw":
        return 2.0 * p - 1.0
    if kind == "tri":
        return 4.0 * np.abs(p - 0.5) - 1.0
    if kind == "sine":
        return np.sin(2 * np.pi * p)
    raise ValueError(kind)


def noise(n, hold_hz=None):
    """sfxr식 잡음. hold_hz를 주면 그 빈도로 값을 붙잡아 거친 8비트 잡음이 된다"""
    if not hold_hz:
        return rng.uniform(-1, 1, n)
    step = max(1, int(SR / hold_hz))
    v = rng.uniform(-1, 1, n // step + 1)
    return np.repeat(v, step)[:n]


def env(n, a=0.005, d=0.05, s=0.6, r=0.1, hold=None):
    """ADSR. hold는 서스테인 길이(초), 없으면 n에 맞춘다"""
    A, D, R = int(a * SR), int(d * SR), int(r * SR)
    S = n - A - D - R if hold is None else int(hold * SR)
    S = max(S, 0)
    e = np.concatenate([np.linspace(0, 1, A, endpoint=False), np.linspace(1, s, D, endpoint=False),
                        np.full(S, s), np.linspace(s, 0, R)])
    return np.pad(e, (0, max(0, n - len(e))))[:n]


def decay(n, k):
    return np.exp(-np.arange(n) / SR * k)


def slide(f0, f1, n, curve=1.0):
    x = np.linspace(0, 1, n) ** curve
    return f0 * (f1 / f0) ** x


def lp(x, hz, order=2):
    b, a = signal.butter(order, min(hz, SR / 2 - 100) / (SR / 2), "low")
    return signal.lfilter(b, a, x)


def hp(x, hz, order=2):
    b, a = signal.butter(order, hz / (SR / 2), "high")
    return signal.lfilter(b, a, x)


def bp(x, lo, hi, order=2):
    b, a = signal.butter(order, [lo / (SR / 2), hi / (SR / 2)], "band")
    return signal.lfilter(b, a, x)


def sweep_lp(x, f0, f1):
    """잘라 내는 주파수가 시간에 따라 움직이는 저역 통과(블록마다 계수 갱신)"""
    out = np.zeros_like(x)
    blk = 256
    zi = np.zeros(2)
    for i in range(0, len(x), blk):
        f = f0 * (f1 / f0) ** (i / max(1, len(x)))
        b, a = signal.butter(2, min(f, SR / 2 - 100) / (SR / 2), "low")
        out[i:i + blk], zi = signal.lfilter(b, a, x[i:i + blk], zi=zi)
    return out


def echo(x, delay=0.18, fb=0.35, mix=0.3):
    d = int(delay * SR)
    y = np.concatenate([x, np.zeros(d * 6)])
    for k in range(1, 6):
        y[d * k:d * k + len(x)] += x * (fb ** k) * mix / fb
    return y


def finish(x, peak=0.89):
    x = hp(x, 20)  # 듀티가 0.5가 아닌 사각파의 직류 성분을 뺀다
    x = np.tanh(x * 1.2)  # 부드러운 클리핑
    fade = min(len(x), int(0.004 * SR))
    x[-fade:] *= np.linspace(1, 0, fade)
    rise = int(0.001 * SR)  # 첫 표본이 0이 아니면 틱 소리가 난다
    x[:rise] *= np.linspace(0, 1, rise)
    m = np.max(np.abs(x))
    return x / m * peak if m > 0 else x


def write(path, x):
    x = np.clip(x, -1, 1)
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((x * 32767).astype("<i2").tobytes())


# ── 효과음 ─────────────────────────────────────────────

def sfx_ui_click():
    n = int(0.045 * SR)
    return osc("square", slide(1400, 900, n), duty=0.25) * decay(n, 70) * 0.5


def sfx_refuse():
    n = int(0.09 * SR)
    a = osc("square", 196, n, 0.5) * env(n, 0.002, 0.02, 0.7, 0.03)
    b = osc("square", 147, n, 0.5) * env(n, 0.002, 0.02, 0.7, 0.04)
    return lp(np.concatenate([a, np.zeros(int(0.02 * SR)), b]), 2500) * 0.6


def sfx_build():
    n = int(0.28 * SR)
    knock = osc("tri", slide(220, 70, n, 0.4), n) * decay(n, 18)
    dust = lp(noise(n), 1800) * decay(n, 25) * 0.6
    n2 = int(0.12 * SR)
    knock2 = osc("tri", slide(260, 90, n2, 0.4), n2) * decay(n2, 30)
    return np.concatenate([knock + dust, knock2 * 0.7]) * 0.9


def sfx_arrow():
    n = int(0.16 * SR)
    twang = osc("tri", slide(1100, 420, n, 0.5), n) * decay(n, 30) * 0.6
    air = hp(noise(n), 3000) * decay(n, 45) * 0.5
    return twang + air


def sfx_cannon():
    n = int(0.75 * SR)
    boom = osc("sine", slide(110, 38, n, 0.5), n) * decay(n, 6)
    blast = sweep_lp(noise(n, 9000), 5000, 300) * decay(n, 9)
    crack = hp(noise(int(0.03 * SR)), 2000)
    blast[:len(crack)] += crack * 0.8
    return boom * 0.9 + blast * 0.8


def sfx_magic():
    n = int(0.35 * SR)
    f = slide(500, 1500, n, 0.7) * (1 + 0.03 * np.sin(2 * np.pi * 28 * t(0.35)[:n]))
    zap = osc("saw", f, n) * env(n, 0.005, 0.08, 0.5, 0.2)
    spark = osc("square", f * 2.01, n, 0.125) * decay(n, 14) * 0.3
    return lp(zap * 0.5 + spark, 6000)


def sfx_hit():
    n = int(0.07 * SR)
    thud = osc("square", slide(320, 110, n), n, 0.5) * decay(n, 50)
    crunch = lp(noise(n, 6000), 3500) * decay(n, 60)
    return lp(thud * 0.5 + crunch * 0.7, 4000)


def sfx_enemy_die():
    n = int(0.32 * SR)
    fall = osc("square", slide(520, 70, n, 0.6), n, 0.3) * env(n, 0.002, 0.05, 0.6, 0.2)
    crumble = lp(noise(n, 4000), 2200) * decay(n, 10) * 0.5
    return lp(fall * 0.5 + crumble, 5000)


def sfx_coin():
    n1, n2 = int(0.06 * SR), int(0.22 * SR)
    a = osc("square", 988, n1, 0.5) * env(n1, 0.001, 0.01, 0.8, 0.01)
    b = osc("square", 1319, n2, 0.5) * decay(n2, 14)
    return lp(np.concatenate([a, b]), 7000) * 0.45


def sfx_wave_start():
    n = int(1.1 * SR)
    vib = 1 + 0.006 * np.sin(2 * np.pi * 5.5 * t(1.1)[:n])
    horn = sum(osc("saw", f * vib, n) for f in (146.83, 220.0, 293.66)) / 3
    horn = sweep_lp(horn, 600, 2200) * env(n, 0.12, 0.2, 0.8, 0.45)
    drum = lp(noise(int(0.25 * SR)), 300) * decay(int(0.25 * SR), 14)
    horn[:len(drum)] += drum
    return horn


def sfx_boss():
    n = int(1.4 * SR)
    f = slide(70, 48, n, 0.8) * (1 + 0.08 * np.sin(2 * np.pi * 7 * t(1.4)[:n]))
    growl = osc("saw", f, n) * 0.6 + osc("square", f * 1.5, n, 0.3) * 0.3
    rasp = bp(noise(n, 2500), 200, 1200) * 0.7
    x = lp(growl + rasp * (0.5 + 0.5 * np.sin(2 * np.pi * 11 * t(1.4)[:n])), 1400)
    return x * env(n, 0.08, 0.3, 0.8, 0.6)


def sfx_fireball():
    n1 = int(0.45 * SR)
    whoosh = sweep_lp(noise(n1), 400, 3500) * env(n1, 0.2, 0.1, 0.8, 0.15) * 0.6
    n2 = int(0.7 * SR)
    burst = sweep_lp(noise(n2, 11000), 6000, 250) * decay(n2, 7)
    body = osc("sine", slide(150, 45, n2, 0.5), n2) * decay(n2, 8) * 0.8
    return np.concatenate([whoosh, burst + body])


SFX = {"ui_click": sfx_ui_click, "refuse": sfx_refuse, "build": sfx_build, "arrow": sfx_arrow,
       "cannon": sfx_cannon, "magic": sfx_magic, "hit": sfx_hit, "enemy_die": sfx_enemy_die,
       "coin": sfx_coin, "wave_start": sfx_wave_start, "boss": sfx_boss, "fireball": sfx_fireball}

# ── 음악 ──────────────────────────────────────────────

NOTE = {"C": 0, "C#": 1, "D": 2, "D#": 3, "E": 4, "F": 5, "F#": 6, "G": 7, "G#": 8, "A": 9, "A#": 10, "B": 11}


def hz(name):
    """«D4»·«A#3» → 주파수"""
    pitch, octv = name[:-1], int(name[-1])
    return 440.0 * 2 ** ((NOTE[pitch] + 12 * (octv + 1) - 69) / 12)


def voice(seq, bpm, kind, duty=0.5, a=0.01, d=0.08, s=0.6, r=0.08, vib=0.0, total=None):
    """seq: [(음 이름 또는 None, 박 수)] → 파형"""
    beat = 60.0 / bpm
    out = []
    for note, beats in seq:
        n = int(beats * beat * SR)
        if note is None:
            out.append(np.zeros(n))
            continue
        f = np.full(n, hz(note))
        if vib:
            f *= 1 + vib * np.sin(2 * np.pi * 5.0 * np.arange(n) / SR) * np.clip(np.arange(n) / SR / 0.25, 0, 1)
        out.append(osc(kind, f, n, duty) * env(n, a, d, s, min(r, beats * beat * 0.5)))
    x = np.concatenate(out)
    if total:
        x = np.pad(x, (0, max(0, total - len(x))))[:total]
    return x


def drums(pattern, bpm, steps_per_beat=4, total=None):
    """pattern: 문자열, k=킥 s=스네어 h=하이햇 .=쉼"""
    step = 60.0 / bpm / steps_per_beat
    n = int(step * SR)
    parts = []
    for c in pattern:
        if c == "k":
            m = osc("sine", slide(150, 45, n, 0.4), n) * decay(n, 22)
        elif c == "s":
            m = bp(noise(n, 8000), 900, 5000) * decay(n, 28) * 0.7 + osc("tri", 190, n) * decay(n, 40) * 0.3
        elif c == "h":
            m = hp(noise(n), 6000) * decay(n, 90) * 0.35
        else:
            m = np.zeros(n)
        parts.append(m)
    x = np.concatenate(parts)
    if total:
        reps = int(np.ceil(total / len(x)))
        x = np.tile(x, reps)[:total]
    return x


def loop(seq, times):
    return seq * times


def song_prep():
    """준비 단계: 90 BPM, D 단조, 느린 아르페지오와 낮은 패드 — 조용한 긴장"""
    bpm = 90
    prog = [("D", "F", "A"), ("A#", "D", "F"), ("G", "A#", "D"), ("A", "C#", "E")]
    arp, bass, pad = [], [], []
    for root, third, fifth in prog:
        lo = {"D": "3", "A#": "2", "G": "2", "A": "2"}[root]
        for _ in range(4):
            arp += [(root + "4", 0.5), (third + "4", 0.5), (fifth + "4", 0.5), (third + "4", 0.5)]
        bass += [(root + lo, 4), (root + lo, 4)]
        pad += [(root + "3", 8)]
    arp = loop(arp, 2)
    bass = loop(bass, 2)
    pad = loop(pad, 2)
    melody = [(None, 16), ("A4", 3), ("F4", 1), ("G4", 2), ("A4", 2), ("A#4", 3), ("A4", 1), ("G4", 4),
              ("F4", 3), ("E4", 1), ("D4", 2), ("F4", 2), ("E4", 6), (None, 2)]
    total = int(64 * 60 / bpm * SR)
    a = voice(arp, bpm, "square", 0.25, 0.005, 0.1, 0.3, 0.1, total=total) * 0.16
    b = voice(bass, bpm, "tri", a=0.02, d=0.3, s=0.7, r=0.3, total=total) * 0.45
    p = lp(voice(pad, bpm, "saw", a=0.8, d=0.5, s=0.6, r=1.0, total=total), 900) * 0.12
    m = voice(melody, bpm, "square", 0.5, 0.03, 0.2, 0.6, 0.2, vib=0.01, total=total) * 0.14
    mix = lp(a, 3500) + b + p + lp(m, 4000)
    return echo(mix, 60 / bpm * 0.75, 0.3, 0.35)


def song_battle():
    """전투 단계: 140 BPM, D 단조, 몰아치는 8분 베이스·리드·드럼"""
    bpm = 140
    roots = ["D", "D", "A#", "C", "D", "D", "G", "A"]
    bass = []
    for r_ in roots:
        o = "2" if r_ in ("A#", "C", "G", "A") else "2"
        bass += [(r_ + o, 0.5), (r_ + "3", 0.5)] * 4
    bass = loop(bass, 2)
    lead = [("D5", 1), ("A4", 0.5), ("D5", 0.5), ("F5", 1), ("E5", 1), ("D5", 1.5), ("C5", 0.5), ("A4", 2),
            ("A#4", 1), ("A4", 0.5), ("G4", 0.5), ("A#4", 1), ("C5", 1), ("A4", 4),
            ("D5", 1), ("A4", 0.5), ("D5", 0.5), ("F5", 1), ("G5", 1), ("A5", 1.5), ("G5", 0.5), ("F5", 2),
            ("E5", 1), ("D5", 0.5), ("C#5", 0.5), ("E5", 2), ("D5", 4)]
    lead = loop(lead, 2)
    total = int(64 * 60 / bpm * SR)
    b = voice(bass, bpm, "square", 0.5, 0.003, 0.05, 0.5, 0.04, total=total)
    b = lp(b, 1200) * 0.32
    l_ = voice(lead, bpm, "square", 0.25, 0.01, 0.1, 0.55, 0.08, vib=0.008, total=total) * 0.15
    harm = voice([(n[:-1] + str(int(n[-1]) - 1), d) if n else (None, d) for n, d in lead], bpm, "tri",
                 total=total) * 0.12
    d = drums("k.h.s.h.k.k.s.hh", bpm, total=total) * 0.55
    mix = b + lp(l_, 5000) + harm + d
    return echo(mix, 60 / bpm * 0.5, 0.25, 0.2)


if __name__ == "__main__":
    out = pathlib.Path(sys.argv[1])
    out.mkdir(parents=True, exist_ok=True)
    for name, fn in SFX.items():
        write(out / f"sfx_{name}.wav", finish(fn()))
    write(out / "music_prep.wav", finish(song_prep(), 0.8))
    write(out / "music_battle.wav", finish(song_battle(), 0.8))
    for p in sorted(out.glob("*.wav")):
        with wave.open(str(p)) as w:
            print(f"{p.name}\t{w.getnframes() / SR:.2f}s")
