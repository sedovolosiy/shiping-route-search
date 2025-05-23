FROM ruby:3.4.3-alpine

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN apk add --no-cache build-base yaml-dev && \
    gem install bundler && \
    bundle install

COPY . .

RUN chmod +x bin/route_finder
CMD ["./bin/route_finder"]