def _split_once(s, sep):
    """Splits string once on sep, returns (head, tail_or_None)."""
    idx = s.find(sep)
    if idx == -1:
        return (s, None)
    return (s[:idx], s[idx + len(sep):])


def _percent_decode(s):
    if s == None:
        return None

    # Minimal but practical decoding table
    table = {
        "20": " ",
        "21": "!",
        "22": "\"",
        "23": "#",
        "24": "$",
        "25": "%",
        "26": "&",
        "27": "'",
        "28": "(",
        "29": ")",
        "2B": "+",
        "2C": ",",
        "2F": "/",
        "3A": ":",
        "3B": ";",
        "3D": "=",
        "3F": "?",
        "40": "@",
    }

    result = ""
    i = 0
    n = len(s)

    for i in range(n):
        if s[i] == "%" and i + 2 < n:
            code = s[i + 1:i + 3]
            if code in table:
                result += table[code]
                i += 3
                continue
        result += s[i]
        i += 1

    return result


def _parse_qualifiers(qs):
    if not qs:
        return {}

    result = {}
    parts = qs.split("&")

    for part in parts:
        if "=" in part:
            k, v = part.split("=", 1)
            result[_percent_decode(k)] = _percent_decode(v)
        else:
            result[_percent_decode(part)] = ""

    return result


def _percent_encode(s):
    if s == None:
        return None

    unreserved = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"

    hex_table = {
        " ": "%20",
        "!": "%21",
        "\"": "%22",
        "#": "%23",
        "$": "%24",
        "%": "%25",
        "&": "%26",
        "'": "%27",
        "(": "%28",
        ")": "%29",
        "+": "%2B",
        ",": "%2C",
        "/": "%2F",
        ":": "%3A",
        ";": "%3B",
        "=": "%3D",
        "?": "%3F",
        "@": "%40",
    }

    result = ""
    for i in range(len(s)):
        c = s[i]

        if c in unreserved:
            result += c
        elif c in hex_table:
            result += hex_table[c]
        else:
            fail("Unsupported character for encoding: %s" % c)

    return result


def _encode_qualifiers(q):
    if not q:
        return None

    # Deterministic ordering
    keys = sorted(q.keys())

    parts = []
    for k in keys:
        v = q[k]
        ek = _percent_encode(k)
        ev = _percent_encode(v)

        if v == "":
            parts.append(ek)
        else:
            parts.append("%s=%s" % (ek, ev))

    return "&".join(parts)


def purl_to_string(p):
    """
    Serialize parsed PURL dict back to canonical string form.
    """

    if "type" not in p or "name" not in p:
        fail("Invalid PURL object")

    result = "pkg:"

    # type
    result += _percent_encode(p["type"])

    # path
    result += "/"

    if p.get("namespace"):
        # namespace may contain '/'
        ns_parts = p["namespace"].split("/")
        result += "/".join([_percent_encode(x) for x in ns_parts])
        result += "/"

    result += _percent_encode(p["name"])

    # version
    if p.get("version"):
        result += "@%s" % _percent_encode(p["version"])

    # qualifiers
    q = _encode_qualifiers(p.get("qualifiers"))
    if q:
        result += "?%s" % q

    # subpath
    if p.get("subpath"):
        result += "#%s" % _percent_encode(p["subpath"])

    return result


def parse_purl(purl):
    """
    Parse a Package URL (PURL) into a structured dict.

    Returns:
        {
            "type": str,
            "namespace": str or None,
            "name": str,
            "version": str or None,
            "qualifiers": dict,
            "subpath": str or None,
        }
    """

    if not purl.startswith("pkg:"):
        fail("Invalid PURL: must start with 'pkg:'")

    # Strip scheme
    remainder = purl[4:]

    # Extract subpath (#)
    remainder, subpath = _split_once(remainder, "#")

    # Extract qualifiers (?)
    remainder, qualifiers = _split_once(remainder, "?")

    # Extract version (@)
    remainder, version = _split_once(remainder, "@")

    # Extract type and path
    type_and_path = remainder.split("/", 1)
    if len(type_and_path) != 2:
        fail("Invalid PURL: missing type or name")

    ptype = type_and_path[0]
    path = type_and_path[1]

    # Namespace + name
    parts = path.split("/")
    if len(parts) == 1:
        namespace = None
        name = parts[0]
    else:
        namespace = "/".join(parts[:-1])
        name = parts[-1]

    return {
        "type": ptype,
        "namespace": namespace,
        "name": name,
        "version": version,
        "qualifiers": _parse_qualifiers(qualifiers),
        "subpath": subpath,
    }