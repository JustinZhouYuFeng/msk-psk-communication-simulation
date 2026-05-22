from PIL import Image, ImageDraw, ImageFont
import math
import os
import random


W, H = 2400, 1350
OUT_DIR = os.path.join(os.getcwd(), "MSK_Output_Figures")
OUT_FILE = os.path.join(OUT_DIR, "13_AWGN_SNR_receiver_transparent.png")
PREVIEW_FILE = os.path.join(OUT_DIR, "13_AWGN_SNR_receiver_transparent_preview.png")


NAVY = (16, 41, 83, 255)
BLUE = (0, 92, 190, 255)
TEAL = (0, 135, 128, 255)
ORANGE = (221, 96, 18, 255)
RED = (228, 28, 30, 255)
GRAY = (76, 87, 99, 255)
LIGHT_BLUE = (228, 241, 255, 238)
LIGHT_TEAL = (225, 248, 244, 238)
LIGHT_ORANGE = (255, 237, 220, 238)
PANEL = (255, 255, 255, 228)
CARD = (255, 255, 255, 238)


def font(size, bold=False):
    paths = [
        r"C:\Windows\Fonts\msyhbd.ttc" if bold else r"C:\Windows\Fonts\msyh.ttc",
        r"C:\Windows\Fonts\simhei.ttf",
        r"C:\Windows\Fonts\arial.ttf",
    ]
    for path in paths:
        if os.path.exists(path):
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


F_TITLE = font(66, True)
F_SEC = font(34, True)
F_BODY = font(28, True)
F_SMALL = font(23)
F_FORMULA = font(34, True)


def rr(draw, box, radius=24, fill=PANEL, outline=BLUE, width=3):
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def text_center(draw, box, text, fnt, fill=NAVY, spacing=5):
    x0, y0, x1, y1 = box
    b = draw.multiline_textbbox((0, 0), text, font=fnt, spacing=spacing, align="center")
    tw = b[2] - b[0]
    th = b[3] - b[1]
    draw.multiline_text(
        (x0 + (x1 - x0 - tw) / 2, y0 + (y1 - y0 - th) / 2 - 2),
        text,
        font=fnt,
        fill=fill,
        spacing=spacing,
        align="center",
    )


def arrow(draw, p0, p1, color=GRAY, width=5, head=18):
    x0, y0 = p0
    x1, y1 = p1
    draw.line((x0, y0, x1, y1), fill=color, width=width)
    angle = math.atan2(y1 - y0, x1 - x0)
    for a in (angle + 2.55, angle - 2.55):
        draw.line((x1, y1, x1 + head * math.cos(a), y1 + head * math.sin(a)), fill=color, width=width)


def header(draw, x, y, w, color, text):
    rr(draw, (x, y, x + w, y + 54), radius=10, fill=color, outline=color, width=1)
    text_center(draw, (x, y, x + w, y + 54), text, font(27, True), fill=(255, 255, 255, 255))


def block(draw, box, text, fill, outline, fnt=F_BODY):
    rr(draw, box, radius=18, fill=fill, outline=outline, width=3)
    text_center(draw, box, text, fnt)


def wave(draw, box, color, noise=0.0):
    x0, y0, x1, y1 = box
    pts = []
    for i in range(180):
        t = i / 179
        y = math.sin(2 * math.pi * 2.6 * t)
        y += noise * (0.55 * math.sin(2 * math.pi * 17 * t + 0.3) + 0.35 * math.sin(2 * math.pi * 41 * t))
        pts.append((x0 + t * (x1 - x0), (y0 + y1) / 2 - y * (y1 - y0) * 0.32))
    draw.line(pts, fill=color, width=4)


def formula_box(draw, box, lines, color=BLUE):
    rr(draw, box, radius=16, fill=CARD, outline=color, width=3)
    x = box[0] + 26
    y = box[1] + 22
    for line in lines:
        draw.text((x, y), line, font=F_FORMULA, fill=NAVY)
        y += 50


