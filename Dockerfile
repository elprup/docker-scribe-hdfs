# VERSION 0.1
# DOCKER-VERSION  0.8.0
# AUTHOR:         elprup
# origin scribe docker AUTHOR:         Santiago del Castillo
# DESCRIPTION:    Image with Scribe HDFS (hadoop 1.0.3)
# TO_BUILD:       docker build -rm -t scribe .
# TO_RUN:         docker run -p 1463:1463 scribe

FROM ubuntu:12.04

MAINTAINER elprup, Version: 0.1.0

RUN apt-get update; \
     apt-get -y install make libboost-all-dev libboost-test-dev libboost-program-options-dev libevent-dev automake libtool flex bison pkg-config g++ libssl-dev git-core

RUN git clone -b 0.9.1 https://github.com/apache/thrift.git

RUN cd /thrift && ./bootstrap.sh && ./configure --with-java=no --with-erlang=no --with-php=no --with-perl=no --with-php_extension=no --with-ruby=no --with-haskell=no --with-go=no && make && make install 

RUN cd /thrift/contrib/fb303 && ./bootstrap.sh && ./configure --without-java --without-php && make && make install && cd py && python setup.py install && make distclean

RUN git clone https://github.com/elprup/scribe.git 

RUN apt-get -y --no-install-recommends install wget openjdk-7-jdk ant

RUN cd /root && wget https://archive.apache.org/dist/hadoop/core/hadoop-1.0.3/hadoop-1.0.3.tar.gz; tar xzvf hadoop-1.0.3.tar.gz

RUN cd /root/hadoop-1.0.3 && export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64 && ant compile-c++-libhdfs -Dislibhdfs=true

# if you use origin facebook scribe do following
#RUN sed -i 's/hdfsConnectNewInstance/hdfsConnect/g' /scribe/src/HdfsFile.cpp
# comment throw std::runtime_error("hdfsExists call failed");  in HdfsFile.cpp

RUN ln -s /usr/lib/jvm/java-7-openjdk-amd64/jre/lib/amd64/server/libjvm.so /usr/lib/libjvm.so && ln -s /root/hadoop-1.0.3/c++/Linux-amd64-64/lib/libhdfs.so /usr/lib/libhdfs.so && ln -s /root/hadoop-1.0.3/c++/Linux-amd64-64/lib/libhdfs.so.0 /usr/lib/libhdfs.so.0

RUN cd /scribe && ./bootstrap.sh && ./configure --enable-hdfs CPPFLAGS="-DHAVE_INTTYPES_H -DHAVE_NETINET_IN_H -DBOOST_FILESYSTEM_VERSION=2 -I/root/hadoop-1.0.3/src/c++/libhdfs -I/usr/lib/jvm/java-7-openjdk-amd64/include -I/usr/lib/jvm/java-7-openjdk-amd64/include/linux" LIBS="-lboost_system -lboost_filesystem"  && make && make install && cd lib/py && python setup.py install && make distclean

ENV HADOOP_HOME=/root/hadoop-1.0.3

ENV JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64

ENV CLASSPATH=`$HADOOP_HOME/bin/hadoop classpath`

RUN mkdir /var/lib/scribe/

ADD config/scribe.conf /etc/

# expose scribe
EXPOSE 1463

RUN ldconfig

CMD ["/usr/local/bin/scribed", "-c", "/etc/scribe.conf"]
