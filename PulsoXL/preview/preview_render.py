#!/usr/bin/env python3
"""Vista previa de la esfera Pulso XL. Replica lo que hace EpixWatchFaceView.mc:
dos orbes que nacen blancos, divergen a rojos/azules, chocan y estallan en
anillos de arcoiris. A diferencia de Pulso, el TAMANO del orbe
tambien es proporcional al pulso.

Uso:  python3 preview_render.py [pulsaciones]
"""
import math, os, sys, colorsys
from PIL import Image, ImageDraw, ImageFont

_HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(os.path.dirname(_HERE), "fonts-src")
OUT = os.path.join(_HERE, "preview.png")
OUT_GIF = os.path.join(_HERE, "preview.gif")

S = 454
# Triada: naranja y cian son de los orbes, verde del texto (80 grados de
# separacion entre los tres). El mes se retira a un gris azulado neutro.
GREEN = (0x6F, 0xDC, 0x8C); BLUE = (0x93, 0xA6, 0xB2); WHITE = (255, 255, 255)
Y_WDAY, Y_TIME, Y_DATE = 0.200, 0.500, 0.815

# Mismos valores que el .mc
R_ORB = 211
DEG_PER_BEAT = 12.0
TRAVEL_BEATS, MERGE_BEATS = 15.0, 3.0
CYCLE = TRAVEL_BEATS + MERGE_BEATS
TRAIL_DOTS, TRAIL_SECS, TRAIL_OVERLAP = 8, 1.5, 1.15

HR = int(sys.argv[1]) if len(sys.argv) > 1 else 95

f_time = ImageFont.truetype(os.path.join(SRC, "Barriecito-Regular.ttf"), 196)
f_num = ImageFont.truetype(os.path.join(SRC, "Barriecito-Regular.ttf"), 108)
f_mon = ImageFont.truetype(os.path.join(SRC, "Barriecito-Regular.ttf"), 92)
f_lab = ImageFont.truetype(os.path.join(SRC, "RobotoMono-Bold.ttf"), 20)


def hsv(h, s, v):
    r, g, b = colorsys.hsv_to_rgb(h % 1.0, max(0.0, min(1.0, s)), max(0.0, min(1.0, v)))
    return (int(r * 255), int(g * 255), int(b * 255))


H_WARM, H_COOL = 0.07, 0.53   # naranja y cian, igualados en luminancia


def orb_color(t, warm, v=1.0):
    t = max(0.0, min(1.0, t))
    s = t ** 0.7
    return hsv(H_WARM, s * 0.85, v) if warm else hsv(H_COOL, s, v * 0.92)


def dot_radius(hr):
    return max(6.0, min(9.0 + (hr - 60.0) * 0.20, 34.0))


def merge_radius(hr):
    return max(18.0, min(45.0 + (hr - 60.0) * 1.55, 250.0))


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


def P(deg):
    a = math.radians(deg - 90)
    return S // 2 + R_ORB * math.cos(a), S // 2 + R_ORB * math.sin(a)


def dot(d, deg, r, color):
    if r < 1:
        return
    x, y = P(deg)
    d.ellipse([x - r, y - r, x + r, y + r], fill=color)


def head(d, deg, t, warm, r_dot):
    for k, v in ((1.9, 0.25), (1.4, 0.60), (1.0, 1.0)):
        dot(d, deg, r_dot * k, orb_color(t, warm, v))


def burst(d, deg, radius, fade):
    """Los colores de los dos orbes fundiendose: frio fuera, calido despues,
    nucleo blanco. Antes era un arcoiris, ajeno a los orbes y con el brillo
    dando tumbos (13% del anillo violeta al 83% del amarillo)."""
    n = 7
    for i in range(n):
        rr = radius * (1.0 - i / float(n))
        if rr < 1:
            continue
        f = i / float(n - 1)
        if f < 0.5:
            col = hsv(H_COOL + (H_WARM - H_COOL) * (f / 0.5), 1.0, fade)
        else:
            col = hsv(H_WARM, 1.0 - (f - 0.5) / 0.5, fade)
        dot(d, deg, rr, col)


