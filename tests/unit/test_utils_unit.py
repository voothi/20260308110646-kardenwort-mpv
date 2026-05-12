import math


def _calculate_ass_alpha(val):
    if isinstance(val, str) and len(val) == 2 and all(c in "0123456789abcdefABCDEF" for c in val):
        return val.upper()

    try:
        num = float(val)
    except (TypeError, ValueError):
        return "00"

    if 0 <= num <= 1:
        num = (1.0 - num) * 100

    num = max(0, min(100, num))
    return f"{math.floor((num / 100) * 255 + 0.5):02X}"


def _utf8_to_table(s):
    return list(s)


def test_utf8_ascii():
    assert len(_utf8_to_table("hello")) == 5


def test_utf8_cyrillic():
    assert len(_utf8_to_table("привет")) == 6


def test_utf8_german_diacritics():
    assert len(_utf8_to_table("größe")) == 5


def test_utf8_cjk():
    assert len(_utf8_to_table("日本語")) == 3


def test_utf8_empty():
    assert len(_utf8_to_table("")) == 0


def test_utf8_mixed():
    assert len(_utf8_to_table("héllo")) == 5


def test_ass_alpha_fully_opaque():
    assert _calculate_ass_alpha(1) == "00"


def test_ass_alpha_fully_transparent():
    assert _calculate_ass_alpha(0) == "FF"


def test_ass_alpha_half_opacity():
    assert _calculate_ass_alpha(0.5) == "80"


def test_ass_alpha_hex_passthrough():
    assert _calculate_ass_alpha("aa") == "AA"


def test_ass_alpha_invalid_input_defaults():
    assert _calculate_ass_alpha("garbage") == "00"


def test_ass_alpha_none_input_defaults():
    assert _calculate_ass_alpha(None) == "00"
