FROM ruby:2.5.8
RUN apt-get update -qq && apt-get install -y nodejs postgresql-client
run mkdir /orbf2
ADD . /orbf2
WORKDIR /orbf2
RUN gem update --system && gem install bundler -i 2.2.3

ENV RAILS_ENV production
ENV RAILS_SERVE_STATIC_FILES true
ENV RAILS_LOG_TO_STDOUT true

RUN bundle config set --local without 'development test' && bundle install
# Add a script to be executed every time the container starts.
EXPOSE 3000

# Start the main process.
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]