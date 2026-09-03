using Toybox.Application as App;
using Toybox.WatchUi as Ui;

//! Aplicación de la esfera de reloj para el Garmin Epix Pro 51 mm.
//! Estilo analógico minimalista: fondo ámbar, dos agujas afiladas y un disco
//! central. Sin cifras, sin fecha y sin segundero.
class EpixWatchFaceApp extends App.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    //! Se llama al arrancar la app.
    function onStart(state) {
    }

    //! Se llama al cerrar la app.
    function onStop(state) {
    }

    //! Devuelve la vista inicial (la esfera).
    function getInitialView() {
        return [ new EpixWatchFaceView() ];
    }
}
