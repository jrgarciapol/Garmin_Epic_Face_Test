#!/usr/bin/env python3
"""Inspecciona un modelo 3D y cuenta lo que hay dentro.

FBX no lo lee Python directamente (es formato propietario de Autodesk), así que
va por `assimp`: FBX -> glTF -> trimesh. Probado con una ida y vuelta completa.

Uso:  python3 inspeccionar.py modelo.fbx
      python3 inspeccionar.py modelo.fbx --glb salida.glb   (deja la conversión)

Requisitos:  apt-get install assimp-utils  ·  pip install trimesh numpy
"""
import os
import subprocess
import sys
import tempfile

SIN_CONVERSION = (".glb", ".gltf", ".obj", ".ply", ".stl", ".dae", ".off")


def a_glb(ruta, destino):
    """Convierte cualquier formato que entienda assimp a glTF binario."""
    r = subprocess.run(["assimp", "export", ruta, destino],
                       capture_output=True, text=True)
    if r.returncode != 0 or not os.path.exists(destino):
        sys.exit("assimp no pudo convertir %s:\n%s" % (ruta, r.stderr.strip()))
    return destino


def jerarquia(ruta):
    """El volcado de assimp trae la jerarquía de nodos y los huesos, que es lo
    que de verdad importa para articular la figura."""
    r = subprocess.run(["assimp", "info", ruta], capture_output=True, text=True)
    return r.stdout if r.returncode == 0 else ""


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    ruta = sys.argv[1]
    if not os.path.exists(ruta):
        sys.exit("No encuentro %s" % ruta)

    import trimesh

    ext = os.path.splitext(ruta)[1].lower()
    tmp = None
    if ext in SIN_CONVERSION:
        leible = ruta
    else:
        if "--glb" in sys.argv:
            leible = sys.argv[sys.argv.index("--glb") + 1]
        else:
            tmp = tempfile.mkdtemp()
            leible = os.path.join(tmp, "conv.glb")
        a_glb(ruta, leible)
        print("convertido a %s\n" % leible)

    escena = trimesh.load(leible)
    mallas = (escena.geometry if isinstance(escena, trimesh.Scene)
              else {"malla": escena})

    print("=== MALLAS (%d) ===" % len(mallas))
    tv = tf = 0
    for nombre, m in mallas.items():
        tv += len(m.vertices)
        tf += len(m.faces)
        col = ""
        vis = getattr(m, "visual", None)
        if vis is not None and getattr(vis, "material", None) is not None:
            col = "  material: %s" % getattr(vis.material, "name", "sin nombre")
        print("  %-28s %6d vértices  %6d caras%s"
              % (nombre[:28], len(m.vertices), len(m.faces), col))
    print("  %-28s %6d           %6d" % ("TOTAL", tv, tf))

    caja = escena.bounds
    if caja is not None:
        d = caja[1] - caja[0]
        print("\n=== TAMAÑO ===")
        print("  caja: %.2f x %.2f x %.2f" % (d[0], d[1], d[2]))
        eje = "XYZ"[int(d.argmax())]
        print("  el eje más largo es %s -> probablemente ese es el 'alto'" % eje)

    info = jerarquia(ruta)
    if info:
        huesos = [l.strip() for l in info.splitlines()
                  if "bone" in l.lower() or "hueso" in l.lower()]
        print("\n=== ESQUELETO ===")
        print("  " + ("\n  ".join(huesos[:20]) if huesos
                      else "sin huesos: habrá que girar los brazos como objetos"))

    print("\n=== JERARQUÍA DE NODOS ===")
    dentro = False
    for linea in info.splitlines():
        if linea.startswith("Node hierarchy"):
            dentro = True
            continue
        if dentro:
            if not linea.strip():
                break
            print("  " + linea.rstrip())


if __name__ == "__main__":
    main()
