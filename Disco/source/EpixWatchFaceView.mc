using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Math as Math;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Calendar;

//! Esfera ANALÓGICA minimalista para el Epix Pro 51 mm (454 x 454, AMOLED).
//! Portada de un reloj de disco: fondo ámbar liso, doce marcas discretas, dos
//! agujas afiladas que nacen anchas en la cola y acaban en punta, un disco
//! central oscuro y un pivote. Sin cifras, sin fecha y sin segundero.
//!
//!   INTERACTIVA: fondo ámbar, agujas casi negras con su sombra desplazada y
//!   un bisel más claro en una de sus mitades (es lo que les da volumen sin
//!   degradados, que Monkey C no tiene).
//!
//!   ALWAYS-ON: el fondo ámbar encendería el 100% de la pantalla y el límite
//!   son el 10% de píxeles, así que en reposo se INVIERTE: fondo negro y las
//!   mismas agujas en ámbar. Ronda el 1%, de sobra.
//!
//! El minutero se recalcula cada segundo (avanza 0,1°/s, imperceptible), así
//! que nunca va atrasado respecto al minuto en curso.
class EpixWatchFaceView extends Ui.WatchFace {

    // ¿Pantalla en alto consumo (el usuario la está mirando)?
    private var mIsAwake = true;

    // ---- Paleta ----
    private const COLOR_BG    = 0xF7C81E; // ámbar (fondo, despierto)
    private const COLOR_TICK  = 0x705200; // marcas horarias sobre el ámbar
    private const COLOR_INK   = 0x181A1A; // cuerpo de las agujas
    private const COLOR_BEVEL = 0x343536; // bisel: media aguja, más clara
    private const COLOR_SHADE = 0xC9A100; // sombra proyectada sobre el ámbar
    private const COLOR_PIVOT = 0x3A3B3C;
    private const COLOR_AOD   = 0xF7C81E; // agujas en reposo, sobre negro
    private const COLOR_AOD_T = 0x4A3A00; // marcas en reposo (tenues)

    // ---- Geometría, tomada del diseño original (SVG 70x100) y escalada ----
    private const L_MIN   = 215;  // largo del minutero desde el centro
    private const L_HOUR  = 142;  // largo del horario
    private const TAIL    = 34;   // cola por detrás del pivote
    private const W_MIN   = 11;   // ancho del minutero en el extremo de la cola
    private const W_HOUR  = 12;   // ancho del horario
    private const R_DISC  = 27;   // disco central
    private const R_PIVOT = 5;
    private const SHADE_X = 2;    // desplazamiento de la sombra
    private const SHADE_Y = 3;

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

        drawTicks(dc, cx, cy, COLOR_TICK, 5, 3);
        drawDisc(dc, cx, cy);

        var ha = hourAngle(now);
        var ma = minuteAngle(now);

        // Primero las dos sombras, luego los dos cuerpos: así la sombra del
        // minutero no cae por encima del horario.
        fillHand(dc, cx, cy, ha, L_HOUR, W_HOUR, COLOR_SHADE, SHADE_X, SHADE_Y);
        fillHand(dc, cx, cy, ma, L_MIN,  W_MIN,  COLOR_SHADE, SHADE_X, SHADE_Y);

        drawHand(dc, cx, cy, ha, L_HOUR, W_HOUR);
        drawHand(dc, cx, cy, ma, L_MIN,  W_MIN);

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

        drawTicks(dc, cx, cy, COLOR_AOD_T, 3, 2);

