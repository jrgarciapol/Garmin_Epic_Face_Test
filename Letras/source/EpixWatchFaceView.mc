using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Calendar;

//! Esfera para el Epix Pro 51 mm (454 x 454, AMOLED) que dice la hora EN
//! PALABRAS, en castellano, como la diría una persona:
//!
//!     1:15  ->  UNA / Y / CUARTO
//!     2:45  ->  TRES / MENOS / CUARTO
//!     9:35  ->  DIEZ / MENOS / VEINTI / CINCO
//!    12:00  ->  DOCE / EN / PUNTO
//!
//! Tres reglas de castellano, que son la parte delicada:
//!
//!   1. REDONDEO A 5 MINUTOS. A las 4:57 dice "CINCO MENOS CINCO", que es como
//!      hablamos. El precio: la esfera puede ir hasta 2,5 minutos desfasada.
//!   2. SIN ARTÍCULO. "UNA Y CUARTO", no "LA UNA Y CUARTO". Ahorra una línea y
//!      evita tener que decidir entre "LA una" y "LAS dos".
//!   3. EL "MENOS" SALTA DE HORA a partir de y treinta y cinco: a las 9:35 se
//!      lee DIEZ MENOS VEINTICINCO. Así que la hora que aparece en pantalla no
//!      es la hora en curso, sino la siguiente. Es correcto, pero despista los
//!      primeros días.
//!
//! Reparto: hora arriba en hueso, enlace y minutos en ámbar vivo. Fondo negro
//! puro, que en AMOLED es píxel apagado.
//!
//! VEINTICINCO es casi el doble de larga que cualquier otra palabra, así que
//! se parte en VEINTI / CINCO y esos dos ratos del día usan cuatro líneas. Sin
//! partirla habría que encogerla a la mitad y la esfera perdería el pulso.
class EpixWatchFaceView extends Ui.WatchFace {

    private var mIsAwake = true;

    // ---- Paleta "hueso y ámbar" ----
    // Pensada para AMOLED: negro puro de fondo (píxel apagado, contraste
    // infinito, cero consumo) y la tinta en el mismo eje cálido.
    // El enlace iba apagado y más pequeño, tratándolo como gramática de
    // relleno. Error: "Y" frente a "MENOS" son MEDIA HORA de diferencia, así
    // que es la palabra más informativa de las tres.
    //
    // Va al MISMO CUERPO que las otras líneas y en un ámbar quemado: se
    // separa del ámbar de los minutos por el TONO, no por estar apagado.
    // Bajarle el brillo para diferenciarlo es justo lo que no funcionaba.
    //
    // Está en el máximo de brillo que admite ese tono sin desaturar: subir de
    // aquí obliga a tirar hacia el blanco, y entonces empieza a competir con
    // el hueso de la hora. Los escalones siguientes serían 0xFF9833 y
    // 0xFFA54D, ya rebajando saturación.
    private const COLOR_BG   = Gfx.COLOR_BLACK;
    private const COLOR_HOUR = 0xF3E7D3; // hueso
    private const COLOR_LINK = 0xFF8C1B; // ámbar quemado, a tope de brillo
    private const COLOR_MIN  = 0xFFB020; // ámbar vivo

    // ---- Reparto vertical, en fracción de la altura ----
    private const Y3_HOUR = 0.240;   // frase de 3 líneas
    private const Y3_LINK = 0.500;
    private const Y3_MIN  = 0.760;

    private const Y4_HOUR = 0.175;   // frase de 4 líneas (VEINTICINCO)
    private const Y4_LINK = 0.385;
    private const Y4_MIN1 = 0.605;
    private const Y4_MIN2 = 0.825;

    // Always-On: el mismo reparto, con el cuerpo llevado al máximo que permite
    // el presupuesto de píxeles (ver drawAod).
    private const YA3_HOUR = 0.255;
    private const YA3_LINK = 0.500;
    private const YA3_MIN  = 0.745;

    private const YA4_HOUR = 0.175;
    private const YA4_LINK = 0.385;
    private const YA4_MIN1 = 0.605;
    private const YA4_MIN2 = 0.825;

    // Fuentes (Connect IQ no escala en ejecución: un cuerpo, un atlas).
    // TODAS las líneas de un mismo reparto van al mismo cuerpo, enlace
    // incluido: teniéndolo más pequeño, la palabra más informativa de la frase
    // era además la menos legible.
    private var mWord;    // 116 — las tres líneas del reparto de 3
    private var mWordS;   // 100 — las cuatro líneas del reparto de 4
    private var mWordA;   // 68  — Always-On, LAS TRES líneas

    function initialize() {
        WatchFace.initialize();
    }

    function onLayout(dc) {
        mWord  = Ui.loadResource(Rez.Fonts.Word);
        mWordS = Ui.loadResource(Rez.Fonts.WordS);
        mWordA = Ui.loadResource(Rez.Fonts.WordA);
    }

    function onUpdate(dc) {
        var now = Calendar.info(Time.now(), Time.FORMAT_SHORT);

        dc.setColor(COLOR_BG, COLOR_BG);
        dc.clear();

        if (mIsAwake) {
            drawInteractive(dc, now);
        } else {
            drawAod(dc, now);
        }
    }

