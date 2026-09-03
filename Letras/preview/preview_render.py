#!/usr/bin/env python3
"""Vista previa de la esfera Letras. Replica EpixWatchFaceView.mc: mismos
cuerpos de letra, mismo reparto vertical y las mismas reglas de castellano.

Uso:  python3 preview_render.py
"""
import os
from PIL import Image, ImageDraw, ImageFont

_HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(os.path.dirname(_HERE), "fonts-src")
TTF = os.path.join(SRC, "Barriecito-Regular.ttf")
OUT = os.path.join(_HERE, "preview.png")
OUT_AOD = os.path.join(_HERE, "preview_aod.png")

S = 454

# Paleta "hueso y ambar", igual que el .mc
C_HOUR = (0xF3, 0xE7, 0xD3)
C_LINK = (0x6E, 0x56, 0x2C)
C_MIN = (0xFF, 0xB0, 0x20)

Y3 = (0.240, 0.500, 0.760)
Y4 = (0.175, 0.385, 0.605, 0.825)
YA = (0.270, 0.500, 0.730)

F_WORD = ImageFont.truetype(TTF, 116)
F_WORDS = ImageFont.truetype(TTF, 100)
F_LINK = ImageFont.truetype(TTF, 64)
F_WORDA = ImageFont.truetype(TTF, 64)
F_LINKA = ImageFont.truetype(TTF, 38)

HORAS = ["DOCE", "UNA", "DOS", "TRES", "CUATRO", "CINCO", "SEIS", "SIETE",
         "OCHO", "NUEVE", "DIEZ", "ONCE"]


def rounded_minute(mm):
    return ((mm + 2) // 5) * 5


def hour_name(hh, m):
    return HORAS[(hh + (1 if m >= 35 else 0)) % 12]


def link_word(m):
    if m == 0 or m == 60:
        return "EN"
    return "Y" if m <= 30 else "MENOS"


def minute_name(m):
    if m == 0 or m == 60:
        return "PUNTO"
    if m == 30:
        return "MEDIA"
    if m in (15, 45):
        return "CUARTO"
    n = m if m <= 30 else 60 - m
    return {5: "CINCO", 10: "DIEZ", 20: "VEINTE", 25: "VEINTICINCO"}[n]


def face(hh, mm, aod=False):
    img = Image.new("RGB", (S, S), (0, 0, 0))
    d = ImageDraw.Draw(img)
    m = rounded_minute(mm)
    h, lk, mi = hour_name(hh, m), link_word(m), minute_name(m)

    if aod:
        cx = S // 2 + ((mm % 3) - 1) * 7
        dy = (((mm // 3) % 3) - 1) * 7
        rows = [(h, F_WORDA, YA[0], C_HOUR), (lk, F_LINKA, YA[1], C_LINK),
                (mi, F_WORDA, YA[2], C_MIN)]
        for txt, f, y, col in rows:
            d.text((cx, int(S * y) + dy), txt, font=f, fill=col, anchor="mm")
    elif mi == "VEINTICINCO":
        rows = [(h, F_WORDS, Y4[0], C_HOUR), (lk, F_LINK, Y4[1], C_LINK),
                ("VEINTI", F_WORDS, Y4[2], C_MIN), ("CINCO", F_WORDS, Y4[3], C_MIN)]
        for txt, f, y, col in rows:
            d.text((S // 2, int(S * y)), txt, font=f, fill=col, anchor="mm")
    else:
        rows = [(h, F_WORD, Y3[0], C_HOUR), (lk, F_LINK, Y3[1], C_LINK),
                (mi, F_WORD, Y3[2], C_MIN)]
        for txt, f, y, col in rows:
            d.text((S // 2, int(S * y)), txt, font=f, fill=col, anchor="mm")

    img = img.convert("RGBA")
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


def strip(tiles, path, scale=0.44, rows=1):
    f_lab = ImageFont.truetype(os.path.join(SRC, "RobotoMono-Bold.ttf"), 19)
    t = int(tiles[0][0].width * scale)
    per = (len(tiles) + rows - 1) // rows
    gap, margin, lab = 18, 26, 32
    out = Image.new("RGB", (margin * 2 + per * t + (per - 1) * gap,
                            margin * 2 + rows * (t + lab) + (rows - 1) * 8),
                    (18, 18, 22))
    d = ImageDraw.Draw(out)
    for i, (w, lb) in enumerate(tiles):
        r, c = divmod(i, per)
        x = margin + c * (t + gap)
        y = margin + r * (t + lab + 8)
        ws = w.resize((t, t)); out.paste(ws, (x, y), ws)
        d.text((x + t // 2, y + t + 5), lb, font=f_lab, fill=(255, 255, 255), anchor="ma")
    out.save(path)


CASOS = [(1, 15), (2, 45), (6, 30), (12, 0), (9, 35), (4, 57),
         (8, 20), (11, 50)]
strip([(bezel(face(h, m)), "%d:%02d" % (h, m)) for h, m in CASOS], OUT, rows=2)
strip([(bezel(face(h, m, aod=True)), "AOD %d:%02d" % (h, m))
       for h, m in ((9, 35), (2, 45), (12, 0))], OUT_AOD, scale=0.52)

# Presupuesto del 10% de pixeles encendidos en Always-On, caso peor
peor = 0
for h in range(24):
    for m in range(60):
        g = face(h, m, aod=True).convert("L")
        n = sum(1 for p in g.get_flattened_data() if p > 8)
        peor = max(peor, n)
    if h > 1:
        break
print("preview:", OUT, "|", OUT_AOD)
print("AOD peor caso: %d px = %.2f%% de %d" % (peor, 100.0 * peor / (S * S), S * S))
