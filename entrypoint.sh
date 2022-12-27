#!/bin/bash

[[ -z "${WORKER}" ]] && echo "hesabu startup for web" || echo "hesabu startup for worker"

if [[ -z "${WORKER}" ]]; then
  bundle exec rails s -e $RAILS_ENV
else
  bundle exec sidekiq -q dhis2-safe -q default -c $SIDEKIQ_CONCURRENCY
fi