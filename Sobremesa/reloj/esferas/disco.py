"""Disco, para pantalla grande.

Misma geometría que la esfera del Garmin (`Disco/`), con las medidas pasadas a
fracción del radio para que sirva igual en un monitor de 24" que en una
pantallita de 5". Lo que cambia es lo que el reloj no podía darnos:

* **antialiasing de verdad** — en el Garmin las agujas finas salían dentadas;
* **segundero de barrido**, continuo, no a saltos. Una esfera Connect IQ se
  redibuja una vez por segundo, así que un barrido era literalmente imposible;
* y ya no hay techo de píxeles encendidos, porque la retro de un IPS está
  encendida igual.
"""

import math

from ..lienzo import Lienzo, aguja

NOMBRE = "disco"

# ---- Paleta, idéntica a la del Garmin ----
FONDO    = 0x000000
TICK     = 0x7A5E10   # las ocho marcas menores
TICK_Q   = 0xC9A21E   # 12, 3, 6 y 9: más vivas
TINTA    = 0xF7C81E   # cuerpo de las agujas, ámbar
BISEL    = 0xFFE49A   # la media aguja que da a la luz
PIVOTE   = 0xFFF0C4
SEGUNDO  = 0xC9A21E   # el segundero, en el ámbar apagado de las marcas

# ---- Geometría, en fracción del radio (el original iba en px sobre R = 227) ----
L_MIN     = 215 / 227.0
L_HOUR    = 142 / 227.0
L_SEG     = 222 / 227.0
COLA      = 34 / 227.0
R_DISCO   = 27 / 227.0
R_PIVOTE  = 5 / 227.0

W_MIN_COLA,  W_MIN_CUERPO,  K_SH_MIN  = 13 / 227.0, 10 / 227.0, 0.66
W_HOUR_COLA, W_HOUR_CUERPO, K_SH_HOUR = 16 / 227.0, 13 / 227.0, 0.60
W_SEG_COLA,  W_SEG_CUERPO,  K_SH_SEG  = 5 / 227.0,  3 / 227.0,  0.90

TICK_W_Q   = 26 / 227.0
TICK_W     = 17 / 227.0
TICK_R_IN_Q = 0.775   # las de los cuartos, más largas
TICK_R_IN   = 0.855
TICK_R_OUT  = 0.955   # todas acaban a la misma altura

ORDEN = ("hora", "minuto", "segundo", "pivote")


def fondo(lado):
    """Lo que no se mueve: negro, doce marcas y el disco central."""
    r = lado / 2.0
    lz = Lienzo(lado, FONDO)
    _marcas(lz, r)
    _disco(lz, r)
    return lz.array()[:, :, :3]


def _marcas(lz, r):
    c = r
    for i in range(12):
        a = math.radians(i * 30.0 - 90.0)
        ux, uy = math.cos(a), math.sin(a)
        px, py = -uy, ux
        cuarto = (i % 3 == 0)
        hw = r * (TICK_W_Q if cuarto else TICK_W) / 2.0
        r1 = r * (TICK_R_IN_Q if cuarto else TICK_R_IN)
        r2 = r * TICK_R_OUT
        lz.poligono([(c + ux * r1 + px * hw, c + uy * r1 + py * hw),
                     (c + ux * r2 + px * hw, c + uy * r2 + py * hw),
                     (c + ux * r2 - px * hw, c + uy * r2 - py * hw),
                     (c + ux * r1 - px * hw, c + uy * r1 - py * hw)],
                    TICK_Q if cuarto else TICK)


def _disco(lz, r):
    """Siete anillos concéntricos, cada uno más oscuro y descentrado hacia
    abajo a la derecha: es lo que finge la luz cayendo desde arriba a la
    izquierda cuando no hay degradados."""
    rd = r * R_DISCO
    n = 7
    for i in range(n):
        f = i / (n - 1.0)
        v = 0x5E + int((0x1C - 0x5E) * f)
        lz.circulo(r - rd * 0.10 * (1 - f), r - rd * 0.13 * (1 - f),
                   rd * (1.0 - i * 0.09), (v << 16) | ((v + 1) << 8) | (v + 2))


def piezas(lado):
    """Las partes que giran, cada una apuntando a las 12 y con el pivote en el
    centro del lienzo. Así SDL las rota alrededor del centro y no hay que
    llevar la cuenta de ningún desplazamiento."""
    r = lado / 2.0
    lz = Lienzo(lado)
    lz.circulo(r, r, r * R_PIVOTE, PIVOTE)
    return {
        "hora": aguja(lado, r * L_HOUR, r * COLA, r * W_HOUR_COLA,
                      r * W_HOUR_CUERPO, K_SH_HOUR, TINTA, BISEL),
        "minuto": aguja(lado, r * L_MIN, r * COLA, r * W_MIN_COLA,
                        r * W_MIN_CUERPO, K_SH_MIN, TINTA, BISEL),
        "segundo": aguja(lado, r * L_SEG, r * COLA * 1.6, r * W_SEG_COLA,
                         r * W_SEG_CUERPO, K_SH_SEG, SEGUNDO),
        "pivote": lz.array(),
    }


def angulos(t):
    """Grados en sentido horario desde las 12. `t` son segundos desde
    medianoche, con decimales — de ahí sale el barrido del segundero."""
    seg = t % 60.0
    mins = (t / 60.0) % 60.0
    horas = (t / 3600.0) % 12.0
    return {"hora": horas * 30.0, "minuto": mins * 6.0,
            "segundo": seg * 6.0, "pivote": 0.0}
