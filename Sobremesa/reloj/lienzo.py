"""Dibujo con antialiasing de verdad, sobre numpy.

En el Garmin las agujas se dibujaban con `fillPolygon` y el antialiasing que
quisiera darnos el reloj. Aquí no hay prisa: el dibujo se hace **una sola vez
al arrancar**, así que se puede rasterizar a 4x y reducir. Lo que sale es un
array RGBA que luego SDL sube a la tarjeta y rota por hardware.

Ese reparto —Pillow construye, SDL mueve— es lo que hace que una Pi Zero 2 W
pueda con esto: por fotograma solo hay tres o cuatro `RenderCopyEx`.
"""

import numpy as np
from PIL import Image, ImageDraw

SUP = 4  # supermuestreo


def _rgba(c, a=255):
    """0xRRGGBB -> (r, g, b, a)."""
    return ((c >> 16) & 0xFF, (c >> 8) & 0xFF, c & 0xFF, a)


class Lienzo:
    """Un cuadrado de `lado` px que se dibuja a `lado * SUP` y se reduce."""

    def __init__(self, lado, fondo=None):
        self.lado = lado
        n = lado * SUP
        self.im = Image.new("RGBA", (n, n), _rgba(fondo) if fondo is not None
                            else (0, 0, 0, 0))
        self.d = ImageDraw.Draw(self.im)

    def poligono(self, pts, color, alfa=255):
        self.d.polygon([(x * SUP, y * SUP) for x, y in pts], fill=_rgba(color, alfa))

    def circulo(self, cx, cy, r, color, alfa=255):
        self.d.ellipse([(cx - r) * SUP, (cy - r) * SUP,
                        (cx + r) * SUP, (cy + r) * SUP], fill=_rgba(color, alfa))

    def array(self):
        """Reduce a tamaño final y devuelve (lado, lado, 4) uint8 RGBA.

        La reducción va sobre **alfa premultiplicado**. Si no, los píxeles
        transparentes (que por dentro son negros) tiñen de negro el borde de
        cada aguja al promediarlos con los opacos. Sobre fondo negro no se
        notaría, pero la esfera siguiente puede no serlo.
        """
        a = np.asarray(self.im, dtype=np.float32)
        al = a[:, :, 3:4] / 255.0
        pm = np.concatenate([a[:, :, :3] * al, a[:, :, 3:4]], axis=2)

        n = self.lado
        pm = pm.reshape(n, SUP, n, SUP, 4).mean(axis=(1, 3))

        al = pm[:, :, 3:4] / 255.0
        rgb = np.divide(pm[:, :, :3], al, out=np.zeros_like(pm[:, :, :3]),
                        where=al > 1e-4)
        out = np.concatenate([rgb, pm[:, :, 3:4]], axis=2)
        return np.ascontiguousarray(np.clip(out + 0.5, 0, 255).astype(np.uint8))


def aguja(lado, largo, cola, w_cola, w_cuerpo, k_hombro, tinta, bisel=None):
    """Una aguja apuntando a las 12, con el pivote en el centro del lienzo.

    Cinco vértices, igual que en el Garmin: punta · hombro izq · cola izq ·
    cola der · hombro der. De la cola al hombro apenas estrecha; del hombro a
    la punta se afila. El `bisel` es la mitad iluminada, que es lo que finge
    el volumen cuando no hay degradados.

    Todas las medidas van en píxeles del lienzo final.
    """
    c = lado / 2.0
    ht, hb = w_cola / 2.0, w_cuerpo / 2.0
    by = c + cola                 # extremo de la cola (hacia abajo)
    sy = c - largo * k_hombro     # hombro

    pts = [(c, c - largo), (c + hb, sy), (c + ht, by), (c - ht, by), (c - hb, sy)]

    lz = Lienzo(lado)
    lz.poligono(pts, tinta)
    if bisel is not None:
        lz.poligono([pts[0], pts[1], pts[2], (c, by)], bisel)
    return lz.array()
