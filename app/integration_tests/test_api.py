import os

import requests

API_URL = os.environ["API_URL"]
TIMEOUT = 60  


def test_health():
    r = requests.get(f"{API_URL}/health", timeout=TIMEOUT)
    assert r.status_code == 200


def test_create_and_resolve_link():
    r = requests.post(f"{API_URL}/links", json={"url": "https://www.kth.se"}, timeout=TIMEOUT)
    assert r.status_code == 201
    code = r.json()["code"]

    r = requests.get(f"{API_URL}/links/{code}", allow_redirects=False, timeout=TIMEOUT)
    assert r.status_code == 302
    assert r.headers["Location"] == "https://www.kth.se"


def test_invalid_url_is_rejected():
    r = requests.post(f"{API_URL}/links", json={"url": "not-a-url"}, timeout=TIMEOUT)
    assert r.status_code == 400


def test_unknown_code_returns_404():
    r = requests.get(f"{API_URL}/links/does-not-exist", allow_redirects=False, timeout=TIMEOUT)
    assert r.status_code == 404