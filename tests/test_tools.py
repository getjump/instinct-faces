import json
import os
import sys

import pytest

sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "tools"))

import build
import check
import gallery


def test_png_roundtrip(tmp_path):
    path = str(tmp_path / "x.png")
    build.png_write(path, 5, 3, lambda x, y: (255, 255, 255, 255) if (x + y) % 2 else (0, 0, 0, 255))
    w, h, px = build.png_read(path)
    assert (w, h) == (5, 3)
    assert px[0][:3] == [0, 255, 0]
    assert px[2][4] == 0


def test_unique_chars_expands_shorthands_and_adds_space():
    assert build.unique_chars({"chars": "$time"}) == "0123456789: "
    assert build.unique_chars({"chars": "AAB"}) == "AB "
    assert len(build.unique_chars({})) == 95


def test_design_font_link_reads_google_fonts():
    link = build.design_font_link("Main")
    assert link.startswith('<link rel="stylesheet" href="https://fonts.googleapis.com/')
    assert build.design_font_link("NoSuchFace") == ""


@pytest.mark.parametrize("name", check.faces())
def test_face_is_clean(name):
    assert check.check_face(name) == []


def test_repo_is_clean():
    assert check.check_repo() == []


def test_meta_rejects_bad_fonts():
    meta = {"title": "Ünï", "permissions": ["Camera"], "fonts": {"Time": {"size": -1, "fit": [1]}}}
    problems = "\n".join(check.check_meta("Main", meta))
    for needle in ("ASCII", "permissions", "lower_snake_case", "family is required", "size", "fit"):
        assert needle in problems


def test_meta_rejects_family_missing_from_design():
    meta = {"title": "x", "fonts": {"t": {"family": "Comic Sans", "size": 10}}}
    assert any("Google Fonts link" in p for p in check.check_meta("Main", meta))


def test_every_face_has_a_unique_title():
    titles = [json.load(open(os.path.join(check.ROOT, "faces", n, "face.json")))["title"] for n in check.faces()]
    assert len(titles) == len(set(titles))


@pytest.mark.parametrize("name", sorted(gallery.CLOCK_TEXT))
def test_clock_samples_become_holes(name):
    design = gallery.parse_design(name)
    assert set(design["clock"]) == {f"c{i}" for i in range(len(gallery.CLOCK_TEXT[name]))}
    for key in design["clock"]:
        assert design["template"].count(f"{{{{clock.{key}}}}}") == 1


def test_clock_sample_must_match_once():
    with pytest.raises(ValueError, match="occurs 0 times"):
        gallery.live_clock("Main", "<text>12:00</text>")
