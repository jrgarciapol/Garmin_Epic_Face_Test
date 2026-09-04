# Epix Disco — analógica minimalista, ámbar sobre negro

Adaptación al Epix Pro 51 mm de un reloj de disco: doce marcas, dos agujas que
nacen anchas en la cola y acaban en punta, un disco central y un pivote. **Sin
cifras, sin fecha y sin segundero.**

El diseño original tenía el **fondo claro** y así se programó al principio. Se
invirtió: un fondo claro enciende el 100% de la pantalla, era **imposible en
Always-On** (techo del 10%) y obligaba a que la esfera pasara de blanco a negro
cada vez que bajas la muñeca, con su fogonazo. Con el ámbar en la tinta, reposo
e interactiva son **la misma imagen** con distinto brillo.

Es la única esfera del banco de pruebas que **no usa ninguna fuente**: todo son
polígonos y círculos.

## Qué se pudo traer del diseño original y qué no

| Del SVG original | En Monkey C |
|---|---|
| Agujas afiladas | Un polígono de cinco vértices por aguja (ver más abajo) |
| Bisel de la aguja | Un segundo triángulo más claro sobre la mitad que da a la luz |
| `linearGradient` en las agujas | **No existe.** Sustituido por el bisel de arriba |
| `radialGradient` del disco | Siete círculos concéntricos, cada uno más oscuro y ligeramente descentrado. La banda es de 3 px y no se aprecia |
| `radialGradient` del fondo | **No existe** y por anillos se ven escalones: fondo plano |
| `feDropShadow` | **Se cayó al invertir la esfera**: sobre negro, una copia desplazada de la aguja en un tono más oscuro es invisible |
| Minutero con milisegundos | El minutero se recalcula cada segundo. Avanza 0,1°/s: imperceptible |

Las puntas finas dependen de **`dc.setAntiAlias(true)`**, que el Epix Pro
admite. Sin eso saldrían en escalera.

## La forma de la aguja

El diseño original estrecha en línea recta desde la cola hasta la punta. Sobre
una pantalla de 454 px eso deja **3-4 px a media aguja**, y a un vistazo cuesta
verla. Aquí la aguja se mantiene **casi paralela hasta el «hombro»** y solo
entonces se afila:

```
   punta
     /\          <- último tercio: punta de lanza
    |  |
    |  |         <- cuerpo, ancho constante (el hombro está en K_SH_*)
    |  |
   [====]        <- cola, un poco más ancha, por detrás del pivote
```

Se gana masa visible sin perder la punta de aguja, que es lo que hace bonito el
diseño. Las seis constantes están juntas en `EpixWatchFaceView.mc`:

| Constante | Minutero | Horario |
|---|---|---|
| `W_*_TAIL` (ancho en la cola) | 13 | 16 |
| `W_*_BODY` (ancho en el hombro) | 10 | 13 |
| `K_SH_*` (dónde empieza a afilar) | 0,66 | 0,60 |

Para volver a la aguja original del SVG, pon `W_*_BODY` a 1 y `K_SH_*` a 0.

## Las marcas horarias

Van emparejadas con las agujas: al ensanchar el cuerpo de la aguja, unas marcas
finas dejan el dial descompensado. Acabaron en **26/17 px**, y las de 12, 3, 6
y 9 son además **más largas**, para que sirvan de referencia sin tener que
contarlas.

| Constante | 12, 3, 6, 9 | Las otras ocho |
|---|---|---|
| `TICK_W_Q` / `TICK_W` (despierto) | 26 | 17 |
| `TICK_W_Q_AOD` / `TICK_W_AOD` (reposo) | 16 | 11 |
| `TICK_R_IN_Q` / `TICK_R_IN` (dónde empieza) | 0,775 | 0,855 |

Todas acaban en `TICK_R_OUT` = 0,955 del radio.

**Ancho y largo van juntos.** Con 26 px de ancho y la longitud anterior las
marcas se volvían cuadrados y dejaban de leerse como marcas; hubo que alargarlas
en la misma medida. Y a estos grosores tampoco vale `drawLine` con pincel ancho,
porque el remate de la línea depende del dispositivo: cada marca es un
rectángulo dibujado con `fillPolygon`, igual que las agujas.

## Always-On

Lo mismo que la interactiva, con las marcas atenuadas. Medido: **4,78%** de
píxeles encendidos, muy por debajo del techo del 10%. El conjunto se desplaza
unos píxeles cada minuto para repartir el desgaste.

## Colores

Están todos juntos al principio de `source/EpixWatchFaceView.mc`. Para volver
al fondo claro del diseño original hay que cambiar `COLOR_BG` a `0xF7C81E` y
además invertir la tinta (`COLOR_INK` a `0x181A1A`, `COLOR_BEVEL` a `0x343536`
y las marcas a tonos oscuros) — el fondo solo no basta.
