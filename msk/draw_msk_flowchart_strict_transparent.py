from __future__ import annotations

from math import cos, exp, pi, sin, sqrt
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parent
OUT = ROOT / "msk_flowchart_strict_transparent.png"
PREVIEW = ROOT / "msk_flowchart_strict_transparent_checker_preview.png"

W, H = 3840, 2160
BG = (0, 0, 0, 0)

FONT_CANDIDATES = [
    r"C:\Windows\Fonts\msyhbd.ttc",
    r"C:\Windows\Fonts\msyh.ttc",
    r"C:\Windows\Fonts\simhei.ttf",
]


def font(size):
    for path in FONT_CANDIDATES:
        if Path(path).exists():
            return ImageFont.truetype(path, size=size)
    return ImageFont.load_default()


F_TITLE = font(104)
F_GROUP = font(45)
F_CARD = font(34)
F_BODY = font(25)
F_SMALL = font(20)

INK = (12, 20, 34, 255)
BLUE = (25, 91, 174, 255)
ORANGE = (229, 117, 31, 255)
GREEN = (43, 128, 58, 255)
BLACK = (0, 0, 0, 255)


img = Image.new("RGBA", (W, H), BG)
draw = ImageDraw.Draw(img, "RGBA")


def size(text, fnt):
    box = draw.textbbox((0, 0), text, font=fnt)
    return box[2] - box[0], box[3] - box[1]


def ctext(box, text, fnt, fill=INK, spacing=8):
    x, y, w, h = box
    lines = text.split("\n")
    hs = [size(line, fnt)[1] for line in lines]
    total = sum(hs) + spacing * (len(lines) - 1)
    yy = y + (h - total) / 2
    for line, lh in zip(lines, hs):
        tw, _ = size(line, fnt)
        draw.text((x + (w - tw) / 2, yy), line, font=fnt, fill=fill)
        yy += lh + spacing


def rounded(box, radius, outline, width=5):
    draw.rounded_rectangle(box, radius=radius, fill=(0, 0, 0, 0), outline=outline, width=width)


def arrow(p1, p2, color=BLACK, width=6, head=22, dashed=False):
    x1, y1 = p1
    x2, y2 = p2
    dx, dy = x2 - x1, y2 - y1
    length = max(sqrt(dx * dx + dy * dy), 1)
    ux, uy = dx / length, dy / length
    if dashed:
        pos = 0
        while pos < length - head:
            a = pos
            b = min(pos + 28, length - head)
            draw.line((x1 + ux * a, y1 + uy * a, x1 + ux * b, y1 + uy * b), fill=color, width=width)
            pos += 48
    else:
        draw.line((x1, y1, x2, y2), fill=color, width=width)
    ang = __import__("math").atan2(dy, dx)
    left = (x2 - head * cos(ang - pi / 7), y2 - head * sin(ang - pi / 7))
    right = (x2 - head * cos(ang + pi / 7), y2 - head * sin(ang + pi / 7))
    draw.polygon([(x2, y2), left, right], fill=color)


def axes_icon(box):
    x, y, w, h = box
    arrow((x + w * 0.08, y + h * 0.82), (x + w * 0.94, y + h * 0.82), INK, 3, 11)
    arrow((x + w * 0.12, y + h * 0.95), (x + w * 0.12, y + h * 0.10), INK, 3, 11)


def icon_binary(box, color):
    x, y, w, h = box
    axes_icon(box)
    base, high = y + h * 0.82, y + h * 0.48
    pts = [
        (x + w * 0.20, base), (x + w * 0.32, base), (x + w * 0.32, high),
        (x + w * 0.45, high), (x + w * 0.45, base), (x + w * 0.58, base),
        (x + w * 0.58, high), (x + w * 0.72, high), (x + w * 0.72, base),
    ]
    draw.line(pts, fill=color, width=5)


def icon_stem(box, color):
    x, y, w, h = box
    axes_icon(box)
    mid = y + h * 0.65
    for i, v in enumerate([1, -1, 1, 1, -1, 1]):
        px = x + w * (0.24 + i * 0.12)
        py = mid - v * h * 0.28
        draw.line((px, mid, px, py), fill=color, width=4)
        draw.ellipse((px - 8, py - 8, px + 8, py + 8), fill=color)


