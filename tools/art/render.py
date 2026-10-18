# B 방식 렌더러(art_source_research/08 §3 단계 1): SDF 형체를 고정 정사영 카메라로 목표 크기에 직접 렌더한다.
# 재질마다 팔레트 램프로 음영 4단계를 칠하고 깊이 엣지 외곽선을 얹는다. 안티에일리어싱은 하지 않는다(art_direction_research 결론 1).
import json
from pathlib import Path

import numpy as np
from PIL import Image

PALETTES = {k: np.array([[int(h[i:i + 2], 16) for i in (0, 2, 4)] for h in v])
            for k, v in json.loads((Path(__file__).parent / "palettes.json").read_text(encoding="utf-8")).items()
            if not k.startswith("_")}
LIGHT = np.array([-0.45, -0.55, 0.70]) / np.linalg.norm([-0.45, -0.55, 0.70])  # 위·카메라 쪽 왼편(08 §2)


def oklab(rgb):
    c = np.asarray(rgb, float) / 255
    c = np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)
    lms = np.cbrt(c @ np.array([[0.4122214708, 0.5363325363, 0.0514459929],
                                [0.2119034982, 0.6806995451, 0.1073969566],
                                [0.0883024619, 0.2817188376, 0.6299787005]]).T)
    return lms @ np.array([[0.2104542553, 0.7936177850, -0.0040720468],
                           [1.9779984951, -2.4285922050, 0.4505937099],
                           [0.0259040371, 0.7827717662, -0.8086757660]]).T


def ramp(base, pal):
    """재질 기본색 → 팔레트 색 5개 [외곽선, 음영0..3]. 그림자 쪽은 파랑으로, 밝은 쪽은 노랑으로 조금 돈다"""
    P = oklab(pal)
    L, a, b = oklab([base])[0]
    out = []
    for f, db in ((0.38, -0.03), (0.6, -0.02), (0.8, -0.01), (1.0, 0.0), (1.18, 0.015)):
        t = np.array([L * f, a * min(f, 1.0), b * min(f, 1.0) + db])
        out.append(int(np.argmin((((P - t) * [1.5, 1, 1]) ** 2).sum(1))))
    return out


class Cam:
    """고도각 elev도 정사영. 화면 오른쪽 u, 위 v, 시선 d. 칸 하나가 화면에서 정사각이 되려면 바닥 깊이는 1/sin배다(02 §2)"""

    def __init__(self, elev):
        t = np.radians(elev)
        self.elev, self.sin, self.cos = elev, np.sin(t), np.cos(t)
        self.u, self.v, self.d = np.array([1.0, 0, 0]), np.array([0, self.sin, self.cos]), np.array([0, self.cos, -self.sin])

    def facing(self, gx, gy):
        """격자 방향(gx 오른쪽, gy 화면 위쪽) → 월드 바닥 위 앞 방향 단위 벡터"""
        f = np.array([gx, gy / self.sin])
        return f / np.linalg.norm(f)


DIRS = {"S": (0, -1), "SE": (1, -1), "E": (1, 0), "NE": (1, 1), "N": (0, 1), "NW": (-1, 1), "W": (-1, 0), "SW": (-1, -1)}


def scene(prims):
    def sdf(p):
        d = np.stack([q[0](p) for q in prims])
        i = d.argmin(0)
        return d[i, np.arange(p.shape[0])], i
    return sdf


def trace(prims, cam, face, n, ppu, anchor, with_pos=False):
    """n×n 픽셀마다 광선 하나. 결과: 부품 번호(-1 빈칸), 법선·빛 내적, 깊이 (+ with_pos면 맞은 점의 모델 좌표)"""
    sdf = scene(prims)
    j, i = np.mgrid[0:n, 0:n]
    sx, sy = (i.ravel() + 0.5 - anchor[0]) / ppu, (anchor[1] - (j.ravel() + 0.5)) / ppu
    o = sx[:, None] * cam.u + sy[:, None] * cam.v - 4.0 * cam.d
    r = np.array([face[1], -face[0], 0.0]); f = np.array([face[0], face[1], 0.0]); z = np.array([0, 0, 1.0])
    to_local = np.stack([r, f, z])  # 월드 → 모델(x 오른쪽, y 앞, z 위)
    o, d = o @ to_local.T, np.tile(cam.d @ to_local.T, (n * n, 1))
    t, alive, hit = np.zeros(n * n), np.ones(n * n, bool), np.zeros(n * n, bool)
    for _ in range(96):
        idx = np.nonzero(alive)[0]
        if not len(idx):
            break
        dist, _ = sdf(o[idx] + t[idx, None] * d[idx])
        h = dist < 1e-3
        hit[idx[h]] = True
        t[idx] += np.maximum(dist, 1e-4)
        alive[idx[h | (t[idx] > 8.0)]] = False
    mat, lam, pos = np.full(n * n, -1), np.zeros(n * n), np.zeros((n * n, 3))
    hi = np.nonzero(hit)[0]
    if len(hi):
        p = o[hi] + t[hi, None] * d[hi]
        _, mat[hi] = sdf(p)
        pos[hi] = p
        e = 1e-3
        g = np.stack([sdf(p + e * k)[0] - sdf(p - e * k)[0] for k in np.eye(3)], 1)
        g /= np.linalg.norm(g, axis=1, keepdims=True) + 1e-9
        lam[hi] = g @ (to_local @ LIGHT)
    out = mat.reshape(n, n), lam.reshape(n, n), np.where(hit, t, np.inf).reshape(n, n)
    return out + (pos.reshape(n, n, 3),) if with_pos else out


