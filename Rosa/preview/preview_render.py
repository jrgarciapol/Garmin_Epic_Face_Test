#!/usr/bin/env python3
"""Vista previa de la esfera Rosa de los vientos (interactiva + Always-On)."""
import math, os
from PIL import Image, ImageDraw, ImageFont

VIVID = False
_HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(os.path.dirname(_HERE), "fonts-src")
OUT = os.path.join(_HERE, "preview.png")

S = 454
WHITE = (245, 245, 242); GREEN = (63, 217, 140); BLUE = (76, 155, 240)
TICK = (44, 46, 51); TICK5 = (90, 93, 102); TRACK = (26, 28, 32)
VGREEN = (0, 255, 0); VRED = (255, 0, 0); VBLUE = (30, 155, 255)

f_time = ImageFont.truetype(os.path.join(SRC, "Barriecito-Regular.ttf"), 170)
f_aod = ImageFont.truetype(os.path.join(SRC, "Barriecito-Regular.ttf"), 120)
f_date = ImageFont.truetype(os.path.join(SRC, "RobotoMono-Bold.ttf"), 30)
f_card = ImageFont.truetype(os.path.join(SRC, "RobotoMono-Bold.ttf"), 42)

HH, MM, LINE, MINUTE = "9", "24", "LUN 9 AGO", 24


def cell_for(f):
    advs = [f.getlength(str(i)) for i in range(10)]
    ws = []
    for i in range(10):
        bb = f.getbbox(str(i)); ws.append((bb[2] - bb[0]) if bb else 0)
    return max(max(advs), max(ws)) + 4


def tab_time(d, cx, cy, txt, color, font, stroke=0):
    cell = cell_for(font); slot = font.getlength(":") * 0.5
    digits = [c for c in txt if c != ":"]
    total = len(digits) * cell + slot
    x = cx - total / 2
    for ch in txt:
        if ch == ":":
            d.text((x + slot / 2, cy), ":", font=font, fill=color, anchor="mm",
                   stroke_width=stroke, stroke_fill=(0, 0, 0))
            x += slot
        else:
            d.text((x + cell / 2, cy), ch, font=font, fill=color, anchor="mm",
                   stroke_width=stroke, stroke_fill=(0, 0, 0))
            x += cell


def minute_ticks(d, cx, cy, r_out):
    for i in range(60):
        major = i % 5 == 0
        ln, col, pw = (15, TICK5, 3) if major else (9, TICK, 2)
        a = math.radians(i * 6 - 90)
        d.line([cx + (r_out - ln) * math.cos(a), cy + (r_out - ln) * math.sin(a),
                cx + r_out * math.cos(a), cy + r_out * math.sin(a)], fill=col, width=pw)


def arc(d, cx, cy, r, s, e, color, pw):
    d.arc([cx - r, cy - r, cx + r, cy + r], s, e, fill=color, width=pw)


def wind_rose(d, cx, cy, r, rot, vivid):
    r_in = r * 0.085
    for i in range(8):
        cardinal = i % 2 == 0
        ln = r * (0.90 if cardinal else 0.72)
        a = rot + math.radians(i * 45)
        aL, aR = a - math.radians(4.6), a + math.radians(4.6)
        col = (19, 42, 32) if cardinal else (15, 32, 40)
        if i == 0 and not vivid:
            col = GREEN
        if vivid:
            col = VGREEN if cardinal else VRED
        d.polygon([(cx + ln * math.sin(a), cy - ln * math.cos(a)),
                   (cx + r_in * math.sin(aR), cy - r_in * math.cos(aR)),
                   (cx - r_in * math.sin(a), cy + r_in * math.cos(a)),
                   (cx + r_in * math.sin(aL), cy - r_in * math.cos(aL))], fill=col)
    ring = (0, 91, 0) if vivid else (27, 58, 44)
    arc(d, cx, cy, r * 0.66, 0, 360, ring, 2)
    arc(d, cx, cy, r * 0.32, 0, 360, ring, 2)
    for k, ch in enumerate("NESO"):
        ak = rot + math.radians(k * 90)
        p = (cx + (r - 24) * math.sin(ak), cy - (r - 24) * math.cos(ak))
        d.text(p, ch, font=f_card, fill=VBLUE if vivid else BLUE, anchor="mm",
               stroke_width=3 if vivid else 0, stroke_fill=(0, 0, 0))


def face_interactive():
    img = Image.new("RGB", (S, S), (0, 0, 0)); d = ImageDraw.Draw(img)
    cx = cy = S // 2
    wind_rose(d, cx, cy, S // 2 - 24, math.radians(-24), VIVID)
    minute_ticks(d, cx, cy, S // 2 - 14)
    arc(d, cx, cy, S // 2 - 6, 0, 360, TRACK, 5)
    arc(d, cx, cy, S // 2 - 6, -90, -90 + 360 * MINUTE / 60, VGREEN if VIVID else GREEN, 5)
    tab_time(d, cx, cy - 16, HH + ":" + MM, WHITE, f_time, 4 if VIVID else 0)
    d.text((cx, cy + 112), LINE, font=f_date, fill=WHITE, anchor="mm",
           stroke_width=3 if VIVID else 0, stroke_fill=(0, 0, 0))
    return img


def face_aod(slot=0):
    img = Image.new("RGB", (S, S), (0, 0, 0)); d = ImageDraw.Draw(img)
    cx = cy = S // 2; off = 78
    x, y = cx, cy
    if slot == 0: y = cy - off
    elif slot == 1: x = cx + off
    elif slot == 2: y = cy + off
    elif slot == 3: x = cx - off
    tab_time(d, x, y, HH + ":" + MM, VGREEN if VIVID else GREEN, f_aod)
    return img


def bezel(img):
    pad = 30; W = S + pad * 2
    mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(mask).ellipse([0, 0, S - 1, S - 1], fill=255)
    inner = img.copy(); inner.putalpha(mask)
    c = Image.new("RGBA", (W, W), (0, 0, 0, 0)); d = ImageDraw.Draw(c)
    d.ellipse([0, 0, W - 1, W - 1], fill=(58, 60, 66, 255))
    d.ellipse([pad - 4, pad - 4, pad + S + 3, pad + S + 3], fill=(20, 21, 24, 255))
    c.alpha_composite(inner, (pad, pad)); return c


items = [(bezel(face_interactive()), "INTERACTIVO"),
         (bezel(face_aod(0)), "ALWAYS-ON (rota 5 pos.)")]
gap, margin, lab = 40, 40, 48
w0 = items[0][0].width
out = Image.new("RGB", (w0 * 2 + gap + margin * 2, w0 + margin + lab), (18, 18, 22))
d = ImageDraw.Draw(out)
lf = ImageFont.truetype(os.path.join(SRC, "RobotoMono-Bold.ttf"), 24)
for i, (w, t) in enumerate(items):
    x = margin + i * (w0 + gap)
    out.paste(w, (x, margin), w)
    d.text((x + w0 // 2, margin + w0 + 8), t, font=lf, fill=WHITE, anchor="ma")
out.save(OUT)
print("preview escrito:", OUT, out.size)
