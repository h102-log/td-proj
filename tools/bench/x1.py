# X1 아트 픽셀 정합(art_direction_research/05 §5): 줌 k 캡처에서 이웃 픽셀 색이 바뀌는 경계가 k 간격 격자 하나에 몇 %나 모이는지 센다.
# 100%면 아트 픽셀이 모두 k×k 덩어리이고 같은 격자(위상)에 있다. 줌 1은 늘 100%다.
# 사용: python tools/bench/x1.py <k> <캡처.png>...
import sys
from collections import Counter

from PIL import Image


def share(path, k):
    im = Image.open(path).convert("RGB")
    w, h = im.size
    px = im.load()
    cx, cy = Counter(), Counter()
    for y in range(h):
        for x in range(1, w):
            if px[x, y] != px[x - 1, y]:
                cx[x % k] += 1
    for x in range(w):
        for y in range(1, h):
            if px[x, y] != px[x, y - 1]:
                cy[y % k] += 1
    return max(cx.values()) / sum(cx.values()), max(cy.values()) / sum(cy.values())


if __name__ == "__main__":
    k = int(sys.argv[1])
    for p in sys.argv[2:]:
        sx, sy = share(p, k)
        print(f"{p}\tx {sx:.1%}\ty {sy:.1%}")
