import json, sys, re
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8")
S = Path(sys.argv[1])          # scratchpad
OUT = Path(sys.argv[2])        # game_design_research/99_appendix

r1 = json.loads((S / "result.json").read_text(encoding="utf-8"))
r2 = json.loads((S / "round2_merged.json").read_text(encoding="utf-8"))

ledger = []

for i, f in enumerate(r1["findings"], 1):
    tag = re.match(r"\[(.+?)\]", f["claim"])
    ledger.append({
        "id": f"R1-F{i}", "round": 1, "topic": tag.group(1) if tag else "",
        "status": "확인", "votes": f"3표 반박 검증 {f.get('vote','')}", "confidence": f["confidence"],
        "claim": re.sub(r"^\[.+?\]\s*", "", f["claim"]), "alt_claim": "",
        "evidence": f["evidence"], "sources": f["sources"],
    })

for i, x in enumerate(r1["refuted"], 1):
    ledger.append({
        "id": f"R1-X{i}", "round": 1, "topic": "기각된 주장",
        "status": "기각", "votes": f"3표 반박 검증 {x['vote']}", "confidence": "-",
        "claim": x["claim"], "alt_claim": "", "evidence": "", "sources": [x["source"]],
    })

ST = {"confirmed-2": "확인", "confirmed-1": "확인(1관점)", "partial": "부분 확인",
      "disputed": "논란", "refuted": "기각", "unverifiable": "확인 불가"}
for c in r2["batches"]:
    f, x = c["fidelity"], c["crosscheck"]
    prim = f if f["verdict"] != "confirmed" else (x if x["verdict"] != "confirmed" else f)
    other = x if prim is f else f
    alt = other["corrected_claim"] if other["verdict"] == "partial" and other["corrected_claim"] != prim["corrected_claim"] else ""
    srcs = list(dict.fromkeys([c["orig_source"]] + f["sources"] + x["sources"]))
    ledger.append({
        "id": f"R2-{c['id']}", "round": 2, "topic": c["batch"],
        "status": ST[c["status"]], "votes": f"2관점 검증(출처 대조/교차 확인) {c['votes']}", "confidence": "-",
        "claim": prim["corrected_claim"], "alt_claim": alt,
        "evidence": f"[출처 대조] {f['evidence']}\n[교차 확인] {x['evidence']}", "sources": srcs,
    })

for g in r2["gaps"]:
    fd, v = g["found"], g["verify"]
    claim = fd["claim"] if g["status"] == "confirmed" else v["corrected_claim"]
    gid = g["id"].replace("_kr_thronefall_omd", "").replace("_wc3_legion_ironbrigade_dd", "") \
                 .replace("_aura_command_collapse", "").replace("_counters_dominant", "")
    ledger.append({
        "id": f"R2-{gid}", "round": 2, "topic": f"{g['topic']} / {fd['game']}",
        "status": ST.get(g["status"], g["status"]) if g["status"] != "confirmed" else "확인(1표)",
        "votes": f"보충 조사 + 1표 반박 검증 {g['status']}", "confidence": fd["source_quality"],
        "claim": claim, "alt_claim": "",
        "evidence": f"[원문] {fd['quote']}\n[검증] {v['evidence']}",
        "sources": list(dict.fromkeys(fd["sources"] + v["sources"])),
        "design_relevance": fd["design_relevance"],
    })

(S / "ledger.json").write_text(json.dumps(ledger, ensure_ascii=False, indent=1), encoding="utf-8")

def cut(s, n):
    s = s.replace("\n", " ").strip()
    return s if len(s) <= n else s[:n].rstrip() + " …"

OUT.mkdir(parents=True, exist_ok=True)
md = ["# 주장 대장 (Claim Ledger)", "",
      "본문 문서가 `[R1-F5]`처럼 인용하는 모든 주장의 원장이다. 스크립트로 검증 결과에서 생성했으며 손으로 고치지 않는다.", "",
      "- `R1-F*`: 1차 리서치 종합 결과. 주장마다 3표 반박 검증을 통과(2/3 이상 생존).",
      "- `R1-X*`: 1차 리서치에서 **기각**된 주장. 근거로 인용 금지.",
      "- `R2-C*`: 1차에서 추출만 되고 검증 못 한 주장을 2차에서 2관점(출처 대조 / 독립 교차 확인)으로 재검증. `부분 확인`이면 과장을 걷어낸 수정 문장이 들어 있다.",
      "- `R2-G*`: 2차 보충 조사로 새로 찾은 주장. 1표 반박 검증. 다른 그룹보다 검증 강도가 낮다.",
      "- 근거 칸의 원문 인용에는 수치가 남아 있다. 출처 원문을 바꾸지 않으려고 둔 것이며, 설계 제안이 아니다.", ""]
groups = [("1차 확인 (R1-F)", "R1-F"), ("1차 기각 (R1-X) — 인용 금지", "R1-X"), ("2차 재검증 (R2-C)", "R2-C"), ("2차 보충 조사 (R2-G)", "R2-G")]
for title, pre in groups:
    md += [f"## {title}", ""]
    for e in [e for e in ledger if e["id"].startswith(pre)]:
        md += [f"### {e['id']} · {e['status']}", "",
               f"- 주제: {e['topic']}", f"- 검증: {e['votes']}" + (f" · 신뢰도/출처 품질: {e['confidence']}" if e['confidence'] != '-' else ""),
               f"- 주장: {e['claim']}"]
        if e["alt_claim"]:
            md.append(f"- 교차 확인 쪽 수정 문장: {e['alt_claim']}")
        md.append("- 출처: " + " · ".join(e["sources"]))
        if e["evidence"]:
            md += ["", "<details><summary>근거</summary>", "", cut(e["evidence"], 1500), "", "</details>"]
        md.append("")
(OUT / "claim_ledger.md").write_text("\n".join(md), encoding="utf-8")

src = {}
for e in ledger:
    for u in e["sources"]:
        src.setdefault(u, []).append(e["id"])
sm = ["# 출처 목록", "", "주장 대장에 쓰인 출처 전체. 오른쪽은 그 출처를 쓴 주장 ID다.", ""]
for u, ids in sorted(src.items()):
    sm.append(f"- {u} — {', '.join(ids)}")
(OUT / "sources.md").write_text("\n".join(sm) + "\n", encoding="utf-8")

from collections import Counter
print(len(ledger), Counter(e["status"] for e in ledger), len(src))
