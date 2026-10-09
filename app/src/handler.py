import base64
import json
import os
import secrets

import boto3

_table = None


def get_table():
    global _table
    if _table is None:
        _table = boto3.resource("dynamodb").Table(os.environ["TABLE_NAME"])
    return _table


def response(status, body=None, headers=None):
    return {
        "statusCode": status,
        "headers": {"Content-Type": "application/json", **(headers or {})},
        "body": json.dumps(body) if body is not None else "",
    }


def create_link(event):
    raw = event.get("body") or "{}"
    if event.get("isBase64Encoded"):
        raw = base64.b64decode(raw).decode()
    try:
        url = json.loads(raw).get("url")
    except (json.JSONDecodeError, AttributeError):
        return response(400, {"error": "invalid JSON"})
    if not isinstance(url, str) or not url.startswith(("http://", "https://")):
        return response(400, {"error": "invalid url"})

    code = secrets.token_urlsafe(6)
    get_table().put_item(Item={"code": code, "url": url})
    return response(201, {"code": code})


def resolve_link(event):
    code = event["pathParameters"]["code"]
    item = get_table().get_item(Key={"code": code}).get("Item")
    if item is None:
        return response(404, {"error": "not found"})
    return response(302, headers={"Location": item["url"]})


def handler(event, context):
    route = event.get("routeKey")
    if route == "GET /health":
        return response(200, {"status": "ok"})
    if route == "POST /links":
        return create_link(event)
    if route == "GET /links/{code}":
        return resolve_link(event)
    return response(404, {"error": "not found"})