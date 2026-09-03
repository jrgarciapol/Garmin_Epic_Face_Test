import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Math;
import Toybox.Position;
import Toybox.WatchUi;

// Esfera "Rosa de los vientos" para Garmin Epix Pro 51 mm (454 x 454).
// Adaptada del handoff de diseño (layouts 3d / 3e).
//   VIVID = false -> 3d Rosa apagada (verdes/azules oscuros)
//   VIVID = true  -> 3e Rosa saturada (verde/rojo puros, textos con contorno)
const VIVID = false;

// Paleta apagada (3d)
const C_WHITE = 0xF5F5F2;
const C_GREEN = 0x3FD98C;
const C_BLUE  = 0x4C9BF0;
const C_TICK  = 0x2C2E33;
const C_TICK5 = 0x5A5D66;
const C_TRACK = 0x1A1C20;
// Paleta saturada (3e)
const C_VGREEN = 0x00FF00;
const C_VRED   = 0xFF0000;
const C_VBLUE  = 0x1E9BFF;

class EpixWatchFaceView extends WatchUi.WatchFace {
    private var _fTime, _fAod, _fDate;
    private var _lowPower = false;

    function initialize() { WatchFace.initialize(); }

    function onLayout(dc as Dc) as Void {
        _fTime = WatchUi.loadResource(Rez.Fonts.TimeBig);   // Barriecito grande
        _fAod  = WatchUi.loadResource(Rez.Fonts.AodBig);    // Barriecito reducida
        _fDate = WatchUi.loadResource(Rez.Fonts.MonBig);    // Roboto Mono Bold
    }

