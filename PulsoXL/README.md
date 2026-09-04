# Epix Pulso XL — como Pulso, pero los orbes engordan con las pulsaciones

Misma esfera que `Pulso/` (base Barriecito, tamaños de texto 196 / 108 / 92
intactos, sin datos extra en pantalla) con **una sola diferencia**: el radio del
orbe deja de ser fijo (11 px) y pasa a ser **proporcional al pulso**.

| Pulso | Radio del orbe | Halo | Radio del estallido |
|---|---|---|---|
| 55 ppm  | 8 px  | 15 px | 37 px |
| 75 ppm  | 12 px | 23 px | 68 px |
| 100 ppm | 17 px | 32 px | 107 px |
| 130 ppm | 23 px | 44 px | 154 px |
| 160 ppm | 29 px | 55 px | 200 px |

La **estela** se mide en múltiplos del radio del orbe, así que engorda con él:
en reposo es un hilo fino y en esfuerzo un brochazo. El **estallido del choque**
ya era proporcional al pulso en `Pulso`, y aquí no cambia.

Todo lo demás es idéntico: la velocidad la marca el pulso (12° por latido, un
ciclo completo cada 18 latidos), los orbes nacen blancos y divergen a rojos y
azules, y el Always-On sigue siendo solo la hora.

Ver `source/EpixWatchFaceView.mc`, función `dotRadius()`.

## Dos correcciones sobre `Pulso/`

**El choque va por delante de los textos.** Los dos puntos de encuentro son
geométricamente simétricos, pero detrás de uno está `LUN` y detrás del otro
`9 AGO`. Dibujado por debajo, el estallido de arriba y el de abajo salían
recortados de forma muy distinta y no parecían el mismo efecto. Dibujado por
encima son idénticos — y tapar la hora un segundo era justamente la intención
del choque. El **viaje** sigue yendo por detrás: los orbes cruzan la hora sin
taparla.

**La estela mide el arco recorrido desde el fotograma anterior**, no un tiempo
fijo de 1,5 s. Al levantar la muñeca el sistema encadena varios `onUpdate` muy
seguidos: la cabeza avanzaba una pizca mientras la estela seguía midiendo 1,5 s,
y el resultado era un borrón largo que apenas se movía. Se leía como «va lento y
pastoso» hasta que el refresco se asentaba en uno por segundo. Ahora la estela
cubre exactamente el paso de cada fotograma (por `TRAIL_OVERLAP` = 1,15, para
que un trazo empalme con el siguiente), así que el movimiento se lee igual sea
cual sea el ritmo de refresco.

`Pulso/` conserva el comportamiento anterior en las dos cosas.
