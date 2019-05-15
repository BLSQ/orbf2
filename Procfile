web: bundle exec bin/rails server -p $PORT -e $RAILS_ENV
worker: bundle exec sidekiq -q dhis2-safe -q default -c $SIDEKIQ_CONCURRENCY
