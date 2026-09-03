# Epix Letras — la hora en palabras

Dice la hora como la diría una persona, en castellano y en Barriecito:

| Reloj | Pantalla |
|---|---|
| 1:15  | UNA / Y / CUARTO |
| 2:45  | TRES / MENOS / CUARTO |
| 6:30  | SEIS / Y / MEDIA |
| 9:35  | DIEZ / MENOS / VEINTI / CINCO |
| 11:50 | DOCE / MENOS / DIEZ |
| 12:00 | DOCE / EN / PUNTO |

## Las tres reglas de castellano

Son la parte delicada, más que el código:

1. **Redondeo a 5 minutos.** A las 4:57 dice «CINCO MENOS CINCO», que es como
   hablamos. El precio: la esfera puede ir hasta **2,5 minutos desfasada**.
2. **Sin artículo.** «UNA Y CUARTO», no «LA UNA Y CUARTO». Ahorra una línea y
   evita tener que decidir entre «LA una» y «LAS dos».
3. **El «menos» salta de hora** a partir de y treinta y cinco. A las 9:35 se
   lee DIEZ MENOS VEINTICINCO, así que **el número que ves no es la hora en
   curso** sino la siguiente. Es correcto, pero despista los primeros días.

## Paleta «hueso y ámbar»

Pensada para AMOLED: **negro puro** de fondo (píxel apagado, contraste infinito
y cero consumo) y toda la tinta en tres niveles del mismo eje cálido.

| | Color | Por qué |
|---|---|---|
| Hora | `0xF3E7D3` hueso | Lo primero que se lee |
| Enlace | `0x6E562C` ámbar apagado | Es gramática, no información: debe ceder |
| Minutos | `0xFFB020` ámbar vivo | El dato que cambia |

## VEINTICINCO

Es casi el doble de larga que cualquier otra palabra del sistema. Si se dibuja
en una línea hay que encogerla a menos de la mitad y la esfera pierde el pulso,
así que **se parte en VEINTI / CINCO** y esos dos ratos del día usan cuatro
líneas. Es corte silábico válido (vein-ti-cin-co).

## Fuentes

Connect IQ **no sabe escalar una fuente en ejecución**: cada cuerpo de letra es
un atlas BMFont propio. Por eso hay cinco y solo cinco, generados por
`fonts-src/gen_fonts.py`:

| Id | Cuerpo | Para qué |
|---|---|---|
| `Word`  | 116 | Las dos líneas grandes cuando la frase cabe en tres |
| `WordS` | 100 | Las tres líneas grandes cuando VEINTICINCO obliga a cuatro |
| `Link`  | 64  | La línea del enlace (Y / MENOS / EN) |
| `WordA` | 64  | Always-On |
| `LinkA` | 38  | Always-On, enlace |

Solo hacen falta **17 letras** (`ACDEHIMNOPRSTUVYZ`), las que aparecen en las
veinte palabras del sistema, así que los atlas son diminutos.

## Always-On

Las palabras son mucha tinta, así que en reposo se usa el cuerpo reducido. El
caso peor (DIEZ MENOS VEINTICINCO) mide **6,39%** de píxeles encendidos, por
debajo del techo del 10%. A ese tamaño la palabra larga ya cabe entera y no
hace falta partirla. El bloque se desplaza unos píxeles cada minuto para
repartir el desgaste del AMOLED.
