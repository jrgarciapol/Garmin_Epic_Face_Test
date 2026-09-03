# Epix Disco — analógica minimalista, fondo ámbar

Adaptación al Epix Pro 51 mm de un reloj de disco: fondo liso, doce marcas
discretas, dos agujas que nacen anchas en la cola y acaban en punta, un disco
central oscuro y un pivote. **Sin cifras, sin fecha y sin segundero.**

Es la única esfera del banco de pruebas que **no usa ninguna fuente**: todo son
polígonos y círculos.

## Qué se pudo traer del diseño original y qué no

| Del SVG original | En Monkey C |
|---|---|
| Agujas afiladas | Un triángulo (`fillPolygon`) por aguja: la cola ancha y el estrechamiento lineal hasta la punta salen solos |
| Bisel de la aguja | Un segundo triángulo más claro sobre la mitad que da a la luz |
| `linearGradient` en las agujas | **No existe.** Sustituido por el bisel de arriba |
| `radialGradient` del disco | Siete círculos concéntricos, cada uno más oscuro y ligeramente descentrado. La banda es de 3 px y no se aprecia |
| `radialGradient` del fondo | **No existe** y por anillos se ven escalones: fondo plano |
| `feDropShadow` | Una copia de la aguja desplazada 2-3 px en un ámbar más oscuro. Sombra dura, pero a distancia de muñeca cuela |
| Minutero con milisegundos | El minutero se recalcula cada segundo. Avanza 0,1°/s: imperceptible |

Las puntas finas dependen de **`dc.setAntiAlias(true)`**, que el Epix Pro
admite. Sin eso saldrían en escalera.

## Always-On

El fondo ámbar encendería el **100%** de la pantalla y el límite del AMOLED son
el **10%** de píxeles. Así que en reposo la esfera **se invierte**: fondo negro
y las mismas agujas en ámbar, con las marcas atenuadas. Medido: **1,59%** de
píxeles encendidos, de sobra. El conjunto se desplaza unos píxeles cada minuto
para repartir el desgaste.

## Colores

Están todos juntos al principio de `source/EpixWatchFaceView.mc`. Cambiar
`COLOR_BG` a `0xEEEFEE` deja la versión blanca del diseño original; el resto de
la paleta aguanta el cambio sin tocar nada más.
