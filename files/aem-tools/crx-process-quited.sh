#!/usr/bin/env bash

set -o nounset
set -o errexit

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 repeats interval"
  exit 1
fi

repeats="$1"
interval="$2"

crx_exited=0
for (( index=1; index <"$repeats"; index_++ )); do
  echo "checking crx run process: $index run"
  count=$(pgrep -f crx-quickstart|wc -l)
  if [ "$count" -eq 0 ]; then
    crx_exited=1
    break
  fi
  sleep "$interval"
done

if [ "$crx_exited" -eq 0 ]; then
  exit 1
fi
