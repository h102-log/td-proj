"""밸런스 스윕: autoplay.gd를 설정 × 씨앗마다 병렬로 돌려 요약한다(WBS 3.4·5.5용 도구, 평가 아님).

    python tools/balance/sweep.py configs.json [--seeds 1-8] [--jobs 4] [--out result.json]

configs.json은 {"이름": 설정, ...}이다. 설정은 autoplay.gd 머리 주석의 키(seed 제외)다.
요약은 설정마다 승률, 도달 라운드, 라운드별 거점 최저 체력·성문 파괴·새어 든 적·영웅 다운·남긴 골드다.

--panel: configs.json을 {"후보 이름": {"over": {...}}}로 읽고, 후보마다 봇 패널(PANEL) 넷을 모두 돌려
긴장감 점수(score, 낮을수록 목표에 가깝다)를 낸다. 목표 띠는 TARGETS다.
"""
import argparse
import json
import os
import shutil
import statistics
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

# 봇 패널: 숙련(영웅 1로 시작)·숙련(영웅 2로 시작)·중간(영웅 손을 안 씀)·약함(병영 먼저, 타워 1)
PANEL = {
    "smart": {"name": "smart", "plan": "smart", "hire_first_count": 1, "rally": [20, 8], "fill": True},
    "smart2": {"name": "smart2", "plan": "smart", "hire_first_count": 2, "rally": [20, 8], "fill": True},
    "mid": {"name": "mid", "plan": "smart", "hire_first_count": 1, "rally": [20, 8], "fill": True,
            "micro": False, "skills": False},
    "weak": {"name": "weak", "plan": "balanced", "hire_first_count": 1, "fill": True},
    # 사람형: 숙련 + 3라운드부터 영웅 1명을 마을 거점 옆에 둔다(3장 자체 점검 검증에서 더함)
    "smartv": {"name": "smartv", "plan": "smart", "hire_first_count": 1, "rally": [20, 8], "fill": True,
               "village_heroes": 1, "village_from": 3},
}
# 긴장감 목표(사용자 결정이 아니라 Claude 가정이다. 설계 결정 «바쁨»·«감당하는 건 실력»에서 옮겼다)
TARGETS = {
    # 숙련 봇의 라운드별 거점 최저 체력(그 라운드 웨이브 가운데 최저, 그 라운드를 치른 판 평균) 띠: 점점 조여 온다
    "base_curve": {1: (0.85, 1.0), 2: (0.75, 0.95), 3: (0.65, 0.9), 4: (0.55, 0.85), 5: (0.45, 0.8), 6: (0.35, 0.75)},
    "win_smart": (0.40, 0.75),   # 숙련 봇 도전 성공률
    "win_smart2": (0.30, 0.75),
    "win_smartv": (0.50, 0.90),  # 사람형 봇도 끝까지 승부가 갈리게
    "idle_max": 0.30,            # 웨이브 시간 가운데 적이 아무 데도 닿지 않은 비율
    "busy_mid": 0.10,            # 2~3라운드에 위협 지점이 둘 이상인 시간 비율
    "busy_late": 0.25,           # 4~6라운드
    "weak_r1": 0.5,              # 약한 봇이 1라운드를 넘기는 비율(첫 라운드가 벽이 아니게)
    "mid_rounds": (2.5, 4.5),    # 중간 봇이 이기는 라운드 수
}


def _band(v, lo, hi):
    return max(0.0, lo - v, v - hi)


