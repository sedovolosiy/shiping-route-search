FROM ruby:3.4.3

WORKDIR /app

COPY . /app

RUN gem install bundler && bundle install || true

CMD ["ruby", "main.rb"]
