"""5.3 효과음·음악(S269, S271, I205): 코드로 합성해 audio/sfx/<키>.wav와 audio/music/<키>.wav로 쓴다.
합성 도구(파형·포락선·필터·음 이름)는 시제품 proto.py에서 가져온다. 영웅마다 음색 하나를 정하고(아이아스 쇠, 이그니스 불,
실비아 바람, 세라피나 종, 베스퍼 거품·불협, 크로노스 째깍·태엽) 스킬마다 몸짓을 다르게 한다.
음악 4곡은 한 바퀴를 세 번 이어 메아리를 건 뒤 가운데 바퀴만 잘라, 끝이 처음으로 이어진다(I205).
python tools/audio/make.py            # 저장소의 audio/에 쓴다
python tools/audio/make.py <폴더>      # 다른 폴더에 쓴다"""
import sys
import wave
import pathlib
import numpy as np
from scipy import signal

sys.path.insert(0, str(pathlib.Path(__file__).parent))
from proto import (SR, osc, noise, env, decay, slide, lp, hp, bp, sweep_lp, voice, drums, hz,  # noqa: E402
                   sfx_ui_click, sfx_refuse, sfx_build, sfx_arrow, sfx_cannon, sfx_magic, sfx_hit,
                   sfx_enemy_die, sfx_coin, sfx_wave_start, sfx_boss, sfx_fireball)

MUSIC_SR = 22050  # 음악은 반으로 줄여 쓴다(파일 크기). 칩튠이라 11kHz 위가 거의 없다


def n_of(sec):
    return int(sec * SR)


def tt(n):
    return np.arange(n) / SR


def cat(*parts):
    return np.concatenate(parts)


def gap(sec):
    return np.zeros(n_of(sec))


def mix(*parts):
    """길이가 다른 파형을 앞에 맞춰 더한다"""
    out = np.zeros(max(len(p) for p in parts))
    for p in parts:
        out[:len(p)] += p
    return out


def at(x, sec, total=None):
    """x를 sec초 뒤에 놓는다"""
    return np.pad(x, (n_of(sec), 0) if total is None else (n_of(sec), max(0, total - n_of(sec) - len(x))))


def clang(f, n, k=9.0, ratios=(1.0, 2.76, 5.4, 8.9)):
    """쇠를 친 소리: 배음이 어긋난 사인 묶음"""
    return sum(osc("sine", f * r, n) * decay(n, k * (1 + i * 0.7)) / (1 + i) for i, r in enumerate(ratios))


def bell(f, n, k=4.0):
    """종: 맑은 배음(2.0·3.0·4.2)"""
    return clang(f, n, k, (1.0, 2.0, 3.0, 4.2))


def whoosh(n, f0, f1, q=0.6):
    """바람 소리: 띠 잡음의 가운데 주파수가 움직인다"""
    x = noise(n)
    out = np.zeros(n)
    blk = 256
    zi = np.zeros(4)
    for i in range(0, n, blk):
        f = f0 * (f1 / f0) ** (i / max(1, n))
        lo, hi = max(60.0, f * (1 - q / 2)), min(SR / 2 - 200, f * (1 + q / 2))
        b, a = signal.butter(2, [lo / (SR / 2), hi / (SR / 2)], "band")
        out[i:i + blk], zi = signal.lfilter(b, a, x[i:i + blk], zi=zi)
    return out


def chord(names, n, kind="tri", duty=0.5, k=3.0):
    return sum(osc(kind, hz(m), n, duty) for m in names) / len(names) * decay(n, k)


def arp(names, step, kind="square", duty=0.25, ring=0.25, k=12.0):
    """음을 step초 간격으로 차례로 울린다. 음마다 ring초 동안 k로 줄어든다"""
    n = n_of(ring)
    note = np.minimum(1, tt(n) / 0.003) * decay(n, k)
    return mix(*[at(osc(kind, hz(m), n, duty) * note, i * step) for i, m in enumerate(names)])


