#!/bin/sh

set -e

CONTAINER_IP=$(ifconfig eth0 | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | cut -d: -f2)

sed -i "s/HOSTNAME/$HOSTNAME/g" payload.json
sed -i "s/127.0.0.1/$CONTAINER_IP/" payload.json
curl -v -X PUT -d @payload.json http://192.168.33.10:8080/v1/agent/service/register

exec python cabify.py