def score(by_bot):
    """봇 이름 → 실행 결과 목록. 점수와 항목별 값을 돌려준다(낮을수록 좋다)."""
    t = TARGETS
    parts = {}
    curve = {}
    curve_bots = [b for b in ("smart", "smart2", "smartv") if b in by_bot]
    for bot in curve_bots:
        runs = [r for r in by_bot.get(bot, []) if "error" not in r]
        for rnd in range(1, 7):
            vals = []
            for r in runs:
                ws = [w for w in r["waves"] if w["r"] == rnd]
                if ws:
                    vals.append(min(w["base_min"] for w in ws))
            curve[(bot, rnd)] = statistics.mean(vals) if vals else 0.0
    parts["curve"] = sum(_band(curve[(b, r)], *t["base_curve"][r]) for b in curve_bots for r in range(1, 7))
    win = {b: statistics.mean(r["result"] == "won" for r in by_bot[b] if "error" not in r) for b in by_bot}
    parts["win"] = 2 * (_band(win.get("smart", 0), *t["win_smart"]) + _band(win.get("smart2", 0), *t["win_smart2"])
                        + (_band(win["smartv"], *t["win_smartv"]) if "smartv" in win else 0.0))
    sw = [w for r in by_bot.get("smart", []) if "error" not in r for w in r["waves"]]
    idle = statistics.mean(w["idle"] / max(w["secs"], 0.1) for w in sw) if sw else 1.0
    parts["idle"] = 2 * max(0.0, idle - t["idle_max"])
    busy_mid = statistics.mean([w["busy"] / max(w["secs"], 0.1) for w in sw if w["r"] in (2, 3)] or [0])
    busy_late = statistics.mean([w["busy"] / max(w["secs"], 0.1) for w in sw if w["r"] >= 4] or [0])
    parts["busy"] = max(0.0, t["busy_mid"] - busy_mid) + max(0.0, t["busy_late"] - busy_late)
    weak = [r for r in by_bot.get("weak", []) if "error" not in r]
    weak_r1 = statistics.mean((r["round"] > 1 or r["result"] == "won") for r in weak) if weak else 0.0
    parts["weak_r1"] = 2 * max(0.0, t["weak_r1"] - weak_r1)
    mid = [r["round"] + (1 if r["result"] == "won" else 0) - 1 for r in by_bot.get("mid", []) if "error" not in r]
    mid_rounds = statistics.mean(mid) if mid else 0.0
    parts["mid"] = 0.3 * _band(mid_rounds, *t["mid_rounds"])
    info = {
        "win": {k: round(v, 2) for k, v in win.items()}, "idle": round(idle, 2), "busy_mid": round(busy_mid, 2),
        "busy_late": round(busy_late, 2), "weak_r1": round(weak_r1, 2), "mid_rounds": round(mid_rounds, 2),
        "curve_smart": [round(curve[("smart", r)], 2) for r in range(1, 7)],
        "curve_smart2": [round(curve[("smart2", r)], 2) for r in range(1, 7)],
    }
    if "smartv" in by_bot:
        info["curve_smartv"] = [round(curve[("smartv", r)], 2) for r in range(1, 7)]
    return round(sum(parts.values()), 3), {k: round(v, 3) for k, v in parts.items()}, info


def godot():
    return os.environ.get("GODOT") or shutil.which("godot") or "godot"


def run_one(cfg):
    r = subprocess.run(
        [godot(), "--headless", "--path", str(ROOT), "-s", "res://tools/balance/autoplay.gd", "--", json.dumps(cfg)],
        capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=1800,
    )
    errs = [l for l in (r.stdout + r.stderr).splitlines() if l.startswith("SCRIPT ERROR")]
    for line in r.stdout.splitlines():
        if line.startswith("RESULT "):
            res = json.loads(line[7:])
            if errs:  # 스크립트 오류가 나도 판은 끝까지 돌아 RESULT를 낸다. 봇이 엉뚱하게 둔 판일 수 있다
                res["script_errors"] = errs[:3]
            return res
    return {"error": (r.stdout + r.stderr)[-2000:]}


def warn_script_errors(results):
    bad = [r for r in results if r.get("script_errors")]
    if bad:
        print(f"!! 경고: 스크립트 오류가 난 판 {len(bad)}/{len(results)}개. 결과를 믿지 말 것. 첫 오류: {bad[0]['script_errors'][0]}")


def seeds_of(text):
    if "-" in text:
        a, b = text.split("-")
        return list(range(int(a), int(b) + 1))
    return [int(x) for x in text.split(",")]