def blips(n, rate, f_lo, f_hi, seed):
    """거품: 무작위 때에 짧게 오르는 사인"""
    r = np.random.default_rng(seed)
    out = np.zeros(n)
    m = n_of(0.05)
    t = 0
    while t < n - m:
        f = r.uniform(f_lo, f_hi)
        out[t:t + m] += osc("sine", slide(f, f * 1.8, m), m) * decay(m, 60) * r.uniform(0.4, 1.0)
        t += int(SR / rate * r.uniform(0.4, 1.6))
    return out


def ticks(times, f=3200.0, k=180.0):
    """째깍: 아주 짧은 사각파 딸깍"""
    m = n_of(0.03)
    c = osc("square", f, m, 0.5) * decay(m, k) + hp(noise(m), 4000) * decay(m, 250) * 0.6
    total = n_of(max(times) + 0.05)
    return mix(*[at(c, s, total) for s in times])


# ── 전투 ────────────────────────────────────────────────

def swing():
    n = n_of(0.13)
    return whoosh(n, 900, 2600, 0.8) * env(n, 0.02, 0.03, 0.7, 0.06) * 1.4


def boom():
    n = n_of(0.4)
    body = osc("sine", slide(95, 40, n, 0.5), n) * decay(n, 10)
    crack = sweep_lp(noise(n, 9000), 4000, 200) * decay(n, 14)
    return body + crack * 0.7


def hurt():
    n = n_of(0.09)
    thud = osc("square", slide(240, 80, n), n, 0.5) * decay(n, 40)
    return lp(thud * 0.6 + lp(noise(n, 4000), 2000) * decay(n, 50) * 0.5, 3000)


def struct_hit():
    n = n_of(0.14)
    knock = osc("tri", slide(300, 120, n, 0.4), n) * decay(n, 35)
    chip = bp(noise(n, 7000), 1500, 5000) * decay(n, 70) * 0.6
    return knock + chip


def ally_down():
    n = n_of(0.4)
    fall = osc("tri", slide(440, 150, n, 0.7), n) * env(n, 0.003, 0.05, 0.7, 0.25)
    return fall + lp(noise(n, 3000), 1200) * decay(n, 18) * 0.3


def hero_down():
    a = arp(["A4", "F4", "D4", "A3"], 0.12, "square", 0.5, 0.3, 8)
    n = len(a)
    thud = osc("sine", slide(120, 45, n_of(0.3), 0.5), n_of(0.3)) * decay(n_of(0.3), 12)
    return lp(mix(a * 0.6, at(thud, 0.36)), 4000)


def boss_skill():
    n = n_of(0.9)
    quake = lp(noise(n, 300), 200) * env(n, 0.01, 0.1, 0.7, 0.5) * 1.5
    slam = osc("sine", slide(80, 30, n, 0.6), n) * decay(n, 5)
    return quake + slam + sfx_boss()[:n] * 0.25


def interrupt():
    n = n_of(0.35)
    shatter = hp(noise(n, 12000), 2500) * decay(n, 16)
    ping = osc("tri", slide(1800, 600, n, 0.6), n) * decay(n, 12) * 0.5
    return shatter * 0.7 + ping


def collapse():
    n = n_of(1.3)
    rumble = sweep_lp(noise(n, 2000), 900, 120) * env(n, 0.01, 0.2, 0.7, 0.8)
    r = np.random.default_rng(11)
    rocks = mix(*[at(struct_hit() * r.uniform(0.3, 0.7), r.uniform(0.05, 0.9), n) for _ in range(7)])
    return rumble * 1.2 + rocks[:n]


# ── 스킬 터짐 ──────────────────────────────────────────

def meteor():
    n = n_of(1.0)
    blast = sweep_lp(noise(n, 11000), 7000, 150) * decay(n, 5)
    body = osc("sine", slide(110, 30, n, 0.5), n) * decay(n, 4)
    crack = hp(noise(n_of(0.04)), 1500)
    return mix(blast * 0.9 + body, crack)


def trap():
    n = n_of(0.45)
    snap = hp(noise(n_of(0.02)), 3000) * 1.2
    gust = whoosh(n, 3000, 500, 0.9) * env(n, 0.005, 0.05, 0.7, 0.3)
    return mix(snap, gust * 1.5)


def burst():
    n = n_of(0.7)
    return mix(clang(196, n, 6) * 0.8, boom() * 0.8)


