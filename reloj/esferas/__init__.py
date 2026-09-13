"""Catálogo de esferas."""

import importlib

DISPONIBLES = ("disco",)


def cargar(nombre):
    if nombre not in DISPONIBLES:
        raise SystemExit("No conozco la esfera %r. Hay: %s"
                         % (nombre, ", ".join(DISPONIBLES)))
    return importlib.import_module("." + nombre, __name__)
