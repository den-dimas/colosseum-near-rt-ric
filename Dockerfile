#==================================================================================
#       Copyright (c) 2022 Northeastern University
#         Extended by Den of NTUST TEEP Programs
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#          http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#==================================================================================

FROM ubuntu:20.04 as buildenv
ARG log_level_e2sim=3

# Install E2sim
RUN mkdir -p /workspace

# To configure tzdata without having to do it interactively
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC
#RUN DEBIAN_FRONTEND=noninteractive apt-get -y install tzdata

RUN apt-get update && apt-get install -y build-essential git cmake libsctp-dev autoconf automake libtool bison flex libboost-all-dev

WORKDIR /workspace

RUN git clone -b develop https://github.com/wineslab/ns-o-ran-e2-sim /workspace/e2sim

RUN mkdir /workspace/e2sim/e2sim/build
WORKDIR /workspace/e2sim/e2sim/build
RUN cmake .. -DDEV_PKG=1 -DLOG_LEVEL=${log_level_e2sim}

RUN make package
RUN echo "Going to install e2sim-dev"
RUN dpkg --install ./e2sim-dev_1.0.0_amd64.deb
RUN ldconfig

WORKDIR /workspace

# Install ns-3
RUN apt-get install -y g++ python3 cmake ninja-build git ccache clang-format clang-tidy gdb valgrind tcpdump sqlite sqlite3 libsqlite3-dev qtbase5-dev qtchooser qt5-qmake qtbase5-dev-tools openmpi-bin openmpi-common openmpi-doc libopenmpi-dev doxygen graphviz imagemagick python3-sphinx dia imagemagick texlive dvipng latexmk texlive-extra-utils texlive-latex-extra texlive-font-utils libeigen3-dev gsl-bin libgsl-dev libgslcblas0 libxml2 libxml2-dev libgtk-3-dev lxc-utils lxc-templates iproute2 iptables libxml2 libxml2-dev libboost-all-dev

RUN git clone https://github.com/wineslab/ns-o-ran-ns3-mmwave /workspace/ns3-mmwave-oran
RUN git clone -b master https://github.com/o-ran-sc/sim-ns3-o-ran-e2 /workspace/ns3-mmwave-oran/contrib/oran-interface

WORKDIR /workspace/ns3-mmwave-oran

RUN ./ns3 configure --enable-tests --enable-examples
RUN cd cmake-cache; /usr/bin/cmake -DCMAKE_BUILD_TYPE=default -DNS3_ASSERT=ON -DNS3_LOG=ON -DNS3_WARNINGS_AS_ERRORS=OFF -DNS3_NATIVE_OPTIMIZATIONS=OFF -DNS3_EXAMPLES=ON -DNS3_PYTHON_BINDINGS=ON -DNS3_TESTS=ON -G Ninja .. ; cd ..
RUN ./ns3 build
RUN cd cmake-cache; /usr/bin/cmake --build . -j 7 ; cd ..

WORKDIR /workspace

CMD [ "/bin/sh" ]