def note_box(draw, box, lines, color=TEAL):
    rr(draw, box, radius=14, fill=CARD, outline=color, width=3)
    x = box[0] + 18
    y = box[1] + 16
    for line in lines:
        draw.text((x, y), line, font=font(23, True), fill=NAVY)
        y += 38


def bullet_card(draw, box, title, body, color):
    rr(draw, box, radius=14, fill=(255, 255, 255, 234), outline=color, width=3)
    draw.text((box[0] + 18, box[1] + 14), title, font=font(23, True), fill=color)
    draw.multiline_text((box[0] + 18, box[1] + 52), body, font=font(20), fill=NAVY, spacing=5)


def mini_iq(draw, cx, cy, r, spread, label):
    draw.ellipse((cx - r, cy - r, cx + r, cy + r), outline=(80, 80, 80, 170), width=3)
    states = [(cx + r, cy), (cx, cy - r), (cx - r, cy), (cx, cy + r)]
    random.seed(int(spread * 1000) + cx)
    for sx, sy in states:
        for _ in range(28):
            a = random.random() * 2 * math.pi
            rr0 = abs(random.gauss(0, spread))
            px = sx + math.cos(a) * rr0
            py = sy + math.sin(a) * rr0
            draw.ellipse((px - 3, py - 3, px + 3, py + 3), fill=(ORANGE[0], ORANGE[1], ORANGE[2], 190))
        draw.ellipse((sx - 7, sy - 7, sx + 7, sy + 7), fill=RED)
    draw.text((cx - r, cy + r + 10), label, font=font(20, True), fill=NAVY)


def main_iq(draw, x, y, w, h):
    cx, cy = x + w * 0.57, y + h * 0.56
    r = min(w, h) * 0.30
    draw.line((cx - r - 50, cy, cx + r + 65, cy), fill=(40, 45, 50, 220), width=3)
    draw.line((cx, cy - r - 45, cx, cy + r + 55), fill=(40, 45, 50, 220), width=3)
    draw.text((cx + r + 68, cy - 10), "I", font=font(24, True), fill=NAVY)
    draw.text((cx - 8, cy - r - 75), "Q", font=font(24, True), fill=NAVY)
    draw.ellipse((cx - r, cy - r, cx + r, cy + r), outline=(35, 35, 35, 160), width=3)

    states = [
        (cx + r, cy, "(+1,0)"),
        (cx, cy - r, "(0,+1)"),
        (cx - r, cy, "(-1,0)"),
        (cx, cy + r, "(0,-1)"),
    ]
    random.seed(5)
    for sx, sy, label in states:
        for _ in range(45):
            a = random.random() * 2 * math.pi
            rr0 = abs(random.gauss(0, 24))
            px = sx + math.cos(a) * rr0
            py = sy + math.sin(a) * rr0
            draw.ellipse((px - 4, py - 4, px + 4, py + 4), fill=(ORANGE[0], ORANGE[1], ORANGE[2], 180))
        draw.ellipse((sx - 11, sy - 11, sx + 11, sy + 11), fill=RED)
        # Green decision samples are intentionally near the four MSK boundary states, not at QPSK corners.
        draw.ellipse((sx - 26, sy - 26, sx + 26, sy + 26), outline=(0, 150, 75, 255), width=4)
        tx = sx + (34 if sx >= cx else -92 if sx < cx else 14)
        ty = sy + (-38 if sy < cy else 18 if sy > cy else -36)
        draw.text((tx, ty), label, font=font(18), fill=NAVY)
    draw.ellipse((cx - 12, cy - 12, cx + 12, cy + 12), outline=(0, 150, 75, 255), width=4)


