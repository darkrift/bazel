_BASE64_TABLE = {
    "A": 0, "B": 1, "C": 2, "D": 3, "E": 4, "F": 5, "G": 6, "H": 7,
    "I": 8, "J": 9, "K": 10, "L": 11, "M": 12, "N": 13, "O": 14, "P": 15,
    "Q": 16, "R": 17, "S": 18, "T": 19, "U": 20, "V": 21, "W": 22, "X": 23,
    "Y": 24, "Z": 25,
    "a": 26, "b": 27, "c": 28, "d": 29, "e": 30, "f": 31, "g": 32, "h": 33,
    "i": 34, "j": 35, "k": 36, "l": 37, "m": 38, "n": 39, "o": 40, "p": 41,
    "q": 42, "r": 43, "s": 44, "t": 45, "u": 46, "v": 47, "w": 48, "x": 49,
    "y": 50, "z": 51,
    "0": 52, "1": 53, "2": 54, "3": 55, "4": 56, "5": 57, "6": 58, "7": 59,
    "8": 60, "9": 61,
    "+": 62, "/": 63,
}

def _b64_char_value(c):
    if c == "=":
        return None
    if c in _BASE64_TABLE:
        return _BASE64_TABLE[c]
    fail("Invalid base64 character: %s" % c)

def _base64_decode(b64):
    """Returns a list of byte values (ints 0–255)."""
    result = []
    chunk = []

    for i in range(len(b64)):
        val = _b64_char_value(b64[i])
        chunk.append(val)

        if len(chunk) == 4:
            v0, v1, v2, v3 = chunk

            # First byte
            result.append((v0 << 2) | (v1 >> 4))

            # Second byte
            if v2 != None:
                result.append(((v1 & 0xF) << 4) | (v2 >> 2))

            # Third byte
            if v3 != None:
                result.append(((v2 & 0x3) << 6) | v3)

            chunk = []

    return result


def _bytes_to_hex(byte_list):
    hex_chars = "0123456789abcdef"
    out = []

    for b in byte_list:
        out.append(hex_chars[b >> 4])
        out.append(hex_chars[b & 0xF])

    return "".join(out)


def sri_to_checksum(sri):
    """Convert 'sha256-<base64>' → 'sha256:<hex>'."""
    parts = sri.split("-", 1)
    if len(parts) != 2:
        fail("Invalid SRI format: %s" % sri)

    algo = parts[0]
    b64 = parts[1]

    decoded_bytes = _base64_decode(b64)
    hex_digest = _bytes_to_hex(decoded_bytes)

    return "%s:%s" % (algo, hex_digest)