def shade(mat, lam, depth, ramps, outline, darkest, edge, levels=(0.05, 0.4, 0.75)):
    """팔레트 번호 이미지(-1 투명). outline: 'B' 색 외곽선 / 'D' 바깥은 최암색 + 안쪽은 색 외곽선(README 결론 2)"""
    R = np.array(ramps)
    op = mat >= 0
    m = np.where(op, mat, 0)
    out = np.where(op, R[m, 1 + np.digitize(lam, levels)], -1)
    pd = np.pad(depth, 1, constant_values=np.inf)
    pm = np.pad(m, 1)
    n = mat.shape[0]
    near = np.full(depth.shape, np.inf)
    near_m = np.zeros_like(m)
    for dy, dx in ((0, 1), (0, -1), (1, 0), (-1, 0)):
        nd = pd[1 + dy:1 + dy + n, 1 + dx:1 + dx + n]
        inner = op & (nd < depth - edge)
        out[inner] = R[m[inner], 0]
        closer = nd < near
        near = np.where(closer, nd, near)
        near_m = np.where(closer, pm[1 + dy:1 + dy + n, 1 + dx:1 + dx + n], near_m)
    rim = ~op & np.isfinite(near)
    out[rim] = darkest if outline == "D" else R[near_m[rim], 0]
    return out


def darkest(pal):
    return int(np.argmin(oklab(pal)[:, 0]))


def rgba(idx, pal):
    img = np.zeros(idx.shape + (4,), np.uint8)
    op = idx >= 0
    img[op, :3] = pal[idx[op]]
    img[op, 3] = 255
    return Image.fromarray(img, "RGBA")


def sheet(frames, cols, gap=0, bg=(0, 0, 0, 0)):
    w, h = frames[0].size
    rows = -(-len(frames) // cols)
    s = Image.new("RGBA", (cols * w + (cols - 1) * gap, rows * h + (rows - 1) * gap), bg)
    for k, f in enumerate(frames):
        s.alpha_composite(f, ((k % cols) * (w + gap), (k // cols) * (h + gap)))
    return s


# SDF 부품. p는 모델 좌표 (M,3)
def ellipsoid(c, r):
    c, r = np.asarray(c, float), np.asarray(r, float)

    def f(p):
        q = p - c
        k0 = np.linalg.norm(q / r, axis=1)
        k1 = np.linalg.norm(q / (r * r), axis=1)
        return k0 * (k0 - 1) / (k1 + 1e-9)
    return f


def capsule(a, b, ra, rb=None):
    a, b = np.asarray(a, float), np.asarray(b, float)
    rb = ra if rb is None else rb
    ba = b - a

    def f(p):
        pa = p - a
        h = np.clip(pa @ ba / (ba @ ba), 0, 1)
        return np.linalg.norm(pa - h[:, None] * ba, axis=1) - (ra + (rb - ra) * h)
    return f


def box(c, half, axes=np.eye(3), rnd=0.0):
    """axes 행 = 상자 자기 x·y·z 축(모델 좌표)"""
    c, half, axes = np.asarray(c, float), np.asarray(half, float) - rnd, np.asarray(axes, float)

    def f(p):
        q = np.abs((p - c) @ axes.T) - half
        return np.linalg.norm(np.maximum(q, 0), axis=1) + np.minimum(q.max(1), 0) - rnd
    return f


def cut_above(fn, z0):
    """fn ∩ {z > z0}"""
    return lambda p: np.maximum(fn(p), z0 - p[:, 2])
