using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Lang as Lang;
using Toybox.Math as Math;
using Toybox.Activity as Activity;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Calendar;
using Toybox.Application as App;

//! Esfera digital para el Epix Pro 51 mm (454 x 454, AMOLED) — variante PULSO:
//! la esfera Barriecito, con sus tamaños intactos, más dos orbes que giran al
//! ritmo del corazón.
//!
//!   INTERACTIVA (mirando el reloj):
//!     - Dos orbes nacen del mismo punto, blancos, y recorren media vuelta en
//!       sentidos opuestos. Al alejarse ganan color: uno hacia los rojos y el
//!       otro hacia los azules.
//!     - La VELOCIDAD la marca el pulso (grados por latido fijos), así que a
//!       más pulsaciones, más rápido giran y antes chocan.
//!     - La ESTELA se estira en proporción a esa velocidad y cada punto lleva
//!       el tono que tuvo la cabeza en ese instante: es el registro del viaje.
//!       Además tapa los saltos del refresco de 1 fps.
//!     - Al encontrarse estalla un orbe de anillos de arcoíris cuyo TAMAÑO es
//!       proporcional al pulso: a 60 ppm es un destello discreto; a 160 ppm
//!       invade la esfera y tapa la hora unos segundos, a propósito, para que
//!       no puedas ignorarlo.
//!     - Después colapsa a nada y renacen dos orbes en el punto del choque,
//!       cada uno con el sentido contrario al que traía.
//!     - Día de la semana arriba, hora grande (Barriecito 196) y fecha abajo.
//!
//!   ALWAYS-ON (reposo): sin orbes (no pueden animarse y gastarían píxeles),
//!   solo la hora con desplazamiento anti burn-in.
//!
//! Nota: los orbes solo se mueven con la pantalla despierta. Una esfera Garmin
//! se redibuja una vez por segundo en alto consumo y solo una por minuto en
//! reposo; no hay animación fluida posible.
class EpixWatchFaceView extends Ui.WatchFace {

    // ¿Pantalla en alto consumo (el usuario la está mirando)?
    private var mIsAwake = true;

    //! Latidos acumulados: es el "reloj" de la animación. Avanza pulso/60 en
    //! cada refresco interactivo (uno por segundo), así que el movimiento va
    //! literalmente al ritmo del corazón.
    private var mBeats = 0.0;

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

    // --- Parámetros de los orbes ---
    private const R_ORB = 211;          // radio de la órbita (borde del dial)
    private const R_DOT = 11;           // radio del orbe
    private const DEG_PER_BEAT = 12.0;  // velocidad: grados que avanza por latido
    private const TRAVEL_BEATS = 15.0;  // 180 / DEG_PER_BEAT = media vuelta
    private const MERGE_BEATS  = 3.0;   // duración del choque + colapso
    private const CYCLE_BEATS  = 18.0;  // TRAVEL + MERGE
    private const TRAIL_DOTS   = 8;     // puntos de estela (ajustado al
                                        // presupuesto de tiempo de onUpdate)
    private const TRAIL_SECS   = 1.5;   // segundos de pasado que cubre la estela

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

        // Un refresco interactivo = un segundo => avanzamos pulso/60 latidos.
        var hr = heartRate();
        mBeats += hr / 60.0;
        // Envolvemos en dos ciclos para no crecer sin fin, conservando la
        // paridad (que es la que decide el sentido de giro).
        if (mBeats > 2 * CYCLE_BEATS) {
            mBeats -= 2 * CYCLE_BEATS;
        }
        // Los orbes van primero: así pasan POR DETRÁS de los textos.
        drawPulse(dc, hr);

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

    //! Pulsaciones actuales. Si el sensor no da dato (muñeca suelta, reloj
    //! recién puesto), caemos a 60 para que la animación siga viva.
    private function heartRate() {
        var info = Activity.getActivityInfo();
        if (info != null && info.currentHeartRate != null) {
            return info.currentHeartRate;
        }
        return 60;
    }

    //! HSV -> RGB. Necesitamos saturación variable porque los orbes nacen
    //! blancos (s=0) y van ganando color (s=1).
    private function hsvColor(h, s, v) {
        var hh = h - h.toNumber();
        if (hh < 0) { hh += 1.0; }
        var i = (hh * 6).toNumber();
        var f = hh * 6 - i;
        var p = v * (1 - s);
        var q = v * (1 - f * s);
        var t = v * (1 - (1 - f) * s);
        var r = v; var g = t; var b = p;
        if (i == 1)      { r = q; g = v; b = p; }
        else if (i == 2) { r = p; g = v; b = t; }
        else if (i == 3) { r = p; g = q; b = v; }
        else if (i == 4) { r = t; g = p; b = v; }
        else if (i == 5) { r = v; g = p; b = q; }
        return ((r * 255).toNumber() << 16)
             | ((g * 255).toNumber() << 8)
             |  (b * 255).toNumber();
    }

