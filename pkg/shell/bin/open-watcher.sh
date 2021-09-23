#!/usr/bin/env bash

if [ "${WATCHER_PORT:-""}" = "" ]; then
  echo "Must provide a \$WATCHER_PORT where the stream is available"
  exit 1
fi

if [ "${WATCHER_HOST:-""}" = "" ]; then
  echo "Must provide a \$WATCHER_HOST to connect to"
  exit 1
fi

# OSX
(
  sleep 1
  open http://localhost:$WATCHER_PORT
) &

ssh $WATCHER_HOST -L $WATCHER_PORT:localhost:$WATCHER_PORT 'sleep 4s && exit'
