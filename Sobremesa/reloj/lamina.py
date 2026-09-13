"""La misma esfera, compuesta con Pillow y guardada en PNG.

Sirve para verla sin pantalla —en un servidor, o en una sesión como esta— y
para comparar dos variantes lado a lado. Usa exactamente los mismos arrays que
la salida por SDL, así que lo que se ve aquí es lo que se verá en la Pi salvo
por el filtrado de la rotación.
"""

import numpy as np
from PIL import Image


def _rotar(arr, grados):
    im = Image.fromarray(arr, "RGBA")
    return im.rotate(-grados, resample=Image.BICUBIC, expand=False)


def componer(esfera, lado, t):
    base = Image.fromarray(esfera.fondo(lado), "RGB").convert("RGBA")
    ang = esfera.angulos(t)
    piezas = esfera.piezas(lado)
    for n in esfera.ORDEN:
        base.alpha_composite(_rotar(piezas[n], ang.get(n, 0.0)))
    return base.convert("RGB")


def hoja(esfera, lado, tiempos, columnas=2, hueco=20):
    """Varias horas en una sola imagen, para comparar de un vistazo."""
    ims = [componer(esfera, lado, t) for t in tiempos]
    filas = (len(ims) + columnas - 1) // columnas
    w = columnas * lado + (columnas - 1) * hueco
    h = filas * lado + (filas - 1) * hueco
    out = Image.new("RGB", (w, h), (18, 18, 18))
    for k, im in enumerate(ims):
        out.paste(im, ((k % columnas) * (lado + hueco),
                       (k // columnas) * (lado + hueco)))
    return out


def reloj_a_segundos(txt):
    """'10:09' o '10:09:30' -> segundos desde medianoche."""
    p = [float(x) for x in txt.split(":")]
    while len(p) < 3:
        p.append(0.0)
    return p[0] * 3600 + p[1] * 60 + p[2]
