#!/usr/bin/env bash

set -o nounset
set -o errexit

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 repeats interval"
  exit 1
fi

repeats=$1
interval=$2

oak_exited=0
for (( index=1; index <"$repeats"; index++ )); do
  echo "checking oak run process: $index run"
  #shellcheck disable=SC2009
  count=$(ps -ef | grep -v grep | grep java | grep -c oak-run)
  if [ "$count" -eq 0 ]; then
    oak_exited=1
    break
  fi
  sleep "$interval"
done

if [ "$oak_exited" -eq 0 ]; then
  exit 1
fi
