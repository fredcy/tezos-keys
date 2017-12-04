(function() {
    // MAIN

    const SERVER = "http://localhost:8732";

    sodium = require('libsodium-wrappers');


    var flags = {
        nodeUrl: SERVER,
        now: (new Date()).getTime()
    };

    var app = Elm.Main.fullscreen();

    app.ports.sendSk.subscribe(function(sk) {
	console.log("sendSk", sk);
    });
})();