def loop_back():
    n = n_of(0.5)
    rev = whoosh(n, 400, 3000, 0.8) * np.linspace(0, 1, n) ** 2  # 빨려 들듯 커지다 끊긴다
    thump = osc("sine", slide(140, 50, n_of(0.25), 0.5), n_of(0.25)) * decay(n_of(0.25), 14)
    return cat(rev * 1.2, thump)


def resonate():
    n = n_of(1.0)
    return sum(bell(hz(m), n, 3) for m in ["A5", "C#6", "E6"]) / 2


# ── 영웅 스킬 24 ───────────────────────────────────────

def s_shield_bash():
    return cat(swing()[:n_of(0.08)], mix(clang(330, n_of(0.5), 10), boom() * 0.6))


def s_war_cry():
    n = n_of(0.9)
    vib = 1 + 0.02 * np.sin(2 * np.pi * 6 * tt(n))
    f = slide(130, 175, n, 0.3) * vib
    roar = (osc("saw", f, n) + osc("saw", f * 1.5, n) * 0.6 + osc("square", f * 0.5, n, 0.3) * 0.5) / 2
    return sweep_lp(roar, 500, 2500) * env(n, 0.04, 0.2, 0.8, 0.4) + lp(noise(n), 400) * decay(n, 4) * 0.4


def s_brace():
    n = n_of(0.6)
    return clang(523, n, 5) * 0.8 + clang(784, n, 7) * 0.4


def s_bulwark():
    n = n_of(1.2)
    hum = osc("saw", slide(80, 160, n, 0.5), n) * env(n, 0.1, 0.2, 0.8, 0.5)
    shimmer = sum(osc("sine", hz(m) * (1 + 0.004 * np.sin(2 * np.pi * 7 * tt(n))), n) for m in ["E5", "B5", "E6"]) / 3
    return lp(hum, 900) * 0.6 + shimmer * env(n, 0.3, 0.2, 0.6, 0.5) * 0.6


def s_fireball():
    return sfx_fireball()


def s_frost_ring():
    n = n_of(0.8)
    gliss = osc("sine", slide(2400, 900, n, 0.5), n) * decay(n, 4) * 0.5
    r = np.random.default_rng(5)
    crystals = mix(*[at(osc("tri", r.uniform(2500, 5000), n_of(0.06)) * decay(n_of(0.06), 50), r.uniform(0, 0.5), n) for _ in range(10)])
    return gliss + crystals[:n] * 0.5 + hp(noise(n), 5000) * decay(n, 8) * 0.25


def s_black_hole():
    n = n_of(1.2)
    suck = whoosh(n, 3000, 200, 0.9) * np.linspace(0.2, 1, n) * 1.5
    sub = osc("sine", slide(90, 35, n, 0.7), n) * env(n, 0.2, 0.2, 0.8, 0.4)
    return suck + sub * 0.9


def s_meteor_swarm():
    n = n_of(0.9)
    whistle = osc("sine", slide(2600, 500, n, 0.8), n) * env(n, 0.05, 0.1, 0.8, 0.2) * 0.5
    return whistle + whoosh(n, 500, 3000, 0.7) * env(n, 0.4, 0.1, 0.7, 0.2)


def s_piercing_gale():
    n = n_of(0.45)
    return mix(whoosh(n, 800, 5000, 0.5) * env(n, 0.005, 0.05, 0.8, 0.3) * 1.6, sfx_arrow() * 0.5)


def s_split_shot():
    a = sfx_arrow()
    return mix(a, at(a * 0.8, 0.07), at(osc("tri", slide(900, 1300, n_of(0.1)), n_of(0.1)) * decay(n_of(0.1), 30) * 0.4, 0.0))


def s_storm_trap():
    clicks = ticks([0.0, 0.08], 1800, 120)
    n = n_of(0.4)
    return mix(clicks, at(whoosh(n, 1200, 600, 0.8) * env(n, 0.05, 0.05, 0.6, 0.2) * 0.8, 0.1))


def s_arrow_rain():
    r = np.random.default_rng(9)
    n = n_of(1.1)
    one = n_of(0.25)
    shafts = [at(osc("sine", slide(r.uniform(2500, 3500), r.uniform(600, 900), one, 0.6), one) * decay(one, 10) * 0.3, r.uniform(0, 0.8), n) for _ in range(12)]
    return mix(*shafts)[:n] + whoosh(n, 2000, 800, 0.8) * env(n, 0.2, 0.1, 0.6, 0.5) * 0.6