def icon_iq(box, color):
    x, y, w, h = box
    cy = y + h / 2
    draw.ellipse((x + 14, cy - 14, x + 42, cy + 14), outline=INK, width=4)
    arrow((x, cy), (x + 14, cy), INK, 4, 10)
    arrow((x + 42, cy), (x + w * 0.48, y + h * 0.30), INK, 4, 10)
    arrow((x + 42, cy), (x + w * 0.48, y + h * 0.70), INK, 4, 10)
    for yy, label in [(y + h * 0.30, "I"), (y + h * 0.70, "Q")]:
        draw.text((x + w * 0.53, yy - 34), label, font=F_SMALL, fill=color)
        draw.line((x + w * 0.62, yy, x + w * 0.93, yy), fill=color, width=4)
        for i in range(3):
            px = x + w * (0.65 + i * 0.11)
            draw.ellipse((px - 8, yy - 8, px + 8, yy + 8), fill=color)


def icon_half_sine(box, color):
    x, y, w, h = box
    axes_icon(box)
    pts = []
    for i in range(130):
        t = i / 129
        pts.append((x + w * (0.15 + 0.75 * t), y + h * (0.82 - 0.46 * sin(pi * t))))
    draw.line(pts, fill=color, width=5)


def icon_carrier(box, color):
    x, y, w, h = box
    for row, yy in enumerate([0.38, 0.66]):
        pts = []
        for i in range(150):
            t = i / 149
            pts.append((x + w * (0.18 + 0.72 * t), y + h * yy + h * 0.11 * sin(2 * pi * 6 * t)))
        if row == 0:
            draw.line(pts, fill=color, width=4)
        else:
            for a, b in zip(pts[::9], pts[4::9]):
                draw.line((a[0], a[1], b[0], b[1]), fill=color, width=4)
        draw.text((x + w * 0.04, y + h * yy - 22), "I" if row == 0 else "Q", font=F_SMALL, fill=color)


def icon_awgn(box, color):
    x, y, w, h = box
    cx, cy = x + w * 0.50, y + h * 0.35
    draw.ellipse((cx - 38, cy - 38, cx + 38, cy + 38), outline=INK, width=4)
    draw.line((cx - 24, cy, cx + 24, cy), fill=INK, width=4)
    draw.line((cx, cy - 24, cx, cy + 24), fill=INK, width=4)
    base = y + h * 0.83
    pts = []
    for i in range(110):
        t = (i - 55) / 22
        pts.append((x + w * (0.18 + 0.64 * i / 109), base - h * 0.23 * exp(-t * t / 2)))
    draw.line(pts, fill=color, width=4)


def icon_ber(box, color):
    x, y, w, h = box
    axes_icon(box)
    pts = []
    for i in range(11):
        t = i / 10
        pts.append((x + w * (0.18 + 0.70 * t), y + h * (0.26 + 0.58 * t**2.1)))
    draw.line(pts, fill=color, width=4)
    for px, py in pts:
        draw.ellipse((px - 6, py - 6, px + 6, py + 6), outline=color, width=3, fill=(0, 0, 0, 0))


def icon_phase(box, color):
    x, y, w, h = box
    cx, cy = x + w / 2, y + h / 2
    r = min(w, h) * 0.33
    draw.ellipse((cx - r, cy - r, cx + r, cy + r), outline=color, width=5)
    arrow((cx - r * 1.35, cy), (cx + r * 1.48, cy), INK, 3, 10)
    arrow((cx, cy + r * 1.30), (cx, cy - r * 1.48), INK, 3, 10)
    for ang in [0, pi / 2, pi, 3 * pi / 2]:
        px, py = cx + r * cos(ang), cy - r * sin(ang)
        draw.ellipse((px - 10, py - 10, px + 10, py + 10), fill=color)


