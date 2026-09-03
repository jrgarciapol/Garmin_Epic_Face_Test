using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Lang as Lang;
using Toybox.Math as Math;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Calendar;
using Toybox.Application as App;

//! Esfera digital para el Epix Pro 51 mm (454 x 454, AMOLED) — variante ÓRBITA:
//! la esfera Barriecito, con sus tamaños intactos, más un orbe que recorre el
//! borde del dial cambiando de color.
//!
//! Dos presentaciones:
//!
//!   INTERACTIVA (mirando el reloj):
//!     - Orbe en el borde: 6 grados por segundo (una vuelta por minuto), con
//!       estela de 5 puntos y el tono recorriendo el espectro en cada vuelta.
//!       Se dibuja antes que los textos, así que pasa POR DETRÁS de la hora.
//!     - Día de la semana en 3 letras, arriba, en verde.
//!     - Hora H:MM / HH:MM grande (Barriecito 196), blanca. Sin cero delante
//!       en horas de un solo dígito (p. ej. 1:00, no 01:00).
//!     - Día del mes (número grande verde) + mes en 3 letras (acento azul), abajo.
//!     - Sin segundos numéricos: el orbe hace de segundero.
//!
//!   ALWAYS-ON (reposo, pantalla siempre encendida):
//!     - Sin orbe (no puede animarse y gastaría píxeles): solo la hora, con
//!       desplazamiento anti burn-in.
//!
//! Nota: el orbe solo se mueve con la pantalla despierta. Una esfera Garmin se
//! redibuja una vez por segundo en alto consumo y solo una vez por minuto en
//! reposo; no hay animación fluida posible.
class EpixWatchFaceView extends Ui.WatchFace {

    // ¿Pantalla en alto consumo (el usuario la está mirando)?
    private var mIsAwake = true;

    // Ajustes configurables por el usuario.
    private var mUse24Hour = true;
    private var mAccentColor = 0x1E9BFF; // azul (acento interactivo)
    private var mAodColor = 0x00FF00;    // verde (hora en AOD)

    // Fuentes personalizadas (Henny Penny, avance tabular en las cifras).
    private var mTimeFont;   // 155 — hora interactiva
    private var mAodFont;    // 136 — hora AOD (bajo el 10%)
    private var mNumFont;    // 78  — número del día del mes
    private var mMonFont;    // 70  — mes y día de la semana

    // Colores.
    private const COLOR_BG    = Gfx.COLOR_BLACK;
    private const COLOR_TIME  = 0xFFFFFF; // blanco puro (hora)
    private const COLOR_GREEN = 0x00FF00; // día de la semana y nº del día del mes

    // Posiciones verticales como fracción de la altura de pantalla.
    private const Y_WDAY = 0.200; // día de la semana (arriba, sobre la hora)
    private const Y_TIME = 0.500; // hora (centro)
    private const Y_DATE = 0.815; // fecha (abajo, separada de la hora)

    function initialize() {
        WatchFace.initialize();
    }

    //! Carga las fuentes personalizadas.
    function onLayout(dc) {
        mTimeFont = Ui.loadResource(Rez.Fonts.TimeBig);
        mAodFont  = Ui.loadResource(Rez.Fonts.AodBig);
        mNumFont  = Ui.loadResource(Rez.Fonts.NumBig);
        mMonFont  = Ui.loadResource(Rez.Fonts.MonBig);
        loadSettings();
    }

    function loadSettings() {
        var use24 = App.Properties.getValue("Use24Hour");
        if (use24 != null) {
            mUse24Hour = use24;
        }
        var accent = App.Properties.getValue("AccentColor");
        if (accent != null) {
            mAccentColor = accent;
        }
        var aod = App.Properties.getValue("AodColor");
        if (aod != null) {
            mAodColor = aod;
        }
    }

    function onShow() {
        loadSettings();
    }

    //! Redibujado principal.
    function onUpdate(dc) {
        loadSettings();

        dc.setColor(COLOR_BG, COLOR_BG);
        dc.clear();

        var now = Calendar.info(Time.now(), Time.FORMAT_SHORT);

        if (mIsAwake) {
            drawInteractive(dc, now);
        } else {
            drawAlwaysOn(dc, now);
        }
    }

    //! ---- Presentación INTERACTIVA ----
    private function drawInteractive(dc, now) {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;

        // El orbe va primero: así pasa POR DETRÁS de la hora al cruzarla.
        drawOrbit(dc, now.sec);

        drawWeekday(dc, now.day_of_week);

        drawBigTime(dc, cx, (h * Y_TIME).toNumber(),
                    formatTime(now.hour, now.min), mTimeFont, COLOR_TIME);

        drawDayMonth(dc, cx, (h * Y_DATE).toNumber(), now.day, now.month);
    }

