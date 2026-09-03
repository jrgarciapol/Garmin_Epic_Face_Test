#!/usr/bin/env python3
"""Vista previa de la esfera Órbita: la Barriecito con un orbe que recorre el
borde del dial cambiando de color. Muestra 4 momentos del recorrido."""
import math, os, colorsys
from PIL import Image, ImageDraw, ImageFont

_HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(os.path.dirname(_HERE), "fonts-src")
OUT = os.path.join(_HERE, "preview.png")

S = 454
GREEN = (0, 255, 0); BLUE = (30, 155, 255); WHITE = (255, 255, 255)
Y_WDAY, Y_TIME, Y_DATE = 0.200, 0.500, 0.815
R_ORB = 211

f_time = ImageFont.truetype(os.path.join(SRC, "Barriecito-Regular.ttf"), 196)
f_num = ImageFont.truetype(os.path.join(SRC, "Barriecito-Regular.ttf"), 108)
f_mon = ImageFont.truetype(os.path.join(SRC, "Barriecito-Regular.ttf"), 92)
f_lab = ImageFont.truetype(os.path.join(SRC, "RobotoMono-Bold.ttf"), 22)


def hue_rgb(sec, v=1.0):
    r, g, b = colorsys.hsv_to_rgb((sec % 60) / 60.0, 1.0, v)
    return (int(r * 255), int(g * 255), int(b * 255))


def cell_for(f):
    advs = [f.getlength(str(i)) for i in range(10)]
    ws = []
    for i in range(10):
        bb = f.getbbox(str(i)); ws.append((bb[2] - bb[0]) if bb else 0)
    return max(max(advs), max(ws)) + 4


def tab_time(d, cx, cy, txt, color, font):
    cell = cell_for(font); slot = font.getlength(":") * 0.5
    digits = [c for c in txt if c != ":"]
    x = cx - (len(digits) * cell + slot) / 2
    for ch in txt:
        if ch == ":":
            d.text((x + slot / 2, cy), ":", font=font, fill=color, anchor="mm"); x += slot
        else:
            d.text((x + cell / 2, cy), ch, font=font, fill=color, anchor="mm"); x += cell


def orb_pos(sec):
    a = math.radians(sec * 6 - 90)
    return S // 2 + R_ORB * math.cos(a), S // 2 + R_ORB * math.sin(a)


def draw_orb(d, sec):
    for k in range(5, 0, -1):
        x, y = orb_pos(sec - k)
        f = 1.0 - k / 6.0
        r = 3 + 3 * f
        d.ellipse([x - r, y - r, x + r, y + r], fill=hue_rgb(sec - k, 0.30 + 0.55 * f))
    x, y = orb_pos(sec)
    for r, v in ((13, 0.28), (9, 0.62), (6, 1.0)):
        d.ellipse([x - r, y - r, x + r, y + r], fill=hue_rgb(sec, v))


def face(sec):
    img = Image.new("RGBA", (S, S), (0, 0, 0, 255))
    d = ImageDraw.Draw(img)
    cx = S // 2
    draw_orb(d, sec)                       # por debajo del texto
    d.text((cx, int(S * Y_WDAY)), "LUN", font=f_mon, fill=GREEN, anchor="mm")
    tab_time(d, cx, int(S * Y_TIME), "9:24", WHITE, f_time)
    numW = f_num.getlength("9"); gap = 14
    x0 = cx - (numW + gap + f_mon.getlength("AGO")) / 2
    d.text((x0, int(S * Y_DATE)), "9", font=f_num, fill=GREEN, anchor="lm")
    d.text((x0 + numW + gap, int(S * Y_DATE)), "AGO", font=f_mon, fill=BLUE, anchor="lm")
    mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(mask).ellipse([0, 0, S - 1, S - 1], fill=255)
    img.putalpha(mask); return img


def bezel(inner):
    pad = 26; W = S + pad * 2
    c = Image.new("RGBA", (W, W), (0, 0, 0, 0)); d = ImageDraw.Draw(c)
    d.ellipse([0, 0, W - 1, W - 1], fill=(58, 60, 66, 255))
    d.ellipse([pad - 4, pad - 4, pad + S + 3, pad + S + 3], fill=(20, 21, 24, 255))
    c.alpha_composite(inner, (pad, pad)); return c


secs = [0, 15, 30, 45]
tiles = [(bezel(face(s)), "segundo %d" % s) for s in secs]
scale = 0.55
t = int(tiles[0][0].width * scale)
gap, margin, lab = 26, 34, 40
out = Image.new("RGB", (margin * 2 + 4 * t + 3 * gap, margin * 2 + t + lab), (18, 18, 22))
d = ImageDraw.Draw(out)
for i, (w, lb) in enumerate(tiles):
    x = margin + i * (t + gap)
    ws = w.resize((t, t))
    out.paste(ws, (x, margin), ws)
    d.text((x + t // 2, margin + t + 6), lb, font=f_lab, fill=WHITE, anchor="ma")
out.save(OUT)
print("preview escrito:", OUT, out.size)
