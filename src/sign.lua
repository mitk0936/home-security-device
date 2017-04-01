local crypto = require("crypto")

print(crypto.toHex(crypto.encrypt("AES-CBC", "aaaaaaaaaaaaaaaa", "{'randomJsonObject': true}")))