const Buffer = require('buffer/').Buffer;

const sodium = require('libsodium-wrappers');
const bs58check = require('bs58check');

(function() {
    var prefix = {
	edsk: new Uint8Array([43, 246, 78, 7]),
	edsig: new Uint8Array([9, 245, 205, 134, 18]),
    };

    function b58cencode(bytes, prefix) {
	var bytesBuf = Buffer.from(bytes);
	var prefixBuf = Buffer.from(prefix);
	var combined = Buffer.concat([prefixBuf, bytesBuf]);

	var encoded = bs58check.encode(combined);
	return encoded
    }

    function b58cdecode(chars, prefix) {
	var decoded = bs58check.decode(chars);
	var payload = decoded.slice(prefix.length);
	return payload;
    }

    function signature(bytes, sk_b58check) {
	var sk = b58cdecode(sk_b58check, prefix.edsk);
	var sig = sodium.crypto_sign_detached(bytes, sk)
	var sig_b58check = b58cencode(sig, prefix.edsig)
	return sig_b58check;
    }

    // MAIN

    const SERVER = "http://localhost:8732";

    var flags = {
        nodeUrl: SERVER,
        now: (new Date()).getTime()
    };

    var app = Elm.Main.fullscreen();

    app.ports.sendSk.subscribe(function(req) {
	try {
	    var dec = b58cdecode(req.sk, prefix.edsk);
	    console.log("dec", dec);

	    var enc = b58cencode(dec, prefix.edsk);
	    console.log("enc", enc);

	    var sig = signature(req.payload, req.sk);
	    console.log("sig", sig);

	    app.ports.signature.send(sig);
	} catch(err) {
	    console.log(err.message);
	}
    });

})();
