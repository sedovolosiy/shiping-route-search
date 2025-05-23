FROM ruby:3.4.3-alpine AS builder

WORKDIR /app

# Set Bundler path to install gems locally
ENV BUNDLE_PATH="vendor/bundle"

COPY Gemfile Gemfile.lock ./

RUN apk add --no-cache build-base yaml-dev && \
    gem install bundler && \
    bundle install --jobs=$(nproc) --retry=3 # Install gems to vendor/bundle

COPY . .

FROM ruby:3.4.3-alpine

WORKDIR /app

# Set Bundler path for the final image
ENV BUNDLE_PATH="vendor/bundle"

# Copy the entire application, including gems and any .bundle config, from the builder stage
COPY --from=builder /app /app

RUN chmod +x bin/route_finder

# Use bundle exec to run the application
CMD ["bundle", "exec", "./bin/route_finder"]