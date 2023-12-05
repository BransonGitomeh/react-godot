#!/bin/bash

while true; do
  ./index.sh --headless --server
  sleep 1  # optional: add a small delay before restarting
done
