# 검수용 미리보기: 확대(최근접), 검정 실루엣, 들판 배경 위 실배율. Claude에게는 200px 미만 원본을 보여 주지 않는다(08 §3 운영 규칙)
from PIL import Image, ImageDraw

FIELD = (74, 107, 58, 255)  # 4.1b 전 battle_view.gd의 들판 단색(지금 게임 바닥은 타일)


def up(img, k):
    return img.resize((img.width * k, img.height * k), Image.NEAREST)


def silhouette(img):
    a = img.getchannel("A")
    s = Image.new("RGBA", img.size, (255, 255, 255, 255))
    s.paste((0, 0, 0, 255), mask=a)
    return s


def on(img, bg=FIELD, pad=0):
    s = Image.new("RGBA", (img.width + 2 * pad, img.height + 2 * pad), bg)
    s.alpha_composite(img, (pad, pad))
    return s


def label_rows(img, labels, row_h, width=150, bg=(30, 30, 30, 255)):
    """왼쪽에 행 이름을 붙인다"""
    s = Image.new("RGBA", (img.width + width, img.height), bg)
    s.alpha_composite(img, (width, 0))
    d = ImageDraw.Draw(s)
    for k, t in enumerate(labels):
        d.text((4, k * row_h + row_h // 2 - 5), t, fill=(230, 230, 230, 255))
    return s


def stack(imgs, gap=4, bg=(30, 30, 30, 255)):
    w = max(i.width for i in imgs)
    s = Image.new("RGBA", (w, sum(i.height for i in imgs) + gap * (len(imgs) - 1)), bg)
    y = 0
    for i in imgs:
        s.alpha_composite(i, (0, y))
        y += i.height + gap
    return s