def s_holy_beam():
    beam = arp(["E5", "G#5", "B5", "E6", "G#6"], 0.04, "tri", 0.5, 0.35, 8)
    n = len(beam)
    return beam * 0.7 + osc("sine", hz("E6"), n) * env(n, 0.01, 0.1, 0.4, 0.2) * 0.3


def s_sanctum():
    n = n_of(1.2)
    pad = lp(sum(osc("saw", hz(m), n) for m in ["A3", "C#4", "E4", "A4"]) / 4, 1500) * env(n, 0.25, 0.2, 0.7, 0.5)
    return pad * 0.8 + bell(hz("A5"), n, 3) * 0.4


def s_guardian():
    n = n_of(0.7)
    flutter = bp(noise(n), 800, 4000) * (0.5 + 0.5 * np.sin(2 * np.pi * 18 * tt(n))) * env(n, 0.05, 0.1, 0.7, 0.3)
    return mix(flutter * 0.8, arp(["C#5", "E5", "A5"], 0.09, "tri", 0.5, 0.4, 6) * 0.7)


def s_miracle():
    n = n_of(1.6)
    swell = sum(osc("tri", hz(m), n) for m in ["D4", "F#4", "A4", "D5", "F#5"]) / 5 * env(n, 0.5, 0.3, 0.7, 0.6)
    return swell + bell(hz("D6"), n, 2.5) * 0.4 * np.clip(tt(n) / 0.5, 0, 1)


def s_corrosion():
    n = n_of(0.9)
    hiss = bp(noise(n), 2000, 6000) * env(n, 0.1, 0.2, 0.5, 0.4) * 0.5
    return blips(n, 30, 150, 400, 3) * 0.8 + hiss


def s_enfeeble():
    n = n_of(0.8)
    wob = 1 + 0.03 * np.sin(2 * np.pi * 8 * tt(n))
    a = osc("square", slide(330, 220, n, 0.6) * wob, n, 0.3)
    b = osc("square", slide(466, 311, n, 0.6) * wob, n, 0.3)
    return lp((a + b) * 0.5, 1800) * env(n, 0.02, 0.1, 0.7, 0.4)


def s_soul_chain():
    r = np.random.default_rng(13)
    n = n_of(0.7)
    links = mix(*[at(clang(r.uniform(900, 1400), n_of(0.12), 30) * 0.5, i * 0.07, n) for i in range(6)])
    drone = osc("saw", hz("D2"), n) * env(n, 0.05, 0.1, 0.6, 0.3)
    return links[:n] + lp(drone, 500) * 0.5


def s_abyss():
    n = n_of(1.4)
    lfo = 0.6 + 0.4 * np.sin(2 * np.pi * 3 * tt(n))
    drone = lp(osc("saw", slide(60, 45, n), n) + osc("saw", slide(63.5, 47.6, n), n), 400) * lfo * env(n, 0.2, 0.2, 0.8, 0.5)
    return drone * 0.6 + blips(n, 12, 80, 200, 21) * 0.7


def s_overcharge():
    n = n_of(0.6)
    f = slide(200, 1600, n, 0.6)
    zap = osc("saw", f, n) * (0.6 + 0.4 * osc("square", 40, n)) * env(n, 0.01, 0.1, 0.7, 0.2)
    return mix(lp(zap, 5000) * 0.6, ticks([0.0, 0.1, 0.2]) * 0.5)


def s_aging():
    times = [0.0, 0.14, 0.32, 0.55, 0.85]
    tk = ticks(times, 2600, 150)
    n = len(tk) + n_of(0.2)
    low = osc("tri", slide(400, 180, n, 0.5), n) * env(n, 0.01, 0.1, 0.6, 0.4) * 0.5
    return mix(tk, low)


def s_time_loop():
    n = n_of(0.8)
    swell = (whoosh(n, 3000, 600, 0.7) * np.linspace(0, 1, n) ** 2) * 1.4
    return mix(swell, at(ticks([0.0, 0.25], 2000, 120), 0.3))


