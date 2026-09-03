# Garmin Epic Face — Banco de pruebas

Este repositorio contiene **14 variantes** de la esfera *Epix Digital* para el
**Garmin Epix Pro 51 mm (Gen 2)**. Cada subcarpeta es un **proyecto Connect IQ
completo e independiente**, con su **id de app propio**, así que puedes
instalarlas todas a la vez en el reloj.

## Variantes por fuente (mismo diseño, distinta tipografía)

| Carpeta | Fuente | App |
|---|---|---|
| `Bangers/`        | Bangers            | Epix Bangers |
| `Barriecito/`     | Barriecito         | Epix Barriecito |
| `CaesarDressing/` | Caesar Dressing    | Epix Caesar |
| `Honk/`           | Honk               | Epix Honk |
| `LondrinaShadow/` | Londrina Shadow    | Epix Londrina |
| `RampartOne/`     | Rampart One        | Epix Rampart |
| `Smokum/`         | Smokum             | Epix Smokum |
| `SueEllen/`       | Sue Ellen Francisco| Epix SueEllen |

Todas comparten el mismo diseño (día de la semana arriba en verde, hora grande
en blanco, día del mes verde + mes azul abajo) y usan **avance tabular** en las
cifras para que la hora no se desplace al cambiar de minuto.

## Variantes "Rosa de los vientos"

Diseño distinto: una rosa de ocho puntas de fondo, anillo de 60 marcas de
minuto, arco de progreso del minuto, hora grande en **Barriecito** y línea
`LUN 9 AGO` en Roboto Mono Bold.

| Carpeta | Estilo | App |
|---|---|---|
| `Rosa/`      | 3d — paleta apagada (norte en verde) | Epix Rosa |
| `RosaVivid/` | 3e — saturada (verde/rojo puros, textos con contorno) | Epix Rosa Vivid |

La rosa intenta orientarse con el rumbo (`Position.getInfo().heading`, permiso
`Positioning`). Ojo: una esfera Garmin **no recibe brújula continua**, así que
lo normal es que se quede **fija al norte** salvo que haya un rumbo GPS
reciente. Su **Always-On** no dibuja la rosa: solo la hora reducida, rotando
entre 5 posiciones según el minuto para repartir el desgaste del AMOLED.

## Variante con movimiento

| Carpeta | Estilo | App |
|---|---|---|
| `Orbita/` | Barriecito + orbe que recorre el borde del dial | Epix Orbita |
| `Pulso/`  | Barriecito + dos orbes que giran al ritmo del corazón | Epix Pulso |
| `PulsoXL/`| Igual que Pulso, pero los orbes **engordan** con el pulso | Epix Pulso XL |

El orbe avanza **6° por segundo** (una vuelta por minuto) dejando una estela de
5 puntos, y su **tono recorre el espectro** en cada vuelta. Se dibuja antes que
los textos, así que pasa **por detrás** de la hora. Los tamaños de la esfera
Barriecito (196 / 108 / 92) se mantienen intactos.

Solo se anima con la pantalla despierta: una esfera Garmin se redibuja una vez
por segundo en alto consumo y solo una vez por minuto en reposo. En Always-On
no se dibuja el orbe.

En **`Pulso/`** dos orbes nacen blancos del mismo punto y recorren media vuelta
en sentidos opuestos, ganando color (uno hacia rojos, otro hacia azules). La
**velocidad la marca el pulso**, y la **estela se estira** en proporción: cubre
el arco recorrido entre fotogramas, así que a 1 fps se lee como un trazo
continuo en vez de puntos sueltos. Cada punto de la estela conserva el tono que
tuvo la cabeza en ese instante.

Al encontrarse estalla un orbe de **anillos de arcoíris cuyo tamaño crece con
las pulsaciones**, sin tope: a 60 ppm es un destello discreto y a 160 ppm invade
la esfera y tapa la hora unos segundos, a propósito, para que no pase
desapercibido. Después colapsa y los orbes renacen con los sentidos invertidos.

En **`PulsoXL/`** todo eso es igual, pero además el **radio del orbe** crece con
las pulsaciones: 9 px en reposo, 29 px a 160 ppm. La estela, que se mide en
múltiplos de ese radio, pasa de hilo fino a brochazo.

Lee el pulso con el permiso `SensorHistory` (el permiso `Sensor` **no es válido
en una esfera**: solo lo admiten apps y widgets). Primero intenta el pulso en
vivo y, si el reloj no está midiendo, coge la última muestra del histórico; si
tampoco la hay, usa 60 ppm.

## Variante analógica

| Carpeta | Estilo | App |
|---|---|---|
| `Disco/` | Analógica minimalista, fondo ámbar, sin cifras | Epix Disco |

Adaptación de un reloj de disco: dos agujas afiladas, doce marcas y un disco
central. La única esfera del banco que **no usa ninguna fuente** — todo son
polígonos y círculos. Monkey C no tiene degradados ni sombras difuminadas, así
que el volumen se finge con un bisel más claro en media aguja, anillos
concéntricos en el disco y una sombra desplazada 2-3 px.

Su **Always-On invierte la esfera**: el fondo ámbar encendería el 100% de la
pantalla y el techo es el 10%, así que en reposo pasa a fondo negro con las
agujas en ámbar (4,78% de píxeles). Detalle en `Disco/README.md`.

## Cómo compilar una

Abre en VS Code la **subcarpeta** de la fuente que quieras (no la raíz) y usa
**Monkey C: Build for Device** (o F5 para el simulador). Cada carpeta tiene su
`manifest.xml`, `monkey.jungle`, `source/` y `resources/`.

Todas las fuentes son de código abierto (SIL Open Font License); su licencia
está en la carpeta `fonts-src/` de cada proyecto.