        var ha = hourAngle(now);
        var ma = minuteAngle(now);
        dc.setColor(COLOR_AOD, Gfx.COLOR_TRANSPARENT);
        dc.fillPolygon(handPoints(cx, cy, ha, L_HOUR, W_HOUR, 0, 0));
        dc.fillPolygon(handPoints(cx, cy, ma, L_MIN,  W_MIN,  0, 0));
    }

    //! Ángulo del horario: incluye los minutos, para que no salte de golpe.
    private function hourAngle(now) {
        return ((now.hour % 12) + now.min / 60.0) * 30.0;
    }

    //! Ángulo del minutero: incluye los segundos, aunque avance 0,1°/s.
    private function minuteAngle(now) {
        return (now.min + now.sec / 60.0) * 6.0;
    }

    //! Doce marcas horarias pegadas al borde; las de las horas en punto (12,
    //! 3, 6 y 9) más gruesas.
    private function drawTicks(dc, cx, cy, color, wQuarter, wOther) {
        var r = dc.getWidth() / 2;
        var r1 = r * 0.90;
        var r2 = r * 0.955;
        dc.setColor(color, Gfx.COLOR_TRANSPARENT);
        for (var i = 0; i < 12; i += 1) {
            var a = Math.toRadians(i * 30 - 90);
            var ca = Math.cos(a);
            var sa = Math.sin(a);
            dc.setPenWidth((i % 3 == 0) ? wQuarter : wOther);
            dc.drawLine((cx + r1 * ca).toNumber(), (cy + r1 * sa).toNumber(),
                        (cx + r2 * ca).toNumber(), (cy + r2 * sa).toNumber());
        }
        dc.setPenWidth(1);
    }

    //! Disco central. Sin degradados: siete anillos concéntricos, cada uno un
    //! poco más oscuro y ligeramente descentrado hacia abajo a la derecha, que
    //! es lo que finge la luz cayendo desde arriba a la izquierda.
    private function drawDisc(dc, cx, cy) {
        var n = 7;
        for (var i = 0; i < n; i += 1) {
            var f = i * 1.0 / (n - 1);
            var v = 0x56 + ((0x29 - 0x56) * f).toNumber();   // de 0x56 a 0x29
            dc.setColor((v << 16) | ((v + 1) << 8) | (v + 2), Gfx.COLOR_TRANSPARENT);
            var rr = (R_DISC * (1.0 - i * 0.09)).toNumber();
            var ox = (-R_DISC * 0.10 * (1 - f)).toNumber();
            var oy = (-R_DISC * 0.13 * (1 - f)).toNumber();
            dc.fillCircle(cx + ox, cy + oy, rr);
        }
    }

    //! Los tres vértices de una aguja: punta afilada, y una cola ancha que
    //! sobresale por detrás del pivote. El estrechamiento es lineal, así que
    //! con un triángulo basta.
    private function handPoints(cx, cy, deg, length, wTail, dx, dy) {
        var a = Math.toRadians(deg - 90);
        var ux = Math.cos(a);
        var uy = Math.sin(a);
        var px = -uy;                 // perpendicular al eje de la aguja
        var py = ux;
        var bx = cx - ux * TAIL;      // centro del extremo de la cola
        var by = cy - uy * TAIL;
        var hw = wTail / 2.0;
        return [
            [(cx + ux * length + dx).toNumber(), (cy + uy * length + dy).toNumber()],
            [(bx + px * hw + dx).toNumber(),     (by + py * hw + dy).toNumber()],
            [(bx - px * hw + dx).toNumber(),     (by - py * hw + dy).toNumber()]
        ];
    }

    //! Aguja de un solo color (se usa para la sombra).
    private function fillHand(dc, cx, cy, deg, length, wTail, color, dx, dy) {
        dc.setColor(color, Gfx.COLOR_TRANSPARENT);
        dc.fillPolygon(handPoints(cx, cy, deg, length, wTail, dx, dy));
    }

    //! Aguja completa: cuerpo oscuro y, encima, la mitad que da a la luz en un
    //! tono más claro. Es el sustituto del degradado del diseño original.
    private function drawHand(dc, cx, cy, deg, length, wTail) {
        var pts = handPoints(cx, cy, deg, length, wTail, 0, 0);
        dc.setColor(COLOR_INK, Gfx.COLOR_TRANSPARENT);
        dc.fillPolygon(pts);

        // Bisel: de la punta al centro de la cola, y de ahí a un solo lado.
        var a = Math.toRadians(deg - 90);
        var bx = (cx - Math.cos(a) * TAIL).toNumber();
        var by = (cy - Math.sin(a) * TAIL).toNumber();
        dc.setColor(COLOR_BEVEL, Gfx.COLOR_TRANSPARENT);
        dc.fillPolygon([pts[0], pts[1], [bx, by]]);
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
