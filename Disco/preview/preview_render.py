#!/usr/bin/env python3
"""Vista previa de la esfera Disco. Replica lo que hace EpixWatchFaceView.mc:
solo poligonos, circulos y colores planos, que es lo unico que sabe dibujar
Monkey C. El suavizado se simula con supermuestreo x4, equivalente a
dc.setAntiAlias(true).

Uso:  python3 preview_render.py [HH] [MM]
"""
import math, os, sys
from PIL import Image, ImageDraw, ImageFont

_HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(os.path.dirname(_HERE), "fonts-src")
OUT = os.path.join(_HERE, "preview.png")

S, K = 454, 4                       # tamano real y factor de supermuestreo

# Mismos valores que el .mc
BG    = (0xF7, 0xC8, 0x1E)
TICK  = (0x70, 0x52, 0x00)
INK   = (0x18, 0x1A, 0x1A)
BEVEL = (0x34, 0x35, 0x36)
SHADE = (0xC9, 0xA1, 0x00)
PIVOT = (0x3A, 0x3B, 0x3C)
AOD   = (0xF7, 0xC8, 0x1E)
AOD_T = (0x4A, 0x3A, 0x00)

L_MIN, L_HOUR, TAIL = 215, 142, 34
W_MIN, W_HOUR = 11, 12
R_DISC, R_PIVOT = 27, 5
SHADE_X, SHADE_Y = 2, 3


def hand_points(cx, cy, deg, length, w_tail, dx=0, dy=0):
    a = math.radians(deg - 90)
    ux, uy = math.cos(a), math.sin(a)
    px, py = -uy, ux
    bx, by = cx - ux * TAIL * K, cy - uy * TAIL * K
    hw = w_tail * K / 2.0
    return [(cx + ux * length * K + dx, cy + uy * length * K + dy),
            (bx + px * hw + dx, by + py * hw + dy),
            (bx - px * hw + dx, by - py * hw + dy)]


def draw_hand(d, cx, cy, deg, length, w_tail):
    pts = hand_points(cx, cy, deg, length, w_tail)
    d.polygon(pts, fill=INK)
    a = math.radians(deg - 90)
    b = (cx - math.cos(a) * TAIL * K, cy - math.sin(a) * TAIL * K)
    d.polygon([pts[0], pts[1], b], fill=BEVEL)


def draw_ticks(d, cx, cy, color, w_quarter, w_other):
    r = S * K / 2
    r1, r2 = r * 0.90, r * 0.955
    for i in range(12):
        a = math.radians(i * 30 - 90)
        ca, sa = math.cos(a), math.sin(a)
        d.line([(cx + r1 * ca, cy + r1 * sa), (cx + r2 * ca, cy + r2 * sa)],
               fill=color, width=(w_quarter if i % 3 == 0 else w_other) * K)


def draw_disc(d, cx, cy):
    n = 7
    for i in range(n):
        f = i / float(n - 1)
        v = 0x56 + int((0x29 - 0x56) * f)
        rr = R_DISC * K * (1.0 - i * 0.09)
        ox = -R_DISC * K * 0.10 * (1 - f)
        oy = -R_DISC * K * 0.13 * (1 - f)
        d.ellipse([cx + ox - rr, cy + oy - rr, cx + ox + rr, cy + oy + rr],
                  fill=(v, v + 1, v + 2))


def face(hh, mm, aod=False):
    img = Image.new("RGB", (S * K, S * K), (0, 0, 0))
    d = ImageDraw.Draw(img)
    c = S * K // 2
    ha = ((hh % 12) + mm / 60.0) * 30.0
    ma = mm * 6.0

    if aod:
        cx = c + ((mm % 3) - 1) * 6 * K
        cy = c + (((mm // 3) % 3) - 1) * 6 * K
        draw_ticks(d, cx, cy, AOD_T, 3, 2)
        d.polygon(hand_points(cx, cy, ha, L_HOUR, W_HOUR), fill=AOD)
        d.polygon(hand_points(cx, cy, ma, L_MIN, W_MIN), fill=AOD)
    else:
        d.ellipse([0, 0, S * K - 1, S * K - 1], fill=BG)
        draw_ticks(d, c, c, TICK, 5, 3)
        draw_disc(d, c, c)
        for deg, ln, wt in ((ha, L_HOUR, W_HOUR), (ma, L_MIN, W_MIN)):
            d.polygon(hand_points(c, c, deg, ln, wt, SHADE_X * K, SHADE_Y * K), fill=SHADE)
        draw_hand(d, c, c, ha, L_HOUR, W_HOUR)
        draw_hand(d, c, c, ma, L_MIN, W_MIN)
        d.ellipse([c - R_PIVOT * K, c - R_PIVOT * K,
                   c + R_PIVOT * K, c + R_PIVOT * K], fill=PIVOT)

    img = img.resize((S, S), Image.LANCZOS).convert("RGBA")
    mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(mask).ellipse([0, 0, S - 1, S - 1], fill=255)
    img.putalpha(mask)
    return img


def bezel(inner, pad=22):
    W = S + pad * 2
    c = Image.new("RGBA", (W, W), (0, 0, 0, 0)); d = ImageDraw.Draw(c)
    d.ellipse([0, 0, W - 1, W - 1], fill=(58, 60, 66, 255))
    d.ellipse([pad - 4, pad - 4, pad + S + 3, pad + S + 3], fill=(20, 21, 24, 255))
    c.alpha_composite(inner, (pad, pad)); return c


HH = int(sys.argv[1]) if len(sys.argv) > 1 else 10
MM = int(sys.argv[2]) if len(sys.argv) > 2 else 9

tiles = [(bezel(face(HH, MM)), "%d:%02d" % (HH, MM)),
         (bezel(face(1, 51)), "1:51"),
         (bezel(face(6, 30)), "6:30"),
         (bezel(face(8, 20)), "8:20"),
         (bezel(face(HH, MM, aod=True)), "ALWAYS-ON")]

f_lab = ImageFont.truetype(os.path.join(SRC, "RobotoMono-Bold.ttf"), 20)
t = int(tiles[0][0].width * 0.46)
gap, margin, lab = 18, 28, 34
out = Image.new("RGB", (margin * 2 + len(tiles) * t + (len(tiles) - 1) * gap,
                        margin * 2 + t + lab), (18, 18, 22))
d = ImageDraw.Draw(out)
for i, (w, lb) in enumerate(tiles):
    x = margin + i * (t + gap)
    ws = w.resize((t, t)); out.paste(ws, (x, margin), ws)
    d.text((x + t // 2, margin + t + 6), lb, font=f_lab, fill=(255, 255, 255), anchor="ma")
out.save(OUT)

# Presupuesto del 10% de pixeles encendidos en Always-On
g = face(HH, MM, aod=True).convert("L")
lit = sum(1 for p in g.getdata() if p > 8)
print("preview:", OUT)
print("AOD: %d px encendidos (%.2f%% de %d)" % (lit, 100.0 * lit / (S * S), S * S))
