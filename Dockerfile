FROM alpine:20220328

# list of mirrors: https://mirrors.alpinelinux.org/
COPY https-repositories /etc/apk/repositories
RUN chmod 644 /etc/apk/repositories

RUN apk add --no-cache gcc=11.2.1_git20220219-r2 gcc-gnat=11.2.1_git20220219-r2 binutils libc-dev git make
RUN git clone https://github.com/AdaCore/gprbuild && \
    cd gprbuild && git checkout v22.0.0 && \
    git clone -b v22.0.0 https://github.com/AdaCore/xmlada && \
    git clone -b v22.0.0 https://github.com/AdaCore/gprconfig_kb && \
    sh ./bootstrap.sh --with-xmlada=xmlada --with-kb=gprconfig_kb --prefix=./bootstrap

COPY targets.xml /gprbuild/targets.xml
COPY targets.xml /gprbuild/xmlada/targets.xml

RUN cd gprbuild/xmlada && \
    export PATH=/gprbuild/bootstrap/bin:$PATH && \
    gprconfig --batch --config=Ada,11.2,default,/usr/bin/,GNAT --db . && \
    ./configure && make && make install

RUN cd gprbuild && \
    export PATH=/gprbuild/bootstrap/bin:$PATH && \
    export GPR_PROJECT_PATH=/usr/local/share/gpr && \
    gprconfig --batch  --config=Ada,11.2,default,/usr/bin/,GNAT --config=C,11.2.1,,/usr/bin/,GCC --db . && \
    make prefix=/usr/local setup && make all && make install

RUN rm -rf /gprbuild

RUN apk add curl

RUN git clone --recurse-submodules https://github.com/alire-project/alire.git 
COPY targets.xml /alire/targets.xml
RUN cd alire &&  \
    gprconfig --batch  --config=Ada,11.2,default,/usr/bin/,GNAT --config=C,11.2.1,,/usr/bin/,GCC --db . && \
    gprbuild -j0 -P alr_env && cp bin/alr /usr/local/bin/