    //! ---- Presentación INTERACTIVA ----
    private function drawInteractive(dc, now) {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;

        var m = roundedMinute(now.min);
        var hourWord = hourName(now.hour, m);
        var link = linkWord(m);
        var mins = minuteName(m);

        if (mins.equals("VEINTICINCO")) {
            // Cuatro líneas: la palabra larga partida por sílabas.
            line(dc, cx, h, Y4_HOUR, hourWord, mWordS, COLOR_HOUR);
            line(dc, cx, h, Y4_LINK, link,     mWordS, COLOR_LINK);
            line(dc, cx, h, Y4_MIN1, "VEINTI", mWordS, COLOR_MIN);
            line(dc, cx, h, Y4_MIN2, "CINCO",  mWordS, COLOR_MIN);
        } else {
            line(dc, cx, h, Y3_HOUR, hourWord, mWord, COLOR_HOUR);
            line(dc, cx, h, Y3_LINK, link,     mWord, COLOR_LINK);
            line(dc, cx, h, Y3_MIN,  mins,     mWord, COLOR_MIN);
        }
    }

    //! ---- Presentación ALWAYS-ON ----
    //! LAS TRES LÍNEAS VAN AL MISMO CUERPO. Tenerlas a distinto tamaño hacía
    //! que el enlace, que es la palabra más informativa, fuera además la menos
    //! legible. Igualadas a 68, el caso peor (CUATRO MENOS VEINTI CINCO) mide
    //! 9,31%, por debajo del techo del 10% de píxeles encendidos.
    //! Para poder subir el cuerpo hasta ahí, aquí también se parte
    //! VEINTICINCO en dos líneas; con la palabra entera manda el ancho y hay
    //! que quedarse bastante más pequeño.
    //! El bloque se desplaza unos píxeles cada minuto para repartir el
    //! desgaste del AMOLED.
    private function drawAod(dc, now) {
        var w = dc.getWidth();
        var h = dc.getHeight();

        var shift = 7;
        var cx = w / 2 + ((now.min % 3) - 1) * shift;
        var dy = (((now.min / 3) % 3) - 1) * shift;

        var m = roundedMinute(now.min);
        var hourWord = hourName(now.hour, m);
        var link = linkWord(m);
        var mins = minuteName(m);

        if (mins.equals("VEINTICINCO")) {
            drawAt(dc, cx, (h * YA4_HOUR).toNumber() + dy, hourWord, mWordA, COLOR_HOUR);
            drawAt(dc, cx, (h * YA4_LINK).toNumber() + dy, link,     mWordA, COLOR_LINK);
            drawAt(dc, cx, (h * YA4_MIN1).toNumber() + dy, "VEINTI", mWordA, COLOR_MIN);
            drawAt(dc, cx, (h * YA4_MIN2).toNumber() + dy, "CINCO",  mWordA, COLOR_MIN);
        } else {
            drawAt(dc, cx, (h * YA3_HOUR).toNumber() + dy, hourWord, mWordA, COLOR_HOUR);
            drawAt(dc, cx, (h * YA3_LINK).toNumber() + dy, link,     mWordA, COLOR_LINK);
            drawAt(dc, cx, (h * YA3_MIN).toNumber() + dy,  mins,     mWordA, COLOR_MIN);
        }
    }

    private function line(dc, cx, h, yf, txt, font, color) {
        drawAt(dc, cx, (h * yf).toNumber(), txt, font, color);
    }

    private function drawAt(dc, x, y, txt, font, color) {
        dc.setColor(color, Gfx.COLOR_TRANSPARENT);
        dc.drawText(x, y, font, txt,
                    Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
    }

    //! Minuto redondeado al múltiplo de 5 más cercano. Devuelve 0..55, y 60
    //! cuando toca subir de hora (4:58 -> "CINCO EN PUNTO").
    private function roundedMinute(min) {
        return ((min + 2) / 5) * 5;
    }

    //! Nombre de la hora que hay que decir. Ojo: a partir de "menos" (m >= 35)
    //! y al redondear a en punto (m == 60), es la hora SIGUIENTE.
    private function hourName(hour, m) {
        var h = hour;
        if (m >= 35) { h += 1; }
        return mHours[h % 12];
    }

    //! La palabra de enlace: EN (punto), Y (primera media) o MENOS (segunda).
    private function linkWord(m) {
        if (m == 0 || m == 60) { return "EN"; }
        if (m <= 30) { return "Y"; }
        return "MENOS";
    }

    //! La cantidad de minutos, ya expresada como se dice.
    private function minuteName(m) {
        if (m == 0 || m == 60) { return "PUNTO"; }
        if (m == 30) { return "MEDIA"; }
        if (m == 15 || m == 45) { return "CUARTO"; }
        // El resto son simétricos respecto a la media: 5/55, 10/50, 20/40,
        // 25/35 dicen la misma cantidad, una con "y" y otra con "menos".
        var n = (m <= 30) ? m : 60 - m;
        if (n == 5)  { return "CINCO"; }
        if (n == 10) { return "DIEZ"; }
        if (n == 20) { return "VEINTE"; }
        return "VEINTICINCO";   // n == 25
    }

    //! 0 = las doce. El resto, su nombre. Va como `var` y no como `const`
    //! porque una constante de Monkey C tiene que ser un valor simple.
    private var mHours = ["DOCE", "UNA", "DOS", "TRES", "CUATRO", "CINCO",
                          "SEIS", "SIETE", "OCHO", "NUEVE", "DIEZ", "ONCE"];

    function onExitSleep() {
        mIsAwake = true;
        Ui.requestUpdate();
    }

    function onEnterSleep() {
        mIsAwake = false;
        Ui.requestUpdate();
    }
}