    function onEnterSleep() as Void { _lowPower = true;  WatchUi.requestUpdate(); }
    function onExitSleep()  as Void { _lowPower = false; WatchUi.requestUpdate(); }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        var now = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        if (_lowPower) { drawAod(dc, now); } else { drawRose(dc, now); }
    }

    // ---------- textos ----------
    private function hourString(now) as String {
        var h = now.hour;
        if (!System.getDeviceSettings().is24Hour) {
            h = h % 12; if (h == 0) { h = 12; }
        }
        return h.format("%d");   // sin cero delante
    }

    private function weekdayString(now) as String {
        var id;
        switch (now.day_of_week) {
            case 1:  id = Rez.Strings.Day_0; break;
            case 2:  id = Rez.Strings.Day_1; break;
            case 3:  id = Rez.Strings.Day_2; break;
            case 4:  id = Rez.Strings.Day_3; break;
            case 5:  id = Rez.Strings.Day_4; break;
            case 6:  id = Rez.Strings.Day_5; break;
            case 7:  id = Rez.Strings.Day_6; break;
            default: id = Rez.Strings.Day_0; break;
        }
        return WatchUi.loadResource(id) as String;
    }

    private function monthString(now) as String {
        var id;
        switch (now.month) {
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
        return WatchUi.loadResource(id) as String;
    }

    // Hora en tres piezas con hueco fijo para los dos puntos: no se desplaza
    // al cambiar de minuto (las cifras ya son de avance tabular en la BMFont).
    private function bigTime(dc as Dc, cx, cy, hh, mm, color, font) as Void {
        var wHH = dc.getTextWidthInPixels(hh, font);
        var wMM = dc.getTextWidthInPixels(mm, font);
        var cs  = dc.getTextWidthInPixels(":", font) / 2;
        var x0  = cx - (wHH + cs * 2 + wMM) / 2;
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x0, cy, font, hh, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(x0 + wHH + cs, cy, font, ":", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(x0 + wHH + cs * 2, cy, font, mm, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // Texto con contorno negro (4 pasadas desplazadas + color encima).
    // Imprescindible sobre verde/rojo saturados.
    private function outlinedText(dc as Dc, x, y, font, txt, color, outline) as Void {
        var just = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
        if (outline) {
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
            dc.drawText(x - 2, y, font, txt, just);
            dc.drawText(x + 2, y, font, txt, just);
            dc.drawText(x, y - 2, font, txt, just);
            dc.drawText(x, y + 2, font, txt, just);
        }
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, font, txt, just);
    }

    // ---------- decoración ----------
    private function minuteTicks(dc as Dc, cx, cy, rOut) as Void {
        for (var i = 0; i < 60; i += 1) {
            var major = (i % 5) == 0;
            var len = major ? 15 : 9;
            dc.setColor(major ? C_TICK5 : C_TICK, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(major ? 3 : 2);
            var a = Math.toRadians(i * 6 - 90);
            var ca = Math.cos(a); var sa = Math.sin(a);
            dc.drawLine(cx + (rOut - len) * ca, cy + (rOut - len) * sa,
                        cx + rOut * ca, cy + rOut * sa);
        }
        dc.setPenWidth(1);
    }

    private function progressArc(dc as Dc, cx, cy, r, frac, color, pen) as Void {
        dc.setPenWidth(pen);
        dc.setColor(C_TRACK, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(cx, cy, r);
        if (frac > 0) {
            var end = 90 - 360 * frac;
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            dc.drawArc(cx, cy, r, Graphics.ARC_CLOCKWISE, 90, end);
        }
        dc.setPenWidth(1);
    }

    // Rumbo en radianes (0 = norte). En una esfera Garmin no hay brújula
    // continua: si no hay dato reciente devolvemos 0.0 (rosa mirando al norte).
    private function heading() as Float {
        if (Position has :getInfo) {
            var info = Position.getInfo();
            if (info != null && info.heading != null) { return info.heading; }
        }
        return 0.0;
    }

    // Rosa de 8 puntas girada "rot" radianes. Cada punta es un polígono
    // independiente (uno que abarque dos diagonales se autointersecta).
    private function windRose(dc as Dc, cx, cy, r, rot, vivid) as Void {
        var rIn = r * 0.085;
        for (var i = 0; i < 8; i += 1) {
            var cardinal = (i % 2) == 0;
            var len = cardinal ? r * 0.90 : r * 0.72;
            var a  = rot + Math.toRadians(i * 45);
            var aL = a - Math.toRadians(4.6);
            var aR = a + Math.toRadians(4.6);
            var col = cardinal ? 0x132A20 : 0x0F2028;
            if (i == 0 && !vivid) { col = C_GREEN; }      // punta norte destacada
            if (vivid) { col = cardinal ? C_VGREEN : C_VRED; }
            dc.setColor(col, Graphics.COLOR_TRANSPARENT);
            dc.fillPolygon([
                [cx + len * Math.sin(a),  cy - len * Math.cos(a)],
                [cx + rIn * Math.sin(aR), cy - rIn * Math.cos(aR)],
                [cx - rIn * Math.sin(a),  cy + rIn * Math.cos(a)],
                [cx + rIn * Math.sin(aL), cy - rIn * Math.cos(aL)]
            ]);
        }
        dc.setPenWidth(2);
        dc.setColor(vivid ? 0x005B00 : 0x1B3A2C, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(cx, cy, r * 0.66);
        dc.drawCircle(cx, cy, r * 0.32);
        dc.setPenWidth(1);
        var labels = ["N", "E", "S", "O"];
        for (var k = 0; k < 4; k += 1) {
            var ak = rot + Math.toRadians(k * 90);
            var lx = cx + (r - 24) * Math.sin(ak);
            var ly = cy - (r - 24) * Math.cos(ak);
            outlinedText(dc, lx, ly, Graphics.FONT_LARGE, labels[k],
                         vivid ? C_VBLUE : C_BLUE, vivid);
        }
    }

    // ---------- esfera interactiva ----------
    private function drawRose(dc as Dc, now) as Void {
        var w = dc.getWidth(); var h = dc.getHeight();
        var cx = w / 2; var cy = h / 2;
        var hh = hourString(now);
        var mm = now.min.format("%02d");
        var line = weekdayString(now) + " " + now.day.format("%d") + " " + monthString(now);

        windRose(dc, cx, cy, w / 2 - 24, -heading(), VIVID);
        minuteTicks(dc, cx, cy, w / 2 - 14);
        progressArc(dc, cx, cy, w / 2 - 6, now.min / 60.0,
                    VIVID ? C_VGREEN : C_GREEN, 5);

        if (VIVID) {
            outlinedText(dc, cx, cy - 16, _fTime, hh + ":" + mm, C_WHITE, true);
            outlinedText(dc, cx, cy + 112, _fDate, line, C_WHITE, true);
        } else {
            bigTime(dc, cx, cy - 16, hh, mm, C_WHITE, _fTime);
            dc.setColor(C_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, cy + 112, _fDate, line,
                        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    // ---------- Always-On ----------
    // Sin rosa: solo la hora reducida, rotando entre 5 posiciones según el
    // minuto para repartir el desgaste del AMOLED y bajar píxeles encendidos.
    private function drawAod(dc as Dc, now) as Void {
        var w = dc.getWidth(); var h = dc.getHeight();
        var cx = w / 2; var cy = h / 2;
        var slot = now.min / 12;              // 0..4
        var off = 78;
        var x = cx; var y = cy;
        if (slot == 0) { y = cy - off; }
        else if (slot == 1) { x = cx + off; }
        else if (slot == 2) { y = cy + off; }
        else if (slot == 3) { x = cx - off; }
        var color = Application.Properties.getValue("AodColor");
        if (color == null) { color = VIVID ? C_VGREEN : C_GREEN; }
        bigTime(dc, x, y, hourString(now), now.min.format("%02d"), color, _fAod);
    }
}