def s_wind_up():
    times = list(np.cumsum([0.0] + [0.11 * 0.85 ** i for i in range(9)]))
    n = n_of(max(times) + 0.15)
    rise = osc("square", slide(300, 900, n, 0.7), n, 0.2) * env(n, 0.05, 0.1, 0.5, 0.1) * 0.25
    return mix(ticks(times, 1500, 100), lp(rise, 3000))


# ── 건설·경제·판 흐름·UI ───────────────────────────────

def complete():
    return arp(["C5", "G5"], 0.08, "square", 0.5, 0.18, 14) * 0.7


def hire():
    return arp(["G4", "C5", "E5", "G5"], 0.07, "square", 0.5, 0.2, 10) * 0.6


def level_up():
    return arp(["C5", "E5", "G5", "C6", "E6"], 0.06, "square", 0.25, 0.22, 10) * 0.6


def boss_appear():
    n = n_of(1.6)
    drum = mix(*[at(osc("sine", slide(90, 40, n_of(0.3), 0.5), n_of(0.3)) * decay(n_of(0.3), 9), s, n) for s in (0.0, 0.25)])
    return mix(drum[:n], at(sfx_boss(), 0.15) * 0.8)


def alert():
    n = n_of(0.12)
    a = osc("square", 880, n, 0.5) * env(n, 0.003, 0.02, 0.7, 0.03)
    b = osc("square", 660, n, 0.5) * env(n, 0.003, 0.02, 0.7, 0.03)
    return lp(cat(a, b, a, b), 3500) * 0.6


SKILLS = {"shield_bash": s_shield_bash, "war_cry": s_war_cry, "brace": s_brace, "bulwark": s_bulwark,
          "fireball": s_fireball, "frost_ring": s_frost_ring, "black_hole": s_black_hole, "meteor_swarm": s_meteor_swarm,
          "piercing_gale": s_piercing_gale, "split_shot": s_split_shot, "storm_trap": s_storm_trap, "arrow_rain": s_arrow_rain,
          "holy_beam": s_holy_beam, "sanctum": s_sanctum, "guardian": s_guardian, "miracle": s_miracle,
          "corrosion": s_corrosion, "enfeeble": s_enfeeble, "soul_chain": s_soul_chain, "abyss": s_abyss,
          "overcharge": s_overcharge, "aging": s_aging, "time_loop": s_time_loop, "wind_up": s_wind_up}

# 키 → (만드는 함수, 최대값). 자주 나는 소리는 작게, 드문 소리는 크게
SFX = {
    "arrow": (sfx_arrow, 0.45), "bolt": (lambda: sfx_magic()[:n_of(0.25)], 0.4), "cannon": (sfx_cannon, 0.75),
    "swing": (swing, 0.4), "hit": (sfx_hit, 0.4), "boom": (boom, 0.65), "hurt": (hurt, 0.45), "struct_hit": (struct_hit, 0.45),
    "enemy_die": (sfx_enemy_die, 0.5), "ally_down": (ally_down, 0.6), "hero_down": (hero_down, 0.8),
    "boss_skill": (boss_skill, 0.85), "interrupt": (interrupt, 0.75), "collapse": (collapse, 0.8),
    "meteor": (meteor, 0.85), "trap": (trap, 0.7), "burst": (burst, 0.8), "loop": (loop_back, 0.75), "resonate": (resonate, 0.7),
    "build": (sfx_build, 0.6), "complete": (complete, 0.55), "sell": (sfx_coin, 0.55), "hire": (hire, 0.6),
    "level_up": (level_up, 0.65), "wave_start": (sfx_wave_start, 0.8), "boss_appear": (boss_appear, 0.9),
    "alert": (alert, 0.55), "click": (sfx_ui_click, 0.35), "refuse": (sfx_refuse, 0.5),
}
SFX.update({"skill_" + k: (f, 0.75) for k, f in SKILLS.items()})


# ── 음악 ──────────────────────────────────────────────

