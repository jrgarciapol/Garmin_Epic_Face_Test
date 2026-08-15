# Garmin Epic Face — Banco de pruebas de fuentes

Este repositorio contiene **8 variantes** de la esfera *Epix Digital* para el
**Garmin Epix Pro 51 mm (Gen 2)**, cada una con una fuente distinta. Cada
subcarpeta es un **proyecto Connect IQ completo e independiente**, con su
**id de app propio**, así que puedes instalarlas todas a la vez en el reloj.

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

## Cómo compilar una

Abre en VS Code la **subcarpeta** de la fuente que quieras (no la raíz) y usa
**Monkey C: Build for Device** (o F5 para el simulador). Cada carpeta tiene su
`manifest.xml`, `monkey.jungle`, `source/` y `resources/`.

Todas las fuentes son de código abierto (SIL Open Font License); su licencia
está en la carpeta `fonts-src/` de cada proyecto.
