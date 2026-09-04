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
| Enlace | `0xE07B18` ámbar quemado | «Y» frente a «MENOS» son **media hora** |
| Minutos | `0xFFB020` ámbar vivo | El dato que cambia |

**Todas las líneas van al mismo cuerpo**, enlace incluido. Empezó siendo ámbar
apagado y más pequeño, tratándolo como gramática de relleno. Es un error: «Y»
frente a «MENOS» cambia la hora en treinta minutos, o sea que es la palabra
**más informativa** de las tres, y tenerla atenuada y pequeña la convertía
justo en la menos legible.

El enlace se separa del ámbar de los minutos **por el tono**, no por estar
apagado: bajarle el brillo para diferenciarlo es justo lo que no funcionaba. Los
tres caen en el mismo eje cálido: hueso → ámbar quemado → ámbar vivo. Si
quisieras más separación sin salirte de la gama, `0xFF8A3D` (naranja tostado) o
`0xFF6F5C` (coral) son los escalones siguientes.

## VEINTICINCO

Es casi el doble de larga que cualquier otra palabra del sistema. Si se dibuja
en una línea hay que encogerla a menos de la mitad y la esfera pierde el pulso,
así que **se parte en VEINTI / CINCO** y esos dos ratos del día usan cuatro
líneas. Es corte silábico válido (vein-ti-cin-co).

## Fuentes

Connect IQ **no sabe escalar una fuente en ejecución**: cada cuerpo de letra es
un atlas BMFont propio. Por eso hay tres y solo tres, generados por
`fonts-src/gen_fonts.py`:

| Id | Cuerpo | Para qué |
|---|---|---|
| `Word`  | 116 | Las **tres** líneas cuando la frase cabe en tres |
| `WordS` | 100 | Las **cuatro** líneas cuando VEINTICINCO obliga a cuatro |
| `WordA` | 68  | Always-On, las tres o cuatro líneas |

Solo hacen falta **17 letras** (`ACDEHIMNOPRSTUVYZ`), las que aparecen en las
veinte palabras del sistema, así que los atlas son diminutos.

## Always-On

Igual que la interactiva, todas las líneas al mismo cuerpo. Igualadas a 68, el
caso peor es `3:35` (CUATRO MENOS VEINTI CINCO) y mide **9,28%**, por
debajo del techo del **10%** de píxeles encendidos.

Para poder subir el cuerpo hasta ahí, en reposo **también se parte
VEINTICINCO**: con la palabra entera el ancho manda y hay que quedarse mucho
más pequeño. El bloque se desplaza unos píxeles cada minuto para repartir el
desgaste del AMOLED.

Al medir el presupuesto hay que **barrer las doce horas**, no una sola: DOS
pinta la mitad de tinta que CUATRO, así que quedarse en la primera hora del día
da un número optimista y falso.