def song_title():
    """메인 메뉴: 76 BPM, D 단조, 느린 영웅풍 — Dm·B♭·F·C 위 삼각파 아르페지오와 긴 선율"""
    bpm = 76
    prog = [("D", "F", "A", "2"), ("A#", "D", "F", "1"), ("F", "A", "C", "2"), ("C", "E", "G", "2")]
    arp_, bass, pad = [], [], []
    for root, third, fifth, lo in prog:
        for _ in range(2):
            arp_ += [(root + "4", 0.5), (fifth + "4", 0.5), (third + "5", 0.5), (fifth + "4", 0.5)]
        bass += [(root + lo, 2), (root + lo, 1.5), (root + str(int(lo) + 1), 0.5)]
        pad += [(root + "3", 4)]
    arp_, bass, pad = arp_ * 4, bass * 4, pad * 4
    melody = [("A4", 2), ("D5", 1), ("E5", 1), ("F5", 3), ("E5", 1), ("D5", 2), ("C5", 2), ("A4", 4),
              ("A#4", 2), ("A4", 1), ("G4", 1), ("A4", 3), ("C5", 1), ("D5", 8),
              (None, 16),
              ("F5", 2), ("G5", 1), ("A5", 1), ("G5", 3), ("F5", 1), ("E5", 2), ("C5", 2), ("D5", 4)]
    total = n_of(64 * 60 / bpm)
    a = voice(arp_, bpm, "tri", a=0.01, d=0.15, s=0.4, r=0.15, total=total) * 0.22
    b = voice(bass, bpm, "tri", a=0.02, d=0.3, s=0.7, r=0.2, total=total) * 0.4
    p = lp(voice(pad, bpm, "saw", a=0.6, d=0.4, s=0.6, r=0.8, total=total), 800) * 0.1
    m = voice(melody, bpm, "square", 0.5, 0.04, 0.2, 0.6, 0.25, vib=0.012, total=total) * 0.13
    return a + b + p + lp(m, 3500), 60 / bpm * 0.75, 0.3, 0.35


def song_boss():
    """보스: 152 BPM, E 프리지안, 16분 베이스·거친 톱니 리드·두꺼운 드럼"""
    bpm = 152
    roots = ["E", "E", "F", "E", "E", "E", "G", "F"]
    bass = []
    for r_ in roots:
        bass += [(r_ + "2", 0.25), (r_ + "2", 0.25), (r_ + "3", 0.25), (r_ + "2", 0.25)] * 4
    bass = bass * 2
    lead = [("E5", 1.5), ("F5", 0.5), ("E5", 1), ("B4", 1), ("C5", 2), ("B4", 1), ("A#4", 1),
            ("E5", 1.5), ("F5", 0.5), ("G5", 1), ("F5", 1), ("E5", 4),
            ("B5", 1.5), ("A5", 0.5), ("G5", 1), ("F5", 1), ("E5", 2), ("F5", 1), ("G5", 1),
            ("A#5", 1.5), ("A5", 0.5), ("G5", 1), ("F5", 1), ("E5", 4)] * 2
    total = n_of(64 * 60 / bpm)
    b = lp(voice(bass, bpm, "square", 0.5, 0.002, 0.04, 0.5, 0.03, total=total), 1000) * 0.32
    l_ = lp(voice(lead, bpm, "saw", a=0.01, d=0.1, s=0.6, r=0.08, vib=0.01, total=total), 3500) * 0.13
    stab = voice([(n[:-1] + str(int(n[-1]) - 1), d) for n, d in lead], bpm, "square", 0.125, total=total) * 0.07
    d = beat_drums("k.hkskh.kkh.skhs", bpm, total) * 0.6
    return b + l_ + stab + d, 60 / bpm * 0.5, 0.25, 0.18


