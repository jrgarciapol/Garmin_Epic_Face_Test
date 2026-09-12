# Reloj de sobremesa / pared

Rama nueva del proyecto: en vez de esferas para el Garmin, **relojes creativos
para una pantalla grande** (monitor o televisor) movidos por una Raspberry Pi.

Lo que cambia respecto al reloj:

| | Garmin Epix (AMOLED) | Pantalla grande (IPS) |
|---|---|---|
| Refresco | **1 fotograma por segundo** | 60 fps, animación de verdad |
| Píxeles encendidos | techo del 10% en reposo | sin límite |
| Fondo claro | imposible en Always-On | **gratis**: la retro está encendida igual |
| Quemado | hay que desplazar el dibujo cada minuto | no aplica en LCD |

O sea que **la baraja de restricciones se invierte**. La estética de papel y
tinta, que en el reloj era inviable, aquí es justo la que toca.

## Estado

Arrancando. `modelos/` espera el FBX de partida.
