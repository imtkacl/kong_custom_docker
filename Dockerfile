FROM centos:7

ARG PROXY_USER
ARG PROXY_PASSWORD
ARG PROXY_SERVER
ARG PROXY_PORT

ENV http_proxy http://$PROXY_USER:$PROXY_PASSWORD@$PROXY_SERVER:$PROXY_PORT/
ENV https_proxy http://$PROXY_USER:$PROXY_PASSWORD@$PROXY_SERVER:$PROXY_PORT/

ENV DOWNLOAD_CACHE $HOME/download-cache
ENV LUAROCKS 2.4.2
ENV LUAROCKS_DOWNLOAD $DOWNLOAD_CACHE/luarocks-$LUAROCKS
ENV SERF 0.8.0
ENV SERF_DOWNLOAD $DOWNLOAD_CACHE/serf-$SERF
ENV OPENSSL 1.0.2k
ENV OPENSSL_DOWNLOAD $DOWNLOAD_CACHE/openssl-$OPENSSL
ENV OPENRESTY 1.11.2.2
ENV OPENRESTY_DOWNLOAD $DOWNLOAD_CACHE/openresty-$OPENRESTY
ENV INSTALL_CACHE $HOME/install-cache
ENV OPENSSL_INSTALL $INSTALL_CACHE/openssl-$OPENSSL
ENV OPENRESTY_INSTALL $INSTALL_CACHE/openresty-$OPENRESTY
ENV LUAROCKS_INSTALL $INSTALL_CACHE/luarocks-$LUAROCKS
ENV SERF_INSTALL $INSTALL_CACHE/serf-$SERF
ENV OPENSSL_DIR $OPENSSL_INSTALL
ENV SERF_PATH $SERF_INSTALL/serf
ENV KONG_DOWNLOAD $DOWNLOAD_CACHE/kong
ENV PATH $PATH:$OPENRESTY_INSTALL/nginx/sbin:$OPENRESTY_INSTALL/bin:$LUAROCKS_INSTALL/bin:$SERF_INSTALL:$KONG_DOWNLOAD/bin

RUN yum -y install git-all
RUN yum -y install gcc
RUN yum -y install pcre-devel
RUN yum -y install zlib-devel
RUN yum -y install unzip
RUN yum -y install wget

RUN mkdir -p $OPENSSL_DOWNLOAD $OPENRESTY_DOWNLOAD $LUAROCKS_DOWNLOAD $SERF_DOWNLOAD $KONG_DOWNLOAD
RUN mkdir -p $OPENSSL_INSTALL $OPENRESTY_INSTALL $LUAROCKS_INSTALL $SERF_INSTALL

WORKDIR $DOWNLOAD_CACHE
RUN curl -L http://www.openssl.org/source/openssl-$OPENSSL.tar.gz | tar xz
WORKDIR $OPENSSL_DOWNLOAD
RUN ./config shared --prefix=$OPENSSL_INSTALL
RUN make
RUN make install

WORKDIR $DOWNLOAD_CACHE
RUN curl -L https://openresty.org/download/openresty-$OPENRESTY.tar.gz | tar xz
WORKDIR $OPENRESTY_DOWNLOAD
ENV OPENRESTY_OPTS="--prefix=$OPENRESTY_INSTALL --with-openssl=$OPENSSL_DOWNLOAD --with-ipv6 --with-pcre-jit --with-http_ssl_module --with-http_realip_module --with-http_stub_status_module --without-luajit-lua52"
RUN ./configure $OPENRESTY_OPTS
RUN make
RUN make install

RUN git clone https://github.com/imtkacl/luarocks.git $LUAROCKS_DOWNLOAD
WORKDIR $LUAROCKS_DOWNLOAD
RUN ./configure --prefix=$LUAROCKS_INSTALL --lua-suffix=jit --with-lua=$OPENRESTY_INSTALL/luajit --with-lua-include=$OPENRESTY_INSTALL/luajit/include/luajit-2.1
RUN make build
RUN make install

WORKDIR $SERF_DOWNLOAD
RUN wget https://releases.hashicorp.com/serf/${SERF}/serf_${SERF}_linux_amd64.zip
RUN unzip serf_${SERF}_linux_amd64.zip
RUN ln -s $SERF_DOWNLOAD/serf $SERF_INSTALL/serf

WORKDIR $DOWNLOAD_CACHE
RUN git clone https://github.com/imtkacl/kong
RUN git config --global url."https://".insteadOf git://
WORKDIR $KONG_DOWNLOAD
RUN make install
RUN make dev

RUN mkdir /etc/kong
#RUN cp $KONG_DOWNLOAD/kong.conf.default /etc/kong/kong.conf
#RUN luarocks path >> ~/.bashrc
RUN make lint
#RUN make test
RUN chmod 755 $HOME

#RUN wget -O /usr/local/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.1.3/dumb-init_1.1.3_amd64 && chmod +x /usr/local/bin/dumb-init

COPY dumb-init_1.1.3_amd64 /usr/local/bin/dumb-init
RUN chmod +x /usr/local/bin/dumb-init

COPY docker-entrypoint.sh /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]

#ENV TERM vt100

EXPOSE 8000 8443 8001 7946
CMD ["kong", "start"]
#CMD ["top"]

