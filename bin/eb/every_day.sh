#!/bin/bash
now=$(date)
echo $now every ten $WORKER

if [[ -z "${WORKER}" ]]; then
  bundle exec rake daily:dhis2_snapshot
fi