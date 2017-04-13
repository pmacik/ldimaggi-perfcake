FROM centos:7
MAINTAINER "Pavel Macík <pmacik@redhat.com>"
ENV LANG=en_US.utf8

USER root

RUN yum -y install java-1.8.0-openjdk-devel java-1.8.0-openjdk wget git curl make unzip maven which

# Create a non-root user and a group with the same name: "almighty"
ENV ALMIGHTY_USER_NAME=almighty
RUN useradd -s /bin/bash ${ALMIGHTY_USER_NAME}

USER $ALMIGHTY_USER_NAME

ENV ITERATIONS=10000
ENV THREADS=10
ENV USERS=100
ENV SERVER_HOST=localhost
ENV SERVER_PORT=1234
ENV DURATION=43200
ENV ADDITIONAL_PERFREPO_TAGS=soak;12h;centos-ci
ENV ZABBIX_HOST_PREFIX=PerfHost
ENV PERFREPO_ENABLED=false

ENV WORKSPACE=/home/almighty
ENV JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.121-0.b13.el7_3.x86_64/
ENV MAVEN_OPTS="-Dmaven.repo.local=$WORKSPACE/local-maven-repo"

ENV PERFCAKE_VERSION=8.0-SNAPSHOT
ENV PERFCAKE_HOME=$WORKSPACE/perfcake-$PERFCAKE_VERSION

WORKDIR /home/almighty

RUN	git clone -b devel https://github.com/PerfCake/PerfCake PerfCake.git \
		&& cd PerfCake.git \
		&& git checkout f33795c8a3e2a4285e5b4a22cf4affcbb7785469
RUN	mvn -f PerfCake.git/pom.xml clean install assembly:single -DskipTests

RUN	git clone https://github.com/PerfCake/Plugins Plugins.git
RUN	mvn -f Plugins.git/perfrepo-destination/pom.xml clean install -DskipTests
RUN	mvn -f Plugins.git/httpclient-sender/pom.xml clean install -DskipTests

COPY crud-perf-test.sh $WORKSPACE/crud-perf-test.sh
COPY devtools-core-crud-create.xml $WORKSPACE/devtools-core-crud-create.xml
COPY devtools-core-crud-delete.xml $WORKSPACE/devtools-core-crud-delete.xml
COPY devtools-core-crud-read.xml $WORKSPACE/devtools-core-crud-read.xml
COPY devtools-core-crud-update.xml $WORKSPACE/devtools-core-crud-update.xml
COPY devtools-performance-core-crud-soak.sh $WORKSPACE/devtools-performance-core-crud-soak.sh
COPY _generate-auth-tokens.sh $WORKSPACE/_generate-auth-tokens.sh
COPY _get-workitem-count.sh $WORKSPACE/_get-workitem-count.sh
COPY _setenv.sh $WORKSPACE/_setenv.sh
COPY _zabbix-process-results.sh $WORKSPACE/_zabbix-process-results.sh

RUN unzip -q $WORKSPACE/PerfCake.git/perfcake/target/perfcake-$PERFCAKE_VERSION-bin.zip \
		&& cp -rf Plugins.git/perfrepo-destination/target/perfrepo-*.jar $PERFCAKE_HOME/lib/plugins/ \
		&& cp -rf Plugins.git/perfrepo-destination/target/lib/*.jar $PERFCAKE_HOME/lib/plugins/ \
		&& cp -rf Plugins.git/httpclient-sender/target/httpclient-*.jar $PERFCAKE_HOME/lib/plugins/ \
		&& cp -rf Plugins.git/httpclient-sender/target/lib/*.jar $PERFCAKE_HOME/lib/plugins/ \
		&& cp $WORKSPACE/devtools-core-crud-create.xml $PERFCAKE_HOME/resources/scenarios/ \
		&& cp $WORKSPACE/devtools-core-crud-read.xml $PERFCAKE_HOME/resources/scenarios/ \
		&& cp $WORKSPACE/devtools-core-crud-update.xml $PERFCAKE_HOME/resources/scenarios/ \
		&& cp $WORKSPACE/devtools-core-crud-delete.xml $PERFCAKE_HOME/resources/scenarios/

USER root
RUN	chown -R $ALMIGHTY_USER_NAME:$ALMIGHTY_USER_NAME $WORKSPACE/*
RUN	rm -rf $WORKSPACE/local-maven-repo PerfCake.git Plugins.git
RUN	yum -y autoremove maven && yum clean all

USER	$ALMIGHTY_USER_NAME

#ENTRYPOINT /bin/bash
ENTRYPOINT /home/almighty/devtools-performance-core-crud-soak.sh
