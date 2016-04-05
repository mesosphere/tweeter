FROM debian:jessie

RUN apt-get update && apt-get -y install wget build-essential libreadline-dev libncurses5-dev libpcre3-dev libssl-dev && apt-get -q -y clean
RUN wget http://openresty.org/download/ngx_openresty-1.7.10.1.tar.gz \
  && tar xvfz ngx_openresty-1.7.10.1.tar.gz \
  && cd ngx_openresty-1.7.10.1 \
  && ./configure --with-luajit --with-http_gzip_static_module  --with-http_ssl_module \
  && make \
  && make install \
  && rm -rf /ngx_openresty*

EXPOSE 8080
CMD /usr/local/openresty/nginx/sbin/nginx

ADD nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
ADD app.lua /usr/local/openresty/nginx/conf/app.lua
RUN chmod a+r /usr/local/openresty/nginx/conf/app.lua
