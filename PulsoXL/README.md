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