    //! ---- Presentación ALWAYS-ON (solo la hora) ----
    private function drawAlwaysOn(dc, now) {
        var w = dc.getWidth();
        var h = dc.getHeight();

        // Desplazamiento de píxeles: 9 posiciones que rotan cada minuto para
        // no fijar siempre los mismos píxeles (evita el quemado del AMOLED).
        var shift = 8;
        var ox = ((now.min % 3) - 1) * shift;
        var oy = (((now.min / 3) % 3) - 1) * shift;

        drawBigTime(dc, w / 2 + ox, h / 2 + oy,
                    formatTime(now.hour, now.min), mAodFont, mAodColor);
    }

    //! Color a partir del tono (saturación máxima). h en [0,1), v el brillo.
    //! Equivale a HSV->RGB con s=1; sirve para que el orbe recorra el espectro.
    private function hueColor(h, v) {
        var i = (h * 6).toNumber();
        var f = h * 6 - i;
        var q = (1 - f) * v;
        var t = f * v;
        var r = 0; var g = 0; var b = 0;
        switch (i % 6) {
            case 0:  r = v; g = t; b = 0; break;
            case 1:  r = q; g = v; b = 0; break;
            case 2:  r = 0; g = v; b = t; break;
            case 3:  r = 0; g = q; b = v; break;
            case 4:  r = t; g = 0; b = v; break;
            default: r = v; g = 0; b = q; break;
        }
        return ((r * 255).toNumber() << 16)
             | ((g * 255).toNumber() << 8)
             |  (b * 255).toNumber();
    }

    //! Orbe que recorre el borde del dial: avanza 6 grados por segundo, o sea
    //! una vuelta completa por minuto. Su tono también da una vuelta al
    //! espectro en ese minuto, y deja 5 puntos de estela con los tonos por los
    //! que acaba de pasar.
    //!
    //! Solo se anima con la pantalla despierta: una esfera Garmin se redibuja
    //! una vez por segundo en alto consumo (y solo una por minuto en reposo).
    private function drawOrbit(dc, sec) {
        var cx = dc.getWidth() / 2;
        var cy = dc.getHeight() / 2;
        var rOrb = 211;

        // Estela: del más lejano/apagado al más cercano.
        for (var k = 5; k >= 1; k -= 1) {
            var s = ((sec - k) % 60 + 60) % 60;      // normaliza negativos
            var a = Math.toRadians(s * 6 - 90);
            var f = 1.0 - k / 6.0;
            dc.setColor(hueColor(s / 60.0, 0.30 + 0.55 * f), Gfx.COLOR_TRANSPARENT);
            dc.fillCircle((cx + rOrb * Math.cos(a)).toNumber(),
                          (cy + rOrb * Math.sin(a)).toNumber(),
                          (3 + 3 * f).toNumber());
        }

        // Orbe: halo tenue, corona y núcleo a pleno brillo.
        var ang = Math.toRadians(sec * 6 - 90);
        var x = (cx + rOrb * Math.cos(ang)).toNumber();
        var y = (cy + rOrb * Math.sin(ang)).toNumber();
        var h = sec / 60.0;
        dc.setColor(hueColor(h, 0.28), Gfx.COLOR_TRANSPARENT);
        dc.fillCircle(x, y, 13);
        dc.setColor(hueColor(h, 0.62), Gfx.COLOR_TRANSPARENT);
        dc.fillCircle(x, y, 9);
        dc.setColor(hueColor(h, 1.0), Gfx.COLOR_TRANSPARENT);
        dc.fillCircle(x, y, 6);
    }

