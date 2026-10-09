import base64
import json

import pytest

import handler


class FakeTable:
    def __init__(self):
        self.items = {}

    def put_item(self, Item):
        self.items[Item["code"]] = Item

    def get_item(self, Key):
        item = self.items.get(Key["code"])
        return {"Item": item} if item else {}


@pytest.fixture(autouse=True)
def table(monkeypatch):
    fake = FakeTable()
    monkeypatch.setattr(handler, "_table", fake)
    return fake


def event(route, body=None, code=None, base64_body=False):
    if base64_body and body is not None:
        body = base64.b64encode(body.encode()).decode()
    return {
        "routeKey": route,
        "body": body,
        "isBase64Encoded": base64_body,
        "pathParameters": {"code": code} if code else None,
    }


def test_health():
    result = handler.handler(event("GET /health"), None)
    assert result["statusCode"] == 200


def test_create_link_stores_url(table):
    result = handler.handler(event("POST /links", '{"url": "https://kth.se"}'), None)
    assert result["statusCode"] == 201
    code = json.loads(result["body"])["code"]
    assert table.items[code]["url"] == "https://kth.se"


def test_create_link_accepts_base64_body(table):
    body = '{"url": "https://kth.se"}'
    result = handler.handler(event("POST /links", body, base64_body=True), None)
    assert result["statusCode"] == 201


@pytest.mark.parametrize("body", ['{"url": "not-a-url"}', '{"url": 42}', "{}"])
def test_create_link_rejects_invalid_url(body):
    result = handler.handler(event("POST /links", body), None)
    assert result["statusCode"] == 400


def test_create_link_rejects_invalid_json():
    result = handler.handler(event("POST /links", "not json"), None)
    assert result["statusCode"] == 400


def test_resolve_link_redirects(table):
    table.items["abc"] = {"code": "abc", "url": "https://kth.se"}
    result = handler.handler(event("GET /links/{code}", code="abc"), None)
    assert result["statusCode"] == 302
    assert result["headers"]["Location"] == "https://kth.se"


def test_resolve_unknown_link_returns_404():
    result = handler.handler(event("GET /links/{code}", code="missing"), None)
    assert result["statusCode"] == 404


def test_unknown_route_returns_404():
    result = handler.handler(event("DELETE /links"), None)
    assert result["statusCode"] == 404