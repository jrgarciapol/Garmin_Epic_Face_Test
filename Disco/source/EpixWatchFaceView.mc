using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Math as Math;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Calendar;

//! Esfera ANALÓGICA minimalista para el Epix Pro 51 mm (454 x 454, AMOLED).
//! Portada de un reloj de disco sobre NEGRO: doce marcas, dos agujas afiladas
//! que nacen anchas en la cola y acaban en punta, un disco central y un
//! pivote. Sin cifras, sin fecha y sin segundero.
//!
//! El diseño original tenía el fondo claro. Se invirtió porque un fondo claro
//! enciende el 100% de la pantalla: era imposible en Always-On (techo del 10%)
//! y obligaba a que la esfera pasara de blanco a negro cada vez que bajas la
//! muñeca. Con el ámbar en la tinta, reposo e interactiva son la misma imagen.
//!
//!   INTERACTIVA: agujas en ámbar con un bisel más claro en una de sus
//!   mitades, que es lo que les da volumen sin degradados (Monkey C no los
//!   tiene). Sobre negro no se dibuja sombra: sería invisible.
//!
//!   ALWAYS-ON: lo mismo, atenuado y con las agujas algo más finas de efecto.
//!
//! El minutero se recalcula cada segundo (avanza 0,1°/s, imperceptible), así
//! que nunca va atrasado respecto al minuto en curso.
class EpixWatchFaceView extends Ui.WatchFace {

    // ¿Pantalla en alto consumo (el usuario la está mirando)?
    private var mIsAwake = true;

    // ---- Paleta ----
    // Invertida respecto al diseño original: el ámbar pasa del fondo a la
    // tinta. Un fondo claro encendería el 100% de la pantalla, así que era
    // imposible en reposo y obligaba a que la esfera cambiara de blanco a
    // negro cada vez que bajas la muñeca. Así, Always-On e interactiva son la
    // misma imagen con distinto brillo, y el AMOLED gasta lo mínimo.
    private const COLOR_BG    = Gfx.COLOR_BLACK;
    private const COLOR_TICK  = 0x7A5E10; // las ocho marcas menores
    private const COLOR_TICK_Q= 0xC9A21E; // 12, 3, 6 y 9: más vivas
    private const COLOR_INK   = 0xF7C81E; // cuerpo de las agujas, ámbar
    private const COLOR_BEVEL = 0xFFE49A; // bisel: media aguja, más clara
    private const COLOR_PIVOT = 0xFFF0C4;
    private const COLOR_AOD   = 0xF7C81E; // agujas en reposo
    private const COLOR_AOD_T = 0x4A3A00; // marcas en reposo (tenues)

    // ---- Geometría, tomada del diseño original (SVG 70x100) y escalada ----
    private const L_MIN   = 215;  // largo del minutero desde el centro
    private const L_HOUR  = 142;  // largo del horario
    private const TAIL    = 34;   // cola por detrás del pivote
    private const R_DISC  = 27;   // disco central
    private const R_PIVOT = 5;

    // ---- Forma de la aguja: cuerpo ancho y punta de lanza ----
    // El diseño original estrecha en línea recta desde la cola hasta la punta,
    // así que a media aguja ya solo quedan 3-4 px y cuesta verla. Aquí la
    // aguja se mantiene casi paralela hasta el "hombro" y solo entonces se
    // afila. Se gana masa visible sin perder la punta, que es lo bonito.
    //   W_*_TAIL  ancho en el extremo de la cola
    //   W_*_BODY  ancho en el hombro
    //   K_SH_*    posición del hombro, en fracción del largo de la aguja
    private const W_MIN_TAIL  = 13;
    private const W_MIN_BODY  = 10;
    private const K_SH_MIN    = 0.66;
    private const W_HOUR_TAIL = 16;
    private const W_HOUR_BODY = 13;
    private const K_SH_HOUR   = 0.60;

    // ---- Marcas horarias ----
    // El grosor va emparejado con el de las agujas: al ensanchar el cuerpo de
    // la aguja, las marcas finas se quedaban atrás y el dial se descompensaba.
    // Al engordarlas hubo que ALARGARLAS en la misma medida: con 26 px de
    // ancho y la longitud de antes se volvían cuadrados y dejaban de leerse
    // como marcas. Ancho y largo van juntos.
    private const TICK_W_Q     = 26;    // 12, 3, 6 y 9
    private const TICK_W       = 17;    // las otras ocho
    private const TICK_W_Q_AOD = 16;    // las mismas, en reposo
    private const TICK_W_AOD   = 11;
    private const TICK_R_IN_Q  = 0.775; // las de los cuartos, más largas
    private const TICK_R_IN    = 0.855;
    private const TICK_R_OUT   = 0.955; // todas acaban a la misma altura