def receiver_flow(draw, x, y):
    block(draw, (x + 72, y + 12, x + 270, y + 88), "相关器\n与参考信号积分", (255, 247, 240, 236), ORANGE, font(22, True))
    arrow(draw, (x + 170, y - 30), (x + 170, y + 10), color=GRAY, width=4)
    draw.text((x + 145, y - 70), "r(t)", font=font(24, True), fill=NAVY)
    block(draw, (x + 38, y + 135, x + 118, y + 198), "C1", CARD, ORANGE, font(24, True))
    block(draw, (x + 222, y + 135, x + 302, y + 198), "C0", CARD, ORANGE, font(24, True))
    arrow(draw, (x + 112, y + 90), (x + 78, y + 132), color=GRAY, width=4)
    arrow(draw, (x + 228, y + 90), (x + 262, y + 132), color=GRAY, width=4)
    poly = [(x + 170, y + 246), (x + 264, y + 310), (x + 170, y + 374), (x + 76, y + 310)]
    draw.polygon(poly, fill=(255, 248, 242, 238), outline=ORANGE)
    draw.text((x + 108, y + 282), "比较\nC1 vs C0", font=font(22, True), fill=NAVY, spacing=4)
    arrow(draw, (x + 78, y + 200), (x + 132, y + 258), color=GRAY, width=4)
    arrow(draw, (x + 262, y + 200), (x + 208, y + 258), color=GRAY, width=4)
    arrow(draw, (x + 264, y + 310), (x + 340, y + 310), color=GRAY, width=4)
    draw.text((x + 350, y + 292), "判决", font=font(24, True), fill=NAVY)


