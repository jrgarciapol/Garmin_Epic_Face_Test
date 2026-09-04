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

## Dos correcciones (también aplicadas a `Pulso/`)

**El choque va por delante de los textos.** Los dos puntos de encuentro son
geométricamente simétricos, pero detrás de uno está `LUN` y detrás del otro
`9 AGO`. Dibujado por debajo, el estallido de arriba y el de abajo salían
recortados de forma muy distinta y no parecían el mismo efecto. Dibujado por
encima son idénticos — y tapar la hora un segundo era justamente la intención
del choque. El **viaje** sigue yendo por detrás: los orbes cruzan la hora sin
taparla.

**La estela mide 1,5 s de recorrido** (`TRAIL_SECS`), con un mínimo del arco
que la cabeza avanzó desde el fotograma anterior (`TRAIL_OVERLAP` = 1,15) para
que un trazo empalme siempre con el siguiente aunque el refresco venga lento.

Esa longitud **no es decorativa**. A mitad de camino los orbes pasan por detrás
de la hora, y con **hora de dos cifras** el bloque de texto ocupa de x=11 a
x=443 mientras la órbita pasa por x=16 y x=438: la cabeza queda literalmente
tapada por los dígitos. Con la cola larga el trazo asoma por encima y por debajo
de los números y el orbe se sigue viendo; acortándola, desaparece en ese tramo.

Con hora de una cifra (`9:24`) el texto solo llega a x=62..392 y no tapa nada —
por eso el problema no se ve si solo pruebas con esas horas.
