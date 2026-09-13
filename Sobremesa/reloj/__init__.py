"""Relojes para pantalla grande, movidos por una Raspberry Pi.

El reparto de trabajo es el que hace que esto quepa en una Pi Zero 2 W:

    esferas/    dibujan **una vez** al arrancar y devuelven arrays numpy
    pantalla    sube esos arrays a la tarjeta y los rota por hardware
    lamina      los compone con Pillow, sin pantalla, para ver un PNG

Una esfera no sabe nada de SDL. Solo tiene que ofrecer tres cosas:

    fondo(lado)    -> (lado, lado, 3) uint8, lo que no se mueve
    piezas(lado)   -> {nombre: (lado, lado, 4) uint8}, apuntando a las 12
                      y con el pivote en el centro
    angulos(t)     -> {nombre: grados horarios}, con t en segundos desde
                      medianoche y decimales
    ORDEN          -> los nombres, en orden de dibujo
"""