    function initialize() {
        WatchFace.initialize();
    }

    function onLayout(dc) {
    }

    //! Redibujado completo. Una vez por segundo despierta, una por minuto en
    //! reposo.
    function onUpdate(dc) {
        var now = Calendar.info(Time.now(), Time.FORMAT_SHORT);

        if (dc has :setAntiAlias) {
            // Sin esto, las puntas de las agujas salen en escalera.
            dc.setAntiAlias(true);
        }

        if (mIsAwake) {
            drawInteractive(dc, now);
        } else {
            drawAod(dc, now);
        }
    }

    //! ---- Presentación INTERACTIVA ----
    private function drawInteractive(dc, now) {
        var cx = dc.getWidth() / 2;
        var cy = dc.getHeight() / 2;

        dc.setColor(COLOR_BG, COLOR_BG);
        dc.clear();

        drawTicks(dc, cx, cy, COLOR_TICK_Q, COLOR_TICK, TICK_W_Q, TICK_W);
        drawDisc(dc, cx, cy);

        var ha = hourAngle(now);
        var ma = minuteAngle(now);

        // Sobre negro no hay sombra que valga: una copia desplazada de la
        // aguja en un tono más oscuro sería invisible. Lo que da volumen aquí
        // es solo el bisel.
        drawHand(dc, cx, cy, ha, L_HOUR, W_HOUR_TAIL, W_HOUR_BODY, K_SH_HOUR);
        drawHand(dc, cx, cy, ma, L_MIN,  W_MIN_TAIL,  W_MIN_BODY,  K_SH_MIN);

        dc.setColor(COLOR_PIVOT, Gfx.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, R_PIVOT);
    }

    //! ---- Presentación ALWAYS-ON ----
    //! El fondo claro es imposible aquí (encendería toda la pantalla), así que
    //! se invierte. Además desplazamos el conjunto unos píxeles cada minuto
    //! para repartir el desgaste del AMOLED.
    private function drawAod(dc, now) {
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
        dc.clear();

        var shift = 6;
        var cx = dc.getWidth() / 2 + ((now.min % 3) - 1) * shift;
        var cy = dc.getHeight() / 2 + (((now.min / 3) % 3) - 1) * shift;

        drawTicks(dc, cx, cy, COLOR_AOD_T, COLOR_AOD_T, TICK_W_Q_AOD, TICK_W_AOD);

        var ha = hourAngle(now);
        var ma = minuteAngle(now);
        dc.setColor(COLOR_AOD, Gfx.COLOR_TRANSPARENT);
        dc.fillPolygon(handPoints(cx, cy, ha, L_HOUR, W_HOUR_TAIL, W_HOUR_BODY,
                                  K_SH_HOUR, 0, 0));
        dc.fillPolygon(handPoints(cx, cy, ma, L_MIN, W_MIN_TAIL, W_MIN_BODY,
                                  K_SH_MIN, 0, 0));
    }

    //! Ángulo del horario: incluye los minutos, para que no salte de golpe.
    private function hourAngle(now) {
        return ((now.hour % 12) + now.min / 60.0) * 30.0;
    }

    //! Ángulo del minutero: incluye los segundos, aunque avance 0,1°/s.
    private function minuteAngle(now) {
        return (now.min + now.sec / 60.0) * 6.0;
    }

