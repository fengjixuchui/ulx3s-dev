FROM alpin3/ulx3s-core-dev
MAINTAINER kost - https://github.com/kost

ENV ULX3SBASEDIR=/opt GHDLSRC=/opt/ghdl-git GHDLOPT=/opt/ghdl

# qt5-qtbase-dev
RUN apk --update add git patch bash wget build-base python3-dev boost-python3 boost-static boost-dev libusb-dev libusb-compat-dev libftdi1-dev libtool automake autoconf make cmake pkgconf eigen-dev eigen bison flex gawk libffi-dev zlib-dev tcl-dev graphviz readline-dev py2-pip libgnat gcc-gnat libunwind-dev readline-dev ncurses-static && \
 rm -f /var/cache/apk/* && \
 echo "[i] Success [deps]"

COPY root /

RUN apk add -f --allow-untrusted $ULX3SBASEDIR/apk/libgnat-8.3.0-r0.apk && \
 rm -f /var/cache/apk/* && \
 cd $ULX3SBASEDIR && \
 git clone https://github.com/ldoolitt/vhd2vl.git && \
 cd vhd2vl/src && \
 make WARNS="-static" && \
 install -m 755 -s vhd2vl /usr/local/bin && \
 cd $ULX3SBASEDIR && \
 git clone --recursive https://github.com/SymbiFlow/prjtrellis && \
 cd prjtrellis/libtrellis/ && \
 cmake -DCMAKE_INSTALL_PREFIX=/usr/local -DSTATIC_BUILD=OFF -DBUILD_PYTHON=ON -DBUILD_SHARED=ON . && \
 make -j$(nproc) &&\
 make install && \
 cmake -DCMAKE_INSTALL_PREFIX=/usr/local -DSTATIC_BUILD=ON -DBUILD_PYTHON=OFF -DBUILD_SHARED=OFF . && \
 make -j$(nproc) &&\
 make install && \
 strip /usr/local/bin/ecp* && \
 cd $ULX3SBASEDIR && \
 git clone https://github.com/YosysHQ/nextpnr.git && \
 cd nextpnr && \
 patch -p0 < $ULX3SBASEDIR/patches/nextpnr-CMakeLists.txt.patch && \
 EIGEN3_INCLUDE_DIR=/usr/include/eigen3 cmake -DARCH=ecp5 -DTRELLIS_ROOT=/opt/prjtrellis -DBUILD_GUI=OFF -DBUILD_PYTHON=OFF -DSTATIC_BUILD=ON && \
 make -j$(nproc) && \
 make install && \
 strip /usr/local/bin/nextpnr-ecp5 && \
 cd $ULX3SBASEDIR && \
 git clone https://github.com/ghdl/ghdl.git $GHDLSRC && \
 cd $GHDLSRC && \
 cp -f $ULX3SBASEDIR/patches/Makefile.in . && \
 ./configure --enable-libghdl --enable-synth --prefix=$GHDLOPT && \
 sed -i '/^LDFLAGS=/ s/$/ -lunwind/' Makefile && \
 make && \
 make libghdlsynth.a && \
 make install && \
 gnatbind -Llibghdl $GHDLSRC/pic/libghdl.ali -O > libghdl.files && \
 gnatbind -Llibghdl $GHDLSRC/pic/libghdl.ali -K -Z |sed -e '\@adalib/$@s/-L//' -e '\@adalib/@s@adalib/@adalib/libgnat.a@' -e '/-lgnat/d' > libghdl.link && \
 ar rc libghdl.a b~libghdl.o `cat libghdl.files` pic/grt-cstdio.o && \
 cp $GHDLSRC/libghdl.a $GHDLOPT/lib/ && \
 cp $GHDLSRC/libghdlsynth.a $GHDLSRC/ghdlsynth.link $GHDLOPT/lib/ && \
 cd $ULX3SBASEDIR && \
 git clone https://github.com/tgingold/ghdlsynth-beta && \
 cd $ULX3SBASEDIR && \
 git clone https://github.com/YosysHQ/yosys.git && \
 cp -a /opt/ghdlsynth-beta/src /opt/yosys/frontends/ghdl && \
 cd yosys && \
 patch -p1 < $ULX3SBASEDIR/patches/yosys.diff && \
 cp -a $ULX3SBASEDIR/patches/Makefile.conf . && \
 make -j$(nproc) && \
 make install && \
 strip /usr/local/bin/yosys && \
 cd $ULX3SBASEDIR && \
 pip3 install git+https://github.com/FPGAwars/apio@develop#egg=apio && \
 apio install scons && \
 apio install yosys && \
 apio install ecp5 && \
 echo "Success [build]"

#VOLUME ["/fpga"]
#WORKDIR /opt



