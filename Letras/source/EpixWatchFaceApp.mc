using Toybox.Application as App;
using Toybox.WatchUi as Ui;

//! Aplicación de la esfera de reloj para el Garmin Epix Pro 51 mm.
//! Dice la hora en palabras, en castellano: "TRES MENOS CUARTO".
class EpixWatchFaceApp extends App.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state) {
    }

    function onStop(state) {
    }

    function getInitialView() {
        return [ new EpixWatchFaceView() ];
    }
}