def draw_pulse(d, beats, hr, dt=1.0, fase="viaje"):
    """fase 'viaje' se dibuja antes que los textos; 'choque', despues."""
    bps = hr / 60.0
    r_dot = dot_radius(hr)
    cyc = int(beats // CYCLE)
    p = beats - cyc * CYCLE
    s = 1 if cyc % 2 == 0 else -1
    start = 0.0 if cyc % 2 == 0 else 180.0

    if fase == "viaje" and p < TRAVEL_BEATS:
        t = p / TRAVEL_BEATS
        adv = DEG_PER_BEAT * p
        # 1,5 s de recorrido, nunca menos que el paso del ultimo fotograma
        span = min(max(DEG_PER_BEAT * bps * TRAIL_SECS,
                       DEG_PER_BEAT * bps * dt * TRAIL_OVERLAP), adv)
        for i in range(TRAIL_DOTS, 0, -1):
            f = i / float(TRAIL_DOTS)
            back = span * f
            tk = t - back / 180.0
            rr = r_dot * (0.30 + 0.55 * (1 - f))
            dim = 0.25 + 0.55 * (1 - f)
            dot(d, start + s * (adv - back), rr, orb_color(tk, True, dim))
            dot(d, start - s * (adv - back), rr, orb_color(tk, False, dim))
        head(d, start + s * adv, t, True, r_dot)
        head(d, start - s * adv, t, False, r_dot)
    elif fase == "choque" and p >= TRAVEL_BEATS:
        m = (p - TRAVEL_BEATS) / MERGE_BEATS
        meet = start + 180.0
        R = merge_radius(hr)
        if m < 0.28:
            burst(d, meet, r_dot + (R - r_dot) * (m / 0.28), 1.0)
        else:
            q = (m - 0.28) / 0.72
            burst(d, meet, R * (1.0 - q) ** 1.6, 1.0 - 0.5 * q)


def face(beats, hr):
    img = Image.new("RGBA", (S, S), (0, 0, 0, 255))
    d = ImageDraw.Draw(img)
    cx = S // 2
    draw_pulse(d, beats, hr, fase="viaje")   # el viaje, por debajo del texto
    d.text((cx, int(S * Y_WDAY)), "LUN", font=f_mon, fill=GREEN, anchor="mm")
    tab_time(d, cx, int(S * Y_TIME), "9:24", WHITE, f_time)
    numW = f_num.getlength("9"); gap = 14
    x0 = cx - (numW + gap + f_mon.getlength("AGO")) / 2
    d.text((x0, int(S * Y_DATE)), "9", font=f_num, fill=GREEN, anchor="lm")
    d.text((x0 + numW + gap, int(S * Y_DATE)), "AGO", font=f_mon, fill=BLUE, anchor="lm")
    draw_pulse(d, beats, hr, fase="choque")  # el choque, por encima
    mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(mask).ellipse([0, 0, S - 1, S - 1], fill=255)
    img.putalpha(mask); return img


def bezel(inner, pad=22):
    W = S + pad * 2
    c = Image.new("RGBA", (W, W), (0, 0, 0, 0)); d = ImageDraw.Draw(c)
    d.ellipse([0, 0, W - 1, W - 1], fill=(58, 60, 66, 255))
    d.ellipse([pad - 4, pad - 4, pad + S + 3, pad + S + 3], fill=(20, 21, 24, 255))
    c.alpha_composite(inner, (pad, pad)); return c


# Tira comparativa: el MISMO instante del viaje a distintas pulsaciones, que
# es lo que distingue a esta variante de Pulso.
rates = [55, 75, 100, 130, 160]
tiles = [(bezel(face(TRAVEL_BEATS * 0.55, r)), "%d ppm" % r) for r in rates]
t = int(tiles[0][0].width * 0.46)
gap, margin, lab_h = 18, 28, 34
out = Image.new("RGB", (margin * 2 + len(tiles) * t + (len(tiles) - 1) * gap,
                        margin * 2 + t + lab_h), (18, 18, 22))
d = ImageDraw.Draw(out)
for i, (w, lb) in enumerate(tiles):
    x = margin + i * (t + gap)
    ws = w.resize((t, t)); out.paste(ws, (x, margin), ws)
    d.text((x + t // 2, margin + t + 6), lb, font=f_lab, fill=WHITE, anchor="ma")
out.save(OUT)

# GIF a 1 fps: exactamente el refresco del reloj
bps = HR / 60.0
secs = int(round(2 * CYCLE / bps))
frames = [bezel(face(i * bps, HR)).convert("RGB").resize((300, 300)) for i in range(secs)]
frames[0].save(OUT_GIF, save_all=True, append_images=frames[1:],
               duration=1000, loop=0, optimize=True)
print("preview:", OUT, "| gif:", OUT_GIF, "(%d ppm, %d fotogramas)" % (HR, secs))
