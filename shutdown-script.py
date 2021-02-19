#!/usr/bin/python

import json
import base64
import urllib.parse
import urllib.request

def run_request(req: urllib.request.Request) -> str:
	with urllib.request.urlopen(req) as res:
		return res.read().decode("utf-8")

def get_meta(path: str) -> str:
	return run_request(urllib.request.Request(
		f"http://metadata.google.internal/computeMetadata/v1/{path}",
		None,
		{"Metadata-Flavor": "Google"},
	))

def get_zone() -> str:
	return get_meta("instance/zone").split("/")[-1]

def get_instance() -> str:
	return get_meta("instance/name")

def get_topic() -> str:
	return get_meta("instance/attributes/resurrection-topic")

def get_token() -> str:
	res = get_meta("instance/service-accounts/default/token")
	data = json.loads(res)
	return data["access_token"]

def encode_message(message: dict) -> str:
	params = urllib.parse.urlencode(message)
	return base64.b64encode(params.encode("utf-8")).decode("utf-8")

def publish_message(message: dict) -> str:
	topic = get_topic()
	token = get_token()

	return run_request(urllib.request.Request(
		f"https://pubsub.googleapis.com/v1/{topic}:publish",
		json.dumps({
			"messages": [{
				"data": encode_message(message),
			}],
		}).encode("utf-8"),
		{
			"Content-Type": "application/json",
			"Authorization": f"Bearer {token}",
		},
	))

def resurrect(timeout: int) -> str:
	return publish_message({
		"zone": get_zone(),
		"instance": get_instance(),
		"timeout": timeout,
	})

print(resurrect(500))
