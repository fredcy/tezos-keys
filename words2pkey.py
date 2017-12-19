import unicodedata
import sys
import bitcoin
import pysodium
import json
from pyblake2 import blake2b
from hashlib import sha256
import binascii

def tezos_pkh(digest):
    return bitcoin.bin_to_b58check(digest, magicbyte=434591)

if __name__ == '__main__':

    if len(sys.argv) == 18:
        mnemonic = ' '.join(sys.argv[1:16]).lower()
        email = sys.argv[16]
        password = sys.argv[17]
        salt = unicodedata.normalize(
            "NFKD", (email + password).decode("utf8")).encode("utf8")
        try:
            seed = bitcoin.mnemonic_to_seed(mnemonic, salt)
        except:
            print("Invalid mnemonic")
            exit(1)
        pk, sk = pysodium.crypto_sign_seed_keypair(seed[0:32])
        pkh = blake2b(pk,20).digest()
        message = sys.stdin.read()
        signed = pysodium.crypto_sign_detached(message, sk)

        print json.dumps(
            {'public_key': binascii.b2a_hex(pk),
             'public_key_hash': tezos_pkh(pkh),
             'signature': binascii.b2a_base64(signed)}
            )
    else:
        print("Usage: python keysigner.py garage absurd ... steak email@domain.com passw0rd < message.txt")