"""Reloj de sobremesa / pared.

    python -m reloj                        pantalla completa
    python -m reloj --ventana              en una ventana de 800
    python -m reloj --esfera disco
    python -m reloj --lamina prueba.png --hora 10:09:30
    python -m reloj --lamina hoja.png --hora 10:09 1:50 6:30 8:20

Con `--lamina` no hace falta pantalla ni SDL: compone con Pillow y guarda.
"""

import argparse

from . import lamina
from .esferas import DISPONIBLES, cargar


def main():
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--esfera", default="disco", choices=DISPONIBLES)
    p.add_argument("--ventana", action="store_true",
                   help="en ventana en vez de pantalla completa")
    p.add_argument("--lado", type=int, default=None,
                   help="lado del dial en px (por defecto, el de la pantalla)")
    p.add_argument("--fps", type=int, default=30)
    p.add_argument("--lamina", metavar="PNG",
                   help="no abre pantalla: guarda un PNG y sale")
    p.add_argument("--hora", nargs="+", default=["10:09:38"],
                   help="una o varias horas para --lamina")
    a = p.parse_args()

    esfera = cargar(a.esfera)

    if a.lamina:
        lado = a.lado or 800
        ts = [lamina.reloj_a_segundos(h) for h in a.hora]
        im = (lamina.componer(esfera, lado, ts[0]) if len(ts) == 1
              else lamina.hoja(esfera, lado, ts))
        im.save(a.lamina)
        print("%s  (%dx%d)" % (a.lamina, im.width, im.height))
        return

    from . import pantalla
    pantalla.correr(esfera, lado=a.lado, ventana=a.ventana, fps=a.fps)


if __name__ == "__main__":
    main()
