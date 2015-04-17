FROM rails:latest

ADD . /rails

WORKDIR /rails

EXPOSE 3000

CMD bundle install && rails server