def icon_psd(box, color):
    x, y, w, h = box
    axes_icon(box)
    base = y + h * 0.82
    pts = []
    for i in range(180):
        t = 4 * i / 179 - 2
        v = (sin(pi * t) / (pi * t) if abs(t) > 1e-3 else 1) ** 2
        pts.append((x + w * (0.12 + 0.78 * i / 179), base - h * (0.43 * v + 0.08 * sin(4 * pi * t) ** 2)))
    draw.line(pts, fill=color, width=4)


def icon_constellation(box, color):
    x, y, w, h = box
    cx, cy = x + w / 2, y + h / 2
    r = min(w, h) * 0.34
    draw.ellipse((cx - r, cy - r, cx + r, cy + r), outline=color, width=5)
    for ang in [0, pi / 2, pi, 3 * pi / 2]:
        px, py = cx + r * cos(ang), cy - r * sin(ang)
        draw.ellipse((px - 11, py - 11, px + 11, py + 11), fill=color)
    arrow((cx - r * 1.35, cy), (cx + r * 1.45, cy), INK, 3, 10)
    arrow((cx, cy + r * 1.30), (cx, cy - r * 1.45), INK, 3, 10)


def icon_corr(box, color):
    x, y, w, h = box
    for yy, label in [(0.34, "I"), (0.68, "Q")]:
        cy = y + h * yy
        draw.text((x + 4, cy - 26), label, font=F_SMALL, fill=color)
        arrow((x + 42, cy), (x + 92, cy), INK, 3, 10)
        draw.ellipse((x + 92, cy - 23, x + 138, cy + 23), outline=INK, width=3)
        draw.line((x + 104, cy - 13, x + 126, cy + 13), fill=INK, width=2)
        draw.line((x + 126, cy - 13, x + 104, cy + 13), fill=INK, width=2)
        arrow((x + 138, cy), (x + 178, cy), INK, 3, 10)
        draw.rounded_rectangle((x + 178, cy - 26, x + w - 8, cy + 26), radius=7, fill=(0, 0, 0, 0), outline=INK, width=3)
        ctext((x + 178, cy - 26, w - 186, 52), "∫dt", F_SMALL)


def group(x, y, w, h, color, title):
    rounded((x, y, x + w, y + h), 26, color, 5)
    ctext((x + 20, y + 22, w - 40, 72), title, F_GROUP, color)
    draw.line((x + 20, y + 112, x + w - 20, y + 112), fill=color, width=5)


def card(x, y, w, h, color, title, body, icon):
    rounded((x, y, x + w, y + h), 18, color, 4)
    ctext((x + 14, y + 22, w - 28, 68), title, F_CARD)
    ctext((x + 16, y + 104, w - 32, 88), body, F_BODY, INK, 5)
    icon((x + 28, y + 220, w - 56, h - 260), color)


def bottom_card(x, y, w, h, color, title, body, icon):
    rounded((x, y, x + w, y + h), 18, color, 4)
    ctext((x + 18, y + 24, w - 36, 78), title, F_CARD)
    ctext((x + 20, y + 110, w - 40, 44), body, F_BODY)
    icon((x + 40, y + 165, w - 80, h - 205), color)


title = "MSK通信系统总流程图"
tw, _ = size(title, F_TITLE)
draw.text(((W - tw) / 2, 44), title, font=F_TITLE, fill=INK)

group(56, 205, 2030, 820, BLUE, "发送端  MSK调制器")
group(2130, 205, 505, 820, ORANGE, "信道与特性分析")
group(2678, 205, 1105, 820, GREEN, "接收端与性能评估")

card_y, card_w, card_h, gap = 355, 300, 535, 32
tx_xs = [88 + i * (card_w + gap) for i in range(6)]
tx_cards = [
    ("随机二进制\n序列", "b_k ∈ {0,1}", icon_binary),
    ("双极性映射", "a_k = 2b_k - 1", icon_stem),
    ("差分预编码", "保证相位连续", icon_stem),
    ("I/Q奇偶分路", "I路 / Q路\n交错更新", icon_iq),
    ("半正弦脉冲\n成形", "p(t)=sin(πt/2T)", icon_half_sine),
    ("正交载波\n调制", "Icos(2πfct)\n-Qsin(2πfct)", icon_carrier),
]
for x, item in zip(tx_xs, tx_cards):
    card(x, card_y, card_w, card_h, BLUE, *item)

