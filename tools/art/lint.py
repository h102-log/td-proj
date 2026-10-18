# 숫자 검사. 이미지로 보기 전에 먼저 돌린다(08 §3 운영 규칙)
# H5: 팔레트 밖 색·반투명·프레임 크기. H3·H4: 걷기 프레임 차이(부위 이미지 parts/ 사용). T1은 tiles.py에 있다
# 사용: python tools/art/lint.py walk_45_D_f24p  → 크기마다 결과
import sys

import numpy as np
from PIL import Image

import render as R
from hero import OUT, PARTS, WALK

# 걷기에서 다리 말고는 오르내림만 허용한다(사용자 2026-10-18: 머리·몸통·무기 고정)
BODY = [1 + PARTS.index(p) for p in ("head", "torso", "arm", "sword", "shield")]
LIMB = [1 + PARTS.index("leg")]
HEAD = 1 + PARTS.index("head")


def frames(path, n):
    """시트 → (행, 열, n, n, …)"""
    a = np.array(Image.open(path))
    return a.reshape(a.shape[0] // n, n, a.shape[1] // n, n, *a.shape[2:]).swapaxes(1, 2)


def h5(path, pal, n):
    a = np.array(Image.open(path).convert("RGBA"))
    errs = []
    if a.shape[0] % n or a.shape[1] % n:
        errs.append(f"크기 {a.shape[1]}×{a.shape[0]}가 {n}의 배수가 아니다")
    if not np.isin(a[..., 3], (0, 255)).all():
        errs.append("반투명 픽셀")
    bad = {tuple(c) for c in a[a[..., 3] == 255][:, :3]} - {tuple(c) for c in pal}
    if bad:
        errs.append(f"팔레트 밖 색 {len(bad)}개")
    f = frames(path, n)[..., 3] > 0
    edge = f[:, :, 0, :].any(-1) | f[:, :, -1, :].any(-1) | f[:, :, :, 0].any(-1) | f[:, :, :, -1].any(-1)
    if edge.any():
        errs.append(f"테두리에 닿은 프레임 {int(edge.sum())}개(잘림 의심)")
    return errs


def shift_up(a, k):
    """k행 위로 민다(아래는 빈칸)"""
    if k == 0:
        return a
    out = np.zeros_like(a)
    out[:-k] = a[k:]
    return out


def grow(m):
    """4방향 1px 팽창"""
    g = m.copy()
    g[1:] |= m[:-1]; g[:-1] |= m[1:]; g[:, 1:] |= m[:, :-1]; g[:, :-1] |= m[:, 1:]
    return g


def h3(img, part, bobs):
    """방향 한 줄(프레임들)의 윤곽 흔들림. 첫 프레임을 오르내림만큼 옮겨 비교한다.
    → (윗몸에서 바뀐 픽셀 수, 다리가 없는 행에서 바뀐 픽셀 수)"""
    body = out = 0
    for k in range(1, len(img)):
        s = bobs[k] - bobs[0]
        a, pa = shift_up(img[0], s), shift_up(part[0], s)
        b, pb = img[k], part[k]
        diff = (a != b).any(-1)
        limb = grow(np.isin(pa, LIMB) | np.isin(pb, LIMB))  # 다리의 바깥 외곽선(부위 0)도 다리로 본다
        body += int((diff & (np.isin(pa, BODY) | np.isin(pb, BODY)) & ~limb).sum())
        rows = limb.any(1)
        out += int((diff & ~rows[:, None]).sum())
    return body, out


def h4(part):
    """두 접지 프레임(0·2): 머리 맨 위 행이 같고 다리 배치가 다른가"""
    top = [int(np.nonzero((p == HEAD).any(1))[0].min()) for p in (part[0], part[2])]
    leg = 1 + PARTS.index("leg")
    return top[0] == top[1], not np.array_equal(part[0] == leg, part[2] == leg)


if __name__ == "__main__":
    name = sys.argv[1]
    pal = R.PALETTES[name.split("_")[-1]]
    for n in (16, 24, 32):
        path = OUT / f"{name}_{n}.png"
        print(f"[{n}] H5:", h5(path, pal, 2 * n if name.startswith(("attack", "fall")) else n) or "통과")
        if name.startswith("walk"):
            img, part = frames(path, n), frames(OUT / "parts" / path.name, n)
            bobs = [p["bob"] for p in WALK]
            rows = [(d, h3(img[r], part[r], bobs), h4(part[r])) for r, d in enumerate(R.DIRS)]
            print("  H3 (윗몸 변화, 다리 행 밖 변화):", " ".join(f"{d}{b}" for d, b, _ in rows))
            print("  H4 (머리 높이 같음, 다리 다름):", " ".join(f"{d}{'OK' if all(c) else c}" for d, _, c in rows))
