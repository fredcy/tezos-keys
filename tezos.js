const Buffer = require('buffer/').Buffer;
const sodium = require('libsodium-wrappers');
const bs58check = require('bs58check');
const bip39 = require('bip39');
const bitcore = require('bitcore-lib');


(function() {
    var prefix = {
	tz1: new Uint8Array([6, 161, 159]),
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

	low_half = sk.slice(32);
	var pk = b58cencode(low_half, prefix.edpk);
	return pk;
    }

    function calcPkHash(pk_b58c) {
	var pk = b58cdecode(pk_b58c, prefix.edpk);
	var hash = sodium.crypto_generichash(20, pk);
	var pkh = b58cencode(hash, prefix.tz1);
	return pkh;
    }

    function calcSk(mnemonic, email, passphrase) {
	var salt = email + passphrase;
	var seed = bip39.mnemonicToSeedSync(mnemonic, salt);
	var seed32 = seed.slice(0, 32);
	var kp = sodium.crypto_sign_seed_keypair(seed32);
	var sk = b58cencode(kp.privateKey, prefix.edsk);
	return sk;
    }

    function bitcoinAddress(pk) {
	var bitcoin_keys = [
            "\x02\xc0T!\xaa\x00\x13\xee\xd38T#\xb6<\xd2\x89" +
		"\xc3BR\x118\xaa\xffj\x91U\xb3\xc7\xc8t\xc3\x1e\xa9",
            "\x03\xb3\xb1|\xe2\x13\xe4\xed\xb9\xf1\x7f\x0e\x11" +
		"\xf5h\x80\xa8\x96r\xd2 4\x83\xbb\x7fu\xb1\x1a%_\x08\xdc\x96"
	]

	var script = bitcore.Script.buildMultisigOut(bitcoin_keys, 2, { noSorting: true });
	script.prepend("OP_DROP");
        script.prepend(pkh);

        const scriptHash = bitcore.Script.buildScriptHashOut(script);
	const address = bitcore.Address.fromScript(scriptHash, bitcore.Networks.mainnet).toString();
	return address;
    }

    // MAIN

    const SERVER = "http://localhost:8732";

    var flags = {
        nodeUrl: SERVER,
        now: (new Date()).getTime()
    };

    var app = Elm.Main.init({
        node: document.getElementById('elm')
    });

    app.ports.sendSk.subscribe(function(sk) {
	try {
	    pk = calcPk(sk);
	    pkh = calcPkHash(pk);
	    app.ports.getPk.send({ pk: pk, pkh: pkh });
	} catch(err) {
	    console.log("sendSk handler: ", err.message);
	    app.ports.getPk.send(null);
	}
    });

    app.ports.sigRequest.subscribe(function(req) {
	try {
	    var sig = signature(req.payload, req.sk);
	    app.ports.signature.send(sig);
	} catch(err) {
	    console.log("sigRequest handler", err.message);
	    app.ports.signature.send(null);
	}
    });

    app.ports.skRequest.subscribe(function(req) {
        console.log("skRequest:", req);
	try {
	    sk = calcSk(req.mnemonic, req.email, req.passphrase)
	    app.ports.skResponse.send(sk);
	} catch(err) {
	    console.log("skRequest handler", err.message);
	    app.ports.skResponse.send(null);
	}
    });

})();
