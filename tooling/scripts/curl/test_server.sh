#!/usr/bin/env bash
while true; do
  curl $1 -s > /dev/null
  sleep 5
  echo $1
done