    //! Doce marcas horarias pegadas al borde. Las de 12, 3, 6 y 9 son más
    //! gruesas Y más largas, para que sirvan de referencia de un vistazo.
    //! El grosor va en proporción al de las agujas: si engordas unas, engorda
    //! las otras o el dial se descompensa.
    //! A estos grosores no vale `drawLine` con pincel ancho: el remate de la
    //! línea depende del dispositivo y a 26 px se nota. Cada marca es un
    //! rectángulo (`fillPolygon`), igual que las agujas.
    private function drawTicks(dc, cx, cy, colQuarter, colOther, wQuarter, wOther) {
        var r = dc.getWidth() / 2;
        var r2 = r * TICK_R_OUT;
        for (var i = 0; i < 12; i += 1) {
            var a = Math.toRadians(i * 30 - 90);
            var ux = Math.cos(a);
            var uy = Math.sin(a);
            var px = -uy;             // perpendicular al radio
            var py = ux;
            var quarter = (i % 3 == 0);
            var r1 = r * (quarter ? TICK_R_IN_Q : TICK_R_IN);
            var hw = (quarter ? wQuarter : wOther) / 2.0;
            dc.setColor(quarter ? colQuarter : colOther, Gfx.COLOR_TRANSPARENT);
            var ix = cx + ux * r1;
            var iy = cy + uy * r1;
            var ox = cx + ux * r2;
            var oy = cy + uy * r2;
            dc.fillPolygon([
                [(ix + px * hw).toNumber(), (iy + py * hw).toNumber()],
                [(ox + px * hw).toNumber(), (oy + py * hw).toNumber()],
                [(ox - px * hw).toNumber(), (oy - py * hw).toNumber()],
                [(ix - px * hw).toNumber(), (iy - py * hw).toNumber()]
            ]);
        }
    }

    //! Disco central. Sin degradados: siete anillos concéntricos, cada uno un
    //! poco más oscuro y ligeramente descentrado hacia abajo a la derecha, que
    //! es lo que finge la luz cayendo desde arriba a la izquierda.
    private function drawDisc(dc, cx, cy) {
        var n = 7;
        for (var i = 0; i < n; i += 1) {
            var f = i * 1.0 / (n - 1);
            var v = 0x5E + ((0x1C - 0x5E) * f).toNumber();   // de 0x5E a 0x1C
            dc.setColor((v << 16) | ((v + 1) << 8) | (v + 2), Gfx.COLOR_TRANSPARENT);
            var rr = (R_DISC * (1.0 - i * 0.09)).toNumber();
            var ox = (-R_DISC * 0.10 * (1 - f)).toNumber();
            var oy = (-R_DISC * 0.13 * (1 - f)).toNumber();
            dc.fillCircle(cx + ox, cy + oy, rr);
        }
    }

    //! Los cinco vértices de una aguja, en este orden:
    //!   0 punta · 1 hombro izq. · 2 cola izq. · 3 cola der. · 4 hombro der.
    //! De la cola al hombro apenas estrecha; del hombro a la punta se afila.
    private function handPoints(cx, cy, deg, length, wTail, wBody, kSh, dx, dy) {
        var a = Math.toRadians(deg - 90);
        var ux = Math.cos(a);
        var uy = Math.sin(a);
        var px = -uy;                 // perpendicular al eje de la aguja
        var py = ux;
        var bx = cx - ux * TAIL;      // centro del extremo de la cola
        var by = cy - uy * TAIL;
        var sx = cx + ux * length * kSh;   // centro del hombro
        var sy = cy + uy * length * kSh;
        var ht = wTail / 2.0;
        var hb = wBody / 2.0;
        return [
            [(cx + ux * length + dx).toNumber(), (cy + uy * length + dy).toNumber()],
            [(sx + px * hb + dx).toNumber(),     (sy + py * hb + dy).toNumber()],
            [(bx + px * ht + dx).toNumber(),     (by + py * ht + dy).toNumber()],
            [(bx - px * ht + dx).toNumber(),     (by - py * ht + dy).toNumber()],
            [(sx - px * hb + dx).toNumber(),     (sy - py * hb + dy).toNumber()]
        ];
    }

    //! Aguja completa: cuerpo oscuro y, encima, la mitad que da a la luz en un
    //! tono más claro. Es el sustituto del degradado del diseño original.
    private function drawHand(dc, cx, cy, deg, length, wTail, wBody, kSh) {
        var pts = handPoints(cx, cy, deg, length, wTail, wBody, kSh, 0, 0);
        dc.setColor(COLOR_INK, Gfx.COLOR_TRANSPARENT);
        dc.fillPolygon(pts);

        // Bisel: la mitad que va de la punta al centro de la cola por un lado.
        var a = Math.toRadians(deg - 90);
        var bx = (cx - Math.cos(a) * TAIL).toNumber();
        var by = (cy - Math.sin(a) * TAIL).toNumber();
        dc.setColor(COLOR_BEVEL, Gfx.COLOR_TRANSPARENT);
        dc.fillPolygon([pts[0], pts[1], pts[2], [bx, by]]);
    }

    //! El sistema avisa al pasar a reposo / volver de reposo.
    function onExitSleep() {
        mIsAwake = true;
        Ui.requestUpdate();
    }

    function onEnterSleep() {
        mIsAwake = false;
        Ui.requestUpdate();
    }
}