    //! Color de un orbe según lo lejos que esté de su nacimiento.
    //! t = 0 recién nacido (blanco), t = 1 a punto de chocar (color pleno).
    //! warm = true deriva a rojos; false, a azules.
    private function orbColor(t, warm, v) {
        var tt = t;
        if (tt < 0.0) { tt = 0.0; }
        if (tt > 1.0) { tt = 1.0; }
        return hsvColor(warm ? 0.0 : 0.58, Math.pow(tt, 0.7), v);
    }

    //! Radio del estallido: proporcional al pulso, sin tope útil. A 160 ppm
    //! cubre el dial a propósito.
    private function mergeRadius(hr) {
        var r = 45.0 + (hr - 60.0) * 1.55;
        if (r < 18.0)  { r = 18.0; }
        if (r > 250.0) { r = 250.0; }
        return r;
    }

    //! Coordenada X/Y sobre la órbita. 0 grados = arriba, sentido horario.
    private function orbX(cx, deg) {
        return (cx + R_ORB * Math.cos(Math.toRadians(deg - 90))).toNumber();
    }
    private function orbY(cy, deg) {
        return (cy + R_ORB * Math.sin(Math.toRadians(deg - 90))).toNumber();
    }

    //! Cabeza del orbe: halo, cuerpo y núcleo.
    private function drawHead(dc, cx, cy, deg, t, warm) {
        var x = orbX(cx, deg);
        var y = orbY(cy, deg);
        dc.setColor(orbColor(t, warm, 0.25), Gfx.COLOR_TRANSPARENT);
        dc.fillCircle(x, y, (R_DOT * 1.9).toNumber());
        dc.setColor(orbColor(t, warm, 0.60), Gfx.COLOR_TRANSPARENT);
        dc.fillCircle(x, y, (R_DOT * 1.4).toNumber());
        dc.setColor(orbColor(t, warm, 1.0), Gfx.COLOR_TRANSPARENT);
        dc.fillCircle(x, y, R_DOT);
    }

    //! Estallido del choque: anillos concéntricos de arcoíris, de fuera adentro.
    private function drawBurst(dc, cx, cy, deg, radius, fade) {
        if (radius < 1) { return; }
        var x = orbX(cx, deg);
        var y = orbY(cy, deg);
        var n = 7;
        for (var i = 0; i < n; i += 1) {
            var rr = (radius * (1.0 - i * 1.0 / n)).toNumber();
            if (rr < 1) { continue; }
            dc.setColor(hsvColor(i * 1.0 / n, 1.0, fade), Gfx.COLOR_TRANSPARENT);
            dc.fillCircle(x, y, rr);
        }
    }

    //! Los dos orbes: viaje en sentidos opuestos, choque y colapso.
    private function drawPulse(dc, hr) {
        var cx = dc.getWidth() / 2;
        var cy = dc.getHeight() / 2;
        var bps = hr / 60.0;

        var cyc = (mBeats / CYCLE_BEATS).toNumber();
        var p = mBeats - cyc * CYCLE_BEATS;
        // El sentido se invierte en cada ciclo, y el punto de partida es el
        // del choque anterior: así alternan arriba <-> abajo.
        var s = (cyc % 2 == 0) ? 1 : -1;
        var start = (cyc % 2 == 0) ? 0.0 : 180.0;

        if (p < TRAVEL_BEATS) {
            var t = p / TRAVEL_BEATS;
            var adv = DEG_PER_BEAT * p;
            // La estela cubre lo recorrido en los últimos TRAIL_SECS: cuanto
            // más rápido (más pulso), más larga. Nunca antes del nacimiento.
            var span = DEG_PER_BEAT * bps * TRAIL_SECS;
            if (span > adv) { span = adv; }

            for (var i = TRAIL_DOTS; i >= 1; i -= 1) {
                var f = i * 1.0 / TRAIL_DOTS;
                var back = span * f;
                var tk = t - back / 180.0;          // avance en aquel instante
                var rr = (R_DOT * (0.30 + 0.55 * (1 - f))).toNumber();
                var dim = 0.25 + 0.55 * (1 - f);
                if (rr >= 1) {
                    var d1 = start + s * (adv - back);
                    var d2 = start - s * (adv - back);
                    dc.setColor(orbColor(tk, true, dim), Gfx.COLOR_TRANSPARENT);
                    dc.fillCircle(orbX(cx, d1), orbY(cy, d1), rr);
                    dc.setColor(orbColor(tk, false, dim), Gfx.COLOR_TRANSPARENT);
                    dc.fillCircle(orbX(cx, d2), orbY(cy, d2), rr);
                }
            }
            drawHead(dc, cx, cy, start + s * adv, t, true);
            drawHead(dc, cx, cy, start - s * adv, t, false);
        } else {
            var m = (p - TRAVEL_BEATS) / MERGE_BEATS;
            var meet = start + 180.0;
            var bigR = mergeRadius(hr);
            var radius;
            var fade = 1.0;
            if (m < 0.28) {                        // impacto: crece de golpe
                radius = R_DOT + (bigR - R_DOT) * (m / 0.28);
            } else {                               // colapso hasta desaparecer
                var q = (m - 0.28) / 0.72;
                radius = bigR * Math.pow(1.0 - q, 1.6);
                fade = 1.0 - 0.5 * q;
            }
            drawBurst(dc, cx, cy, meet, radius, fade);
        }
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
