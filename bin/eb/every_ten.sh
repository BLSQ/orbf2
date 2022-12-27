#!/bin/bash
now=$(date)
echo $now every ten $WORKER

if [[ -z "${WORKER}" ]]; then
  bundle exec rake invoicing_jobs:discard
  bundle exec rake duplicate_jobs:clear
fi