def build():
    os.makedirs(OUT_DIR, exist_ok=True)
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    d.text((W / 2, 38), "AWGN 信道、信噪比与相干接收判决", font=F_TITLE, fill=NAVY, anchor="ma")

    # Section columns.
    left = (55, 145, 760, 980)
    mid = (820, 145, 1520, 980)
    right = (1580, 145, 2345, 980)
    for box in (left, mid, right):
        rr(d, box, radius=20, fill=(255, 255, 255, 205), outline=(255, 255, 255, 0), width=1)
    header(d, 165, 165, 430, BLUE, "1. AWGN 信道模型")
    header(d, 920, 165, 430, TEAL, "2. Eb/N0 控制噪声强度")
    header(d, 1705, 165, 430, ORANGE, "3. 相干相关接收")
    d.line((790, 155, 790, 940), fill=(0, 92, 190, 150), width=3)
    d.line((1550, 155, 1550, 940), fill=(80, 80, 80, 130), width=3)

    # Left: AWGN channel.
    d.text((85, 285), "2MSK 信号 s(t)", font=font(22, True), fill=NAVY)
    rr(d, (70, 330, 300, 445), radius=14, fill=CARD, outline=NAVY, width=3)
    wave(d, (95, 360, 275, 410), BLUE, 0)
    rr(d, (382, 320, 465, 403), radius=42, fill=(255, 255, 255, 238), outline=(20, 20, 20, 210), width=3)
    text_center(d, (382, 320, 465, 403), "+", font(48, True), fill=(20, 20, 20, 255))
    d.text((380, 240), "+ n(t)", font=font(22, True), fill=BLUE)
    rr(d, (550, 330, 745, 445), radius=14, fill=CARD, outline=NAVY, width=3)
    d.text((565, 285), "接收信号 r(t)", font=font(22, True), fill=NAVY)
    wave(d, (575, 360, 725, 410), BLUE, 0.9)
    arrow(d, (302, 385), (380, 385), color=(20, 20, 20, 220), width=4)
    arrow(d, (465, 385), (548, 385), color=(20, 20, 20, 220), width=4)
    rr(d, (310, 505, 545, 620), radius=14, fill=CARD, outline=NAVY, width=3)
    d.text((325, 520), "AWGN 噪声 n(t)", font=font(21, True), fill=NAVY)
    wave(d, (335, 565, 520, 595), BLUE, 1.0)
    arrow(d, (425, 503), (425, 405), color=(20, 20, 20, 220), width=4)
    formula_box(d, (150, 690, 690, 835), ["r(t) = s(t) + n(t)", "n(t) ~ N(0, sigma^2)"], BLUE)
    bullet_card(d, (70, 855, 220, 970), "加性", "噪声直接叠加\n到信号上", BLUE)
    bullet_card(d, (270, 855, 420, 970), "白噪声", "功率谱密度\n近似为常数", BLUE)
    bullet_card(d, (470, 855, 620, 970), "高斯分布", "噪声幅度服从\n正态分布", BLUE)

    # Middle: Eb/N0.
    d.text((880, 280), "高 Eb/N0", font=font(24, True), fill=TEAL)
    d.text((870, 840), "低 Eb/N0", font=font(24, True), fill=ORANGE)
    draw_arrow_x = 940
    d.polygon([(draw_arrow_x, 300), (draw_arrow_x - 22, 342), (draw_arrow_x + 22, 342)], fill=TEAL)
    d.rectangle((draw_arrow_x - 10, 340, draw_arrow_x + 10, 820), fill=(210, 180, 135, 210))
    d.polygon([(draw_arrow_x, 870), (draw_arrow_x - 22, 820), (draw_arrow_x + 22, 820)], fill=ORANGE)
    d.text((820, 455), "噪声小\n扰动小", font=font(22, True), fill=NAVY, spacing=7)
    d.text((820, 675), "噪声大\n扰动大", font=font(22, True), fill=NAVY, spacing=7)
    mini_iq(d, 1155, 340, 72, 9, "高信噪比")
    mini_iq(d, 1155, 540, 72, 22, "中等信噪比")
    mini_iq(d, 1155, 745, 72, 46, "低信噪比")
    note_box(d, (1300, 405, 1500, 515), ["Eb/N0 上升", "噪声方差下降"], TEAL)
    note_box(d, (1265, 675, 1505, 855), ["Eb：每比特能量", "N0：噪声谱密度", "Eb/N0 越大", "接收扰动越小"], TEAL)

    # Right: coherent receiver.
    receiver_flow(d, 1655, 310)
    formula_box(d, (2055, 255, 2340, 455), ["C1 = sum r * s1", "C0 = sum r * s0"], ORANGE)
    formula_box(d, (2055, 560, 2340, 725), ["判决规则：", "C1 > C0 -> 判 1", "C1 <= C0 -> 判 0"], ORANGE)
    note_box(d, (1585, 805, 1988, 965), ["构造两组参考信号", "分别与 r(t) 相关", "比较输出完成判决"], ORANGE)
    main_iq(d, 1940, 805, 390, 230)

    # Bottom conclusion.
    rr(d, (65, 1080, 1455, 1245), radius=20, fill=CARD, outline=NAVY, width=4)
    d.text((110, 1120), "Eb/N0 上升  =>  噪声扰动下降  =>  C1、C0 区分更明显  =>  BER 下降", font=font(38, True), fill=NAVY)

    # Legend for I/Q sketch.
    rr(d, (1580, 1080, 1975, 1268), radius=12, fill=CARD, outline=GRAY, width=2)
    d.line((1610, 1122, 1680, 1122), fill=(80, 80, 80, 170), width=3)
    d.text((1700, 1106), "理想轨迹（单位圆）", font=font(21), fill=NAVY)
    d.ellipse((1628, 1160, 1650, 1182), fill=RED)
    d.text((1700, 1155), "四个边界状态", font=font(21), fill=NAVY)
    d.ellipse((1628, 1205, 1650, 1227), outline=TEAL, width=4)
    d.text((1700, 1200), "判决采样点", font=font(21), fill=NAVY)
    d.ellipse((1628, 1245, 1640, 1257), fill=ORANGE)
    d.text((1700, 1238), "接收点云", font=font(21), fill=NAVY)

    img.save(OUT_FILE)
    preview = Image.new("RGBA", (W, H), (245, 247, 250, 255))
    preview.alpha_composite(img)
    preview.save(PREVIEW_FILE)
    print(OUT_FILE)
    print(PREVIEW_FILE)


if __name__ == "__main__":
    build()
