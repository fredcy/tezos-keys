const Buffer = require('buffer/').Buffer;

const sodium = require('libsodium-wrappers');
const bs58check = require('bs58check');

(function() {
    var prefix = {
	edpk: new Uint8Array([13, 15, 37, 217]),
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

    function calcPk(sk_b58c) {
	var sk = b58cdecode(sk_b58c, prefix.edsk);
	console.log("sk", sk);

	low_half = sk.slice(32);
	var pk = b58cencode(low_half, prefix.edpk);

	console.log("pk", pk);
	return pk
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
	    calcPk(req.sk);

	    var sig = signature(req.payload, req.sk);
	    console.log("sig", sig);

	    app.ports.signature.send(sig);
	} catch(err) {
	    console.log(err.message);
	    app.ports.signature.send(null);
	}
    });

})();