def summarize(name, runs):
    ok = [r for r in runs if "error" not in r]
    won = sum(r["result"] == "won" for r in ok)
    reached = [r["round"] + (1 if r["result"] == "won" else 0) - 1 for r in ok]  # 이긴 라운드 수
    rows = {}
    for r in ok:
        for w in r["waves"]:
            rows.setdefault((w["r"], w["w"]), []).append(w)
    lines = [f"== {name}: 승 {won}/{len(ok)} · 이긴 라운드 평균 {statistics.mean(reached) if reached else 0:.2f} "
             f"(분포 {sorted(reached)})" + (f" · 오류 {len(runs) - len(ok)}" if len(ok) < len(runs) else "")]
    lines.append("   R W  n  거점min 거점끝 성문min 성문파괴 잔해 새어듦 영웅다운 용병잃음 남긴골드 들어온골드 길이 한가 동시최대 다지점 영웅Lv 타워수")
    for (rr, ww), ws in sorted(rows.items()):
        m = lambda k: statistics.mean(w[k] for w in ws)
        lines.append(
            f"   {rr} {ww} {len(ws):2d}  {m('base_min'):6.2f} {m('base_hp_end'):6.2f} {m('gate_min'):6.2f} "
            f"{sum(w['gate_min'] == 0 for w in ws) / len(ws):7.0%} {m('castle_lost'):4.1f} {m('leak'):6.1f} {m('hero_down'):7.1f} "
            f"{m('merc_lost'):7.1f} {m('unspent'):8.0f} {m('gold_in'):9.0f} {m('secs'):5.0f} {m('idle'):4.0f} {m('peak'):6.1f} "
            f"{statistics.mean(w.get('busy', 0) / max(w['secs'], 0.1) for w in ws):6.0%} "
            f"{statistics.mean(max(w.get('lv', [0]) or [0]) for w in ws):5.1f} "
            f"{statistics.mean(sum(v for k, v in w.get('def', {}).items() if k in ('tower', 'magic', 'cannon')) for w in ws):5.1f}")
    return "\n".join(lines)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("configs")
    ap.add_argument("--seeds", default="1-8")
    ap.add_argument("--jobs", type=int, default=max(1, (os.cpu_count() or 2)))
    ap.add_argument("--out")
    ap.add_argument("--panel", action="store_true")
    ap.add_argument("--quiet", action="store_true", help="--panel에서 봇별 표를 빼고 점수만")
    a = ap.parse_args()
    configs = json.loads(Path(a.configs).read_text(encoding="utf-8"))
    seeds = seeds_of(a.seeds)
    if a.panel:
        return run_panel(configs, seeds, a)
    jobs = [(name, dict(cfg, seed=s)) for name, cfg in configs.items() for s in seeds]
    with ThreadPoolExecutor(a.jobs) as ex:
        results = list(ex.map(lambda j: run_one(j[1]), jobs))
    warn_script_errors(results)
    by = {}
    for (name, cfg), res in zip(jobs, results):
        res["seed"] = cfg["seed"]
        by.setdefault(name, []).append(res)
    for name in configs:
        print(summarize(name, by[name]))
    if a.out:
        Path(a.out).write_text(json.dumps(by, ensure_ascii=False, indent=1), encoding="utf-8")


def run_panel(cands, seeds, a):
    jobs = [(c, bot, dict(cands[c], bot=PANEL[bot], seed=s)) for c in cands for bot in PANEL for s in seeds]
    with ThreadPoolExecutor(a.jobs) as ex:
        results = list(ex.map(lambda j: run_one(j[2]), jobs))
    warn_script_errors(results)
    by = {}
    for (c, bot, cfg), res in zip(jobs, results):
        res["seed"] = cfg["seed"]
        by.setdefault(c, {}).setdefault(bot, []).append(res)
    out = {}
    for c in cands:
        total, parts, info = score(by[c])
        out[c] = {"score": total, "parts": parts, "info": info}
        print(f"#### {c}: 점수 {total}  {parts}")
        print(f"     {info}")
        if not a.quiet:
            for bot in PANEL:
                print(summarize(f"{c}/{bot}", by[c][bot]))
    if a.out:
        Path(a.out).write_text(json.dumps({"scores": out, "runs": by}, ensure_ascii=False, indent=1), encoding="utf-8")


if __name__ == "__main__":
    sys.exit(main())
