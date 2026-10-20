# M6(06 §2)용 임시 적: 기사(hero.py)에서 검·방패를 뺀 몸통. 자세는 기사와 같아서 공격은 빈손으로 내려친다. 45°·외곽선 D·f24p·24px
# 사용: python tools/art/brute.py  → art/trial/brute/ 에 정지·걷기·공격·쓰러짐 시트, art/trial/preview/brute_* 에 확대본
from pathlib import Path

import hero as H

OUT = Path(__file__).resolve().parents[2] / "art" / "trial" / "brute"


def brute(pose, bob_unit):
    return [q for q in H.knight(pose, bob_unit) if q[2] not in ("sword", "shield")]


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    fts = H.fits(OUT, [H.IDLE] + H.WALK, brute, "brute m5", (24,))
    for anim in H.ANIMS:
        H.save(anim, anim, 45, "D", "f24p", fts, brute, out=OUT)
    H.preview("brute", OUT, fts[24], [(H.OUT, H.fits()[24])])
    print("ok")
