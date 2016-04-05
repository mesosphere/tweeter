FROM rails:onbuild

RUN bin/rake assets:precompile
