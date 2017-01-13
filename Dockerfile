FROM rails:onbuild
RUN gem install jekyll:3.1.3
ADD site /srv/jekyll
RUN bin/rake assets:precompile
