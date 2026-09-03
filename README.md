# Garmin Epic Face — Banco de pruebas

Este repositorio contiene **10 variantes** de la esfera *Epix Digital* para el
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

## Cómo compilar una

Abre en VS Code la **subcarpeta** de la fuente que quieras (no la raíz) y usa
**Monkey C: Build for Device** (o F5 para el simulador). Cada carpeta tiene su
`manifest.xml`, `monkey.jungle`, `source/` y `resources/`.

Todas las fuentes son de código abierto (SIL Open Font License); su licencia
está en la carpeta `fonts-src/` de cada proyecto.
