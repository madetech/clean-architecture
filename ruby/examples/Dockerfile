FROM ruby:2.4.0
WORKDIR /clean
COPY Gemfile* /clean
RUN bundle check || bundle install
COPY . /clean
