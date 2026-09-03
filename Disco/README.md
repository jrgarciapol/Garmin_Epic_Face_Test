# Epix Disco — analógica minimalista, fondo ámbar

Adaptación al Epix Pro 51 mm de un reloj de disco: fondo liso, doce marcas
discretas, dos agujas que nacen anchas en la cola y acaban en punta, un disco
central oscuro y un pivote. **Sin cifras, sin fecha y sin segundero.**

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
| `feDropShadow` | Una copia de la aguja desplazada 2-3 px en un ámbar más oscuro. Sombra dura, pero a distancia de muñeca cuela |
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

El fondo ámbar encendería el **100%** de la pantalla y el límite del AMOLED son
el **10%** de píxeles. Así que en reposo la esfera **se invierte**: fondo negro
y las mismas agujas en ámbar, con las marcas atenuadas. Medido: **4,78%** de
píxeles encendidos, de sobra. El conjunto se desplaza unos píxeles cada minuto
para repartir el desgaste.

## Colores

Están todos juntos al principio de `source/EpixWatchFaceView.mc`. Cambiar
`COLOR_BG` a `0xEEEFEE` deja la versión blanca del diseño original; el resto de
la paleta aguanta el cambio sin tocar nada más.
