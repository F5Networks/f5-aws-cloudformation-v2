#!/usr/bin/env python

import requests
import os

REG_KEY_API_SERVER = 'REG_KEY_API_SERVER'
api_server = os.environ.get(REG_KEY_API_SERVER)
headers = {"X-Api-Key": "3tdLKjleBIT4v4NdDE6z5rOi6WWktf53PJsW1i-e9-c", "X-Api-Entity": "dewdrop"}
pools_to_fill = []
try:
    # Locate correct pool
    with requests.Session() as s:
        get_pools = s.get('https://' + api_server + '/api/regkey/v1/pool', verify=False, headers=headers)
    get_pools.raise_for_status()
except requests.exceptions.RequestException as e:
    print(e)
    print("regkey license server unavailable, exiting test")
    raise SystemExit(1)
else:
    for pool in get_pools.json():
        if pool["counts"]["AVAILABLE"] < 20 and "Mock" not in pool["name"]:
            pools_to_fill.append(pool["name"])
    if len(pools_to_fill) != 0:
        raise Exception("Please refill the following pool(s): ", pools_to_fill)

