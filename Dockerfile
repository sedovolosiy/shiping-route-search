FROM ruby:3.4.3-slim

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN gem install bundler && bundle install

COPY . .

CMD ["ruby", "application/main.rb"]