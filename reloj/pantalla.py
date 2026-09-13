"""Salida por SDL2: sube los arrays a la tarjeta y los rota por hardware.

Misma pila que el simulador de conducción (`pysdl2` + `numpy`), y por la misma
razón: SDL2 pinta sobre KMS/DRM sin escritorio, así que en la Pi arranca contra
la pantalla pelada, sin X ni Wayland.

Por fotograma solo hay un `RenderCopy` del fondo y un `RenderCopyEx` por aguja.
El coste real de dibujar se pagó entero al arrancar.
"""

import ctypes
import time

import numpy as np
import sdl2


def _textura(ren, arr):
    """numpy (h, w, 3|4) uint8 -> SDL_Texture.

    El array tiene que seguir vivo mientras exista la superficie, así que se
    libera la superficie **antes** de salir de la función.
    """
    arr = np.ascontiguousarray(arr)
    h, w = arr.shape[:2]
    if arr.shape[2] == 3:
        arr = np.dstack([arr, np.full((h, w, 1), 255, np.uint8)])
        arr = np.ascontiguousarray(arr)
    # numpy guarda R,G,B,A en ese orden de bytes; en little-endian eso es un
    # uint32 ABGR.
    sup = sdl2.SDL_CreateRGBSurfaceWithFormatFrom(
        arr.ctypes.data_as(ctypes.c_void_p), w, h, 32, w * 4,
        sdl2.SDL_PIXELFORMAT_ABGR8888)
    tex = sdl2.SDL_CreateTextureFromSurface(ren, sup)
    sdl2.SDL_FreeSurface(sup)
    sdl2.SDL_SetTextureBlendMode(tex, sdl2.SDL_BLENDMODE_BLEND)
    return tex


def _ahora():
    """Segundos desde medianoche, hora local, con decimales."""
    t = time.time()
    lt = time.localtime(t)
    return lt.tm_hour * 3600 + lt.tm_min * 60 + lt.tm_sec + (t % 1.0)


def correr(esfera, lado=None, ventana=False, fps=30):
    if sdl2.SDL_Init(sdl2.SDL_INIT_VIDEO) != 0:
        raise SystemExit(sdl2.SDL_GetError().decode())

    # Filtrado bilineal: sin esto la rotación de las agujas sale a escalones y
    # se pierde justo el antialiasing que fuimos a buscar.
    sdl2.SDL_SetHint(sdl2.SDL_HINT_RENDER_SCALE_QUALITY, b"1")

    modo = sdl2.SDL_DisplayMode()
    sdl2.SDL_GetCurrentDisplayMode(0, ctypes.byref(modo))
    if ventana:
        lado = lado or 800
        ancho = alto = lado
        flags = 0
    else:
        ancho, alto = modo.w, modo.h
        lado = lado or min(ancho, alto)
        flags = sdl2.SDL_WINDOW_FULLSCREEN_DESKTOP

    win = sdl2.SDL_CreateWindow(b"reloj", sdl2.SDL_WINDOWPOS_CENTERED,
                                sdl2.SDL_WINDOWPOS_CENTERED, ancho, alto, flags)
    ren = sdl2.SDL_CreateRenderer(
        win, -1, sdl2.SDL_RENDERER_ACCELERATED | sdl2.SDL_RENDERER_PRESENTVSYNC)
    sdl2.SDL_ShowCursor(sdl2.SDL_DISABLE)

    fondo = _textura(ren, esfera.fondo(lado))
    piezas = {n: _textura(ren, a) for n, a in esfera.piezas(lado).items()}

    dst = sdl2.SDL_Rect((ancho - lado) // 2, (alto - lado) // 2, lado, lado)
    centro = sdl2.SDL_Point(lado // 2, lado // 2)
    ev = sdl2.SDL_Event()
    espera = 1.0 / fps

    try:
        while True:
            while sdl2.SDL_PollEvent(ctypes.byref(ev)):
                if ev.type == sdl2.SDL_QUIT:
                    return
                if (ev.type == sdl2.SDL_KEYDOWN
                        and ev.key.keysym.sym in (sdl2.SDLK_ESCAPE, sdl2.SDLK_q)):
                    return

            ang = esfera.angulos(_ahora())

            sdl2.SDL_SetRenderDrawColor(ren, 0, 0, 0, 255)
            sdl2.SDL_RenderClear(ren)
            sdl2.SDL_RenderCopy(ren, fondo, None, ctypes.byref(dst))
            for n in esfera.ORDEN:
                sdl2.SDL_RenderCopyEx(ren, piezas[n], None, ctypes.byref(dst),
                                      ang.get(n, 0.0), ctypes.byref(centro),
                                      sdl2.SDL_FLIP_NONE)
            sdl2.SDL_RenderPresent(ren)
            time.sleep(espera)
    finally:
        for t in piezas.values():
            sdl2.SDL_DestroyTexture(t)
        sdl2.SDL_DestroyTexture(fondo)
        sdl2.SDL_DestroyRenderer(ren)
        sdl2.SDL_DestroyWindow(win)
        sdl2.SDL_Quit()