    //! Día de la semana en 3 letras (verde), arriba, centrado.
    private function drawWeekday(dc, dow) {
        var w = dc.getWidth();
        var h = dc.getHeight();

        dc.setColor(COLOR_GREEN, Gfx.COLOR_TRANSPARENT);
        dc.drawText(w / 2, (h * Y_WDAY).toNumber(), mMonFont, dayName(dow),
                    Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
    }

    //! Dibuja la hora muy grande en tres bloques (HH · : · MM) con el ":"
    //! ceñido. Mide HH y MM por separado para admitir horas de un solo dígito.
    private function drawBigTime(dc, cx, cy, timeStr, font, color) {
        var colonIdx = timeStr.find(":");
        var hh = timeStr.substring(0, colonIdx);
        var mm = timeStr.substring(colonIdx + 1, timeStr.length());

        var wHH = dc.getTextDimensions(hh, font)[0];
        var wMM = dc.getTextDimensions(mm, font)[0];
        var wColon = dc.getTextDimensions(":", font)[0];
        var colonSlot = (wColon / 2).toNumber();
        var totalW = wHH + colonSlot + wMM;
        var x0 = cx - totalW / 2;

        dc.setColor(color, Gfx.COLOR_TRANSPARENT);
        dc.drawText(x0, cy, font, hh,
                    Gfx.TEXT_JUSTIFY_LEFT | Gfx.TEXT_JUSTIFY_VCENTER);
        dc.drawText(x0 + wHH + colonSlot / 2, cy, font, ":",
                    Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
        dc.drawText(x0 + wHH + colonSlot, cy, font, mm,
                    Gfx.TEXT_JUSTIFY_LEFT | Gfx.TEXT_JUSTIFY_VCENTER);
    }

    //! Fecha: número grande del día del mes (blanco) y, a su derecha, el mes
    //! en 3 letras (color de acento). Sin recuadro.
    private function drawDayMonth(dc, cx, cy, day, month) {
        var num = day.format("%d");
        var mon = monthName(month);

        var numW = dc.getTextDimensions(num, mNumFont)[0];
        var monW = dc.getTextDimensions(mon, mMonFont)[0];
        var gap = 14;
        var groupW = numW + gap + monW;
        var x0 = cx - groupW / 2;

        // Número del día del mes en verde.
        dc.setColor(COLOR_GREEN, Gfx.COLOR_TRANSPARENT);
        dc.drawText(x0, cy, mNumFont, num,
                    Gfx.TEXT_JUSTIFY_LEFT | Gfx.TEXT_JUSTIFY_VCENTER);

        // Mes en azul de acento.
        dc.setColor(mAccentColor, Gfx.COLOR_TRANSPARENT);
        dc.drawText(x0 + numW + gap, cy, mMonFont, mon,
                    Gfx.TEXT_JUSTIFY_LEFT | Gfx.TEXT_JUSTIFY_VCENTER);
    }

    //! Nombre corto del día (day_of_week: 1=domingo .. 7=sábado -> Day_0..6).
    private function dayName(dow) {
        var id;
        switch (dow) {
            case 1:  id = Rez.Strings.Day_0; break;
            case 2:  id = Rez.Strings.Day_1; break;
            case 3:  id = Rez.Strings.Day_2; break;
            case 4:  id = Rez.Strings.Day_3; break;
            case 5:  id = Rez.Strings.Day_4; break;
            case 6:  id = Rez.Strings.Day_5; break;
            case 7:  id = Rez.Strings.Day_6; break;
            default: id = Rez.Strings.Day_0; break;
        }
        return Ui.loadResource(id);
    }

    //! Nombre corto del mes (1 = enero), desde recursos (ES/EN).
    private function monthName(month) {
        var id;
        switch (month) {
            case 1:  id = Rez.Strings.Mon_1;  break;
            case 2:  id = Rez.Strings.Mon_2;  break;
            case 3:  id = Rez.Strings.Mon_3;  break;
            case 4:  id = Rez.Strings.Mon_4;  break;
            case 5:  id = Rez.Strings.Mon_5;  break;
            case 6:  id = Rez.Strings.Mon_6;  break;
            case 7:  id = Rez.Strings.Mon_7;  break;
            case 8:  id = Rez.Strings.Mon_8;  break;
            case 9:  id = Rez.Strings.Mon_9;  break;
            case 10: id = Rez.Strings.Mon_10; break;
            case 11: id = Rez.Strings.Mon_11; break;
            case 12: id = Rez.Strings.Mon_12; break;
            default: id = Rez.Strings.Mon_1;  break;
        }
        return Ui.loadResource(id);
    }

    //! Formatea la hora respetando 12/24 h. Sin cero delante en la hora
    //! (1:00 en vez de 01:00); los minutos sí van a dos dígitos.
    private function formatTime(hour, min) {
        var use24 = mUse24Hour and Sys.getDeviceSettings().is24Hour;
        var h = hour;
        if (!use24) {
            h = hour % 12;
            if (h == 0) {
                h = 12;
            }
        }
        return h.format("%d") + ":" + min.format("%02d");
    }

    //! Alto consumo: repintamos al instante para respuesta inmediata al gesto.
    function onExitSleep() {
        mIsAwake = true;
        Ui.requestUpdate();
    }

    //! Bajo consumo: pasamos a la presentación Always-On.
    function onEnterSleep() {
        mIsAwake = false;
        Ui.requestUpdate();
    }
}