chan_x = 2248
card(chan_x, card_y, 300, card_h, ORANGE, "AWGN信道", "E_b/N_0 扫描\nr(t)=s(t)+n(t)", icon_awgn)

rx_xs = [2728, 3058, 3388]
rx_cards = [
    ("相干相关检测", "本地载波同步\n相关积分", icon_corr),
    ("判决恢复", "corr_1 与 corr_0\n比较判决", icon_phase),
    ("BER性能评估", "仿真BER\n理论对比", icon_ber),
]
for x, item in zip(rx_xs, rx_cards):
    card(x, card_y, 300, card_h, GREEN, *item)

cy = card_y + card_h / 2
for i in range(len(tx_xs) - 1):
    arrow((tx_xs[i] + card_w, cy), (tx_xs[i + 1] - 10, cy))
arrow((tx_xs[-1] + card_w, cy), (chan_x - 10, cy))
arrow((chan_x + 300, cy), (rx_xs[0] - 10, cy))
for i in range(len(rx_xs) - 1):
    arrow((rx_xs[i] + 300, cy), (rx_xs[i + 1] - 10, cy))

source_x = tx_xs[-1] + card_w / 2
junction_y = 1110
arrow((source_x, card_y + card_h + 5), (source_x, junction_y), dashed=True, width=5, head=18)

bottom_y, bottom_h = 1180, 435
bottoms = [
    (450, bottom_y, 430, bottom_h, "瞬时频率分析", "f_i(t)=f_c±Δf/2", icon_binary),
    (965, bottom_y, 430, bottom_h, "相位轨迹\nPhase Trellis", "连续相位映射", icon_phase),
    (1480, bottom_y, 560, bottom_h, "功率谱密度 PSD\n与2FSK对比", "旁瓣与带外辐射", icon_psd),
    (2125, bottom_y, 470, bottom_h, "星座图/恒包络轨迹", "I-Q 平面单位圆", icon_constellation),
]
left = bottoms[0][0] + bottoms[0][2] / 2
right = bottoms[-1][0] + bottoms[-1][2] / 2
draw.line((left, junction_y, right, junction_y), fill=BLACK, width=5)
for bx, by, bw, bh, *_ in bottoms:
    arrow((bx + bw / 2, junction_y), (bx + bw / 2, by - 12), dashed=True, width=5, head=18)
for bx, by, bw, bh, title, body, icon in bottoms:
    bottom_card(bx, by, bw, bh, ORANGE, title, body, icon)

ber_x = rx_xs[-1] + 150
arrow((ber_x, card_y + card_h + 5), (ber_x, bottom_y - 12), dashed=True, width=5, head=18)
bottom_card(3045, bottom_y, 610, bottom_h, GREEN, "理论BER对比", "Q(√(E_b/N_0))", icon_ber)

note = "注：R_b为比特率，T_b=1/R_b；MSK调制指数 h=0.5，最小频移 Δf=1/(2T_b)。"
draw.text((90, 1695), note, font=F_BODY, fill=INK)

img.save(OUT)

# checkerboard preview only, not for PPT
tile = 48
preview = Image.new("RGBA", img.size, (255, 255, 255, 255))
pd = ImageDraw.Draw(preview)
for yy in range(0, H, tile):
    for xx in range(0, W, tile):
        col = (230, 230, 230, 255) if ((xx // tile + yy // tile) % 2 == 0) else (170, 170, 170, 255)
        pd.rectangle((xx, yy, xx + tile, yy + tile), fill=col)
preview.alpha_composite(img)
preview.save(PREVIEW)

alpha = img.getchannel("A")
vals = list(alpha.getdata())
print(f"saved={OUT}")
print(f"preview={PREVIEW}")
print(f"mode={img.mode} size={img.size} alpha_min={min(vals)} alpha_max={max(vals)} transparent_pixels={sum(1 for v in vals if v == 0)}")