def beat_drums(pattern, bpm, total):
    """한 마디 패턴(16분 칸)을 곡 길이에 들어가는 만큼만 잇고 뒤는 비운다. 시제품 drums(total=)처럼 잘라 붙이면
    칸 길이 반올림이 쌓여 곡 끝에 다음 바퀴의 첫 칸(킥)이 걸린다"""
    one = drums(pattern, bpm)
    x = np.tile(one, total // len(one))
    return np.pad(x, (0, total - len(x)))


def song_prep():
    """준비: 90 BPM, D 단조, 느린 아르페지오와 낮은 패드 — 시제품 proto.song_prep의 악보에서 메아리를 뺀 마른 소리"""
    bpm = 90
    prog = [("D", "F", "A"), ("A#", "D", "F"), ("G", "A#", "D"), ("A", "C#", "E")]
    arp_, bass, pad = [], [], []
    for root, third, fifth in prog:
        lo = {"D": "3", "A#": "2", "G": "2", "A": "2"}[root]
        for _ in range(4):
            arp_ += [(root + "4", 0.5), (third + "4", 0.5), (fifth + "4", 0.5), (third + "4", 0.5)]
        bass += [(root + lo, 4), (root + lo, 4)]
        pad += [(root + "3", 8)]
    arp_, bass, pad = arp_ * 2, bass * 2, pad * 2
    melody = [(None, 16), ("A4", 3), ("F4", 1), ("G4", 2), ("A4", 2), ("A#4", 3), ("A4", 1), ("G4", 4),
              ("F4", 3), ("E4", 1), ("D4", 2), ("F4", 2), ("E4", 6), (None, 2)]
    total = n_of(64 * 60 / bpm)
    a = voice(arp_, bpm, "square", 0.25, 0.005, 0.1, 0.3, 0.1, total=total) * 0.16
    b = voice(bass, bpm, "tri", a=0.02, d=0.3, s=0.7, r=0.3, total=total) * 0.45
    p = lp(voice(pad, bpm, "saw", a=0.8, d=0.5, s=0.6, r=1.0, total=total), 900) * 0.12
    m = voice(melody, bpm, "square", 0.5, 0.03, 0.2, 0.6, 0.2, vib=0.01, total=total) * 0.14
    return lp(a, 3500) + b + p + lp(m, 4000), 60 / bpm * 0.75, 0.3, 0.35


def song_battle():
    """전투: 140 BPM, D 단조, 몰아치는 8분 베이스·리드·드럼 — 시제품 proto.song_battle의 악보에서 메아리를 뺀 마른 소리"""
    bpm = 140
    bass = []
    for r_ in ["D", "D", "A#", "C", "D", "D", "G", "A"]:
        bass += [(r_ + "2", 0.5), (r_ + "3", 0.5)] * 4
    bass = bass * 2
    lead = [("D5", 1), ("A4", 0.5), ("D5", 0.5), ("F5", 1), ("E5", 1), ("D5", 1.5), ("C5", 0.5), ("A4", 2),
            ("A#4", 1), ("A4", 0.5), ("G4", 0.5), ("A#4", 1), ("C5", 1), ("A4", 4),
            ("D5", 1), ("A4", 0.5), ("D5", 0.5), ("F5", 1), ("G5", 1), ("A5", 1.5), ("G5", 0.5), ("F5", 2),
            ("E5", 1), ("D5", 0.5), ("C#5", 0.5), ("E5", 2), ("D5", 4)] * 2
    total = n_of(64 * 60 / bpm)
    b = lp(voice(bass, bpm, "square", 0.5, 0.003, 0.05, 0.5, 0.04, total=total), 1200) * 0.32
    l_ = voice(lead, bpm, "square", 0.25, 0.01, 0.1, 0.55, 0.08, vib=0.008, total=total) * 0.15
    harm = voice([(n[:-1] + str(int(n[-1]) - 1), d) for n, d in lead], bpm, "tri", total=total) * 0.12
    d = beat_drums("k.h.s.h.k.k.s.hh", bpm, total) * 0.55
    return b + lp(l_, 5000) + harm + d, 60 / bpm * 0.5, 0.25, 0.2


def seamless(dry, delay, fb, wet):
    """한 바퀴를 세 번 이어 메아리를 걸고 MUSIC_SR로 줄인 뒤 가운데 바퀴를 잘라, 끝이 처음으로 이어지는 한 바퀴를 만든다(I205).
    필터·리샘플의 앞뒤 흔들림이 잘라 낸 바퀴에 닿지 않는다"""
    dry = dry[:len(dry) // 2 * 2]  # 2:1로 줄인 바퀴 길이가 정수가 되게
    L = len(dry)
    x = np.tile(dry, 3)
    d = int(delay * SR)
    y = x.copy()
    for k in range(1, 6):
        y[d * k:] += x[:len(x) - d * k] * (fb ** k) * wet / fb
    y = np.tanh(hp(y, 20) * 1.2)
    y = signal.resample_poly(y, MUSIC_SR, SR)
    m = L * MUSIC_SR // SR
    return y[m:2 * m]


SONGS = {"title": song_title, "prep": song_prep, "battle": song_battle, "boss": song_boss}


# ── 징글 ──────────────────────────────────────────────

def j_clear():
    a = arp(["D5", "F#5", "A5", "D6"], 0.1, "square", 0.5, 0.25, 8)
    n = n_of(1.2)
    return mix(a * 0.6, at(chord(["D4", "F#4", "A4", "D5"], n, "tri", k=2.5) * 0.7, 0.4))


def j_win():
    bpm = 132
    lead = [("D5", 0.5), ("D5", 0.5), ("D5", 0.5), ("D5", 1), ("A#4", 1), ("C5", 1), ("D5", 0.75), ("C5", 0.25), ("D5", 3)]
    m = voice(lead, bpm, "square", 0.5, 0.005, 0.08, 0.7, 0.1, vib=0.01) * 0.5
    harm = voice([(n[:-1] + "4", d) for n, d in lead], bpm, "tri", 0.5) * 0.35
    n = len(m)
    bass = voice([("D3", 2.5), ("A#2", 1), ("C3", 1), ("D3", 4)], bpm, "tri", total=n) * 0.5
    return (m + harm[:n] + bass) * np.clip((n - np.arange(n)) / n_of(0.6), 0, 1)


def j_lose():
    bpm = 70
    seq = [("A4", 1), ("F4", 1), ("D4", 1), ("C#4", 3)]
    m = voice(seq, bpm, "square", 0.5, 0.01, 0.2, 0.6, 0.4, vib=0.015) * 0.45
    n = len(m)
    pad = lp(voice([("D3", 3), ("A2", 3)], bpm, "saw", a=0.3, d=0.3, s=0.6, r=1.0, total=n), 700) * 0.3
    return (m + pad) * np.clip((n - np.arange(n)) / n_of(1.0), 0, 1)


JINGLES = {"clear": j_clear, "win": j_win, "lose": j_lose}


# ── 쓰기 ──────────────────────────────────────────────

def finish(x, peak):
    """효과음·징글: 직류를 빼고 부드럽게 눌러 peak로 맞춘다. 처음 1ms·끝 6ms는 0으로 모은다(틱 방지)"""
    x = np.tanh(hp(x, 20) * 1.2)
    x -= np.mean(x)  # 짧은 소리는 20Hz 고역 통과만으로 직류가 다 빠지지 않는다
    x[-n_of(0.006):] *= np.linspace(1, 0, n_of(0.006))
    x[:n_of(0.001)] *= np.linspace(0, 1, n_of(0.001))
    m = np.max(np.abs(x))
    return x / m * peak if m > 0 else x


def write(path, x, rate):
    x = np.clip(x, -1, 1)
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(rate)
        w.writeframes(np.round(x * 32767).astype("<i2").tobytes())


def main(out):
    (out / "sfx").mkdir(parents=True, exist_ok=True)
    (out / "music").mkdir(parents=True, exist_ok=True)
    for key, (fn, peak) in SFX.items():
        write(out / "sfx" / f"{key}.wav", finish(fn(), peak), SR)
    for key, fn in SONGS.items():
        x = seamless(*fn())
        x = x / np.max(np.abs(x)) * 0.8
        write(out / "music" / f"{key}.wav", x, MUSIC_SR)
    for key, fn in JINGLES.items():
        x = finish(fn(), 0.8)
        x = signal.resample_poly(x, MUSIC_SR, SR)
        x[:22] *= np.linspace(0, 1, 22)
        x[-132:] *= np.linspace(1, 0, 132)
        write(out / "music" / f"{key}.wav", x, MUSIC_SR)
    for p in sorted(out.glob("*/*.wav")):
        with wave.open(str(p)) as w:
            print(f"{p.parent.name}/{p.name}\t{w.getnframes() / w.getframerate():.2f}s")


if __name__ == "__main__":
    main(pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else pathlib.Path(__file__).resolve().parents[2] / "audio")
