#set -x

#The following environment variable are assumed to be set properly (e.g. via Jenkins job parameters)
#export ITERATIONS=100000
#export THREADS=30
#export USERS=300
#export SERVER_HOST=localhost
#export SERVER_PORT=80
#export DURATION=43200
#export ADDITIONAL_PERFREPO_TAGS=soak

export JAVA_HOME=/qa/tools/opt/x86_64/jdk1.8.0_last;
export M2_HOME=/qa/tools/opt/apache-maven-3.3.9
export PATH=$PATH:$JAVA_HOME/bin:$M2_HOME/bin;

export MAVEN_OPTS="-Dmaven.repo.local=$WORKSPACE/local-maven-repo"

echo "Running against the $SERVER_HOST:$SERVER_PORT instance"

cd $WORKSPACE

if [[ "$SERVER_HOST" == "localhost" ]];
then
	echo "Need a local server - preparing Docker containers..."

	# Clean docker containers
	for i in `docker ps -a -q`; do docker rm -f $i; done
	for i in `docker volume ls -q`; do docker volume rm $i; done

	# Build the core server that will provide our test client with tokens

	# Download the core
	rm -rf almighty-core*
	git clone https://github.com/almighty/almighty-core.git
	cd almighty-core

	# Run the DB docker image (detached) that the core requires
	docker run --name db -d -p 5432 -e POSTGRESQL_ADMIN_PASSWORD=mysecretpassword centos/postgresql-95-centos7

	# Cleanup and then build the docker core image
	make docker-rm
	sleep 10
	make docker-start
	sleep 10
	make docker-build
	sleep 10
	make docker-image-deploy
	sleep 10

	# Run the docker core image (detached)
	docker run -p $SERVER_PORT:8080 --name core -d -e ALMIGHTY_DEVELOPER_MODE_ENABLED=true -e ALMIGHTY_POSTGRES_HOST=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' db 2>/dev/null) almighty-core-deploy
fi

while true;
do
   echo "Checking if the Core server is up and running ..."
   curl -silent http://$SERVER_HOST:$SERVER_PORT/api/status
   [[ $? -eq 0 ]] && break
   echo "The Core server is not responding, trying again after 10s."
   sleep 10
done
CORE_SERVER_STATUS=`curl -silent http://$SERVER_HOST:$SERVER_PORT/api/status | grep commit | sed -e 's,":",=,g' | sed -e 's,[{"}],,g' | sed -e 's,\,,;,g'`
BASE_PERFREPO_TAGS="$ADDITIONAL_PERFREPO_TAGS;server=$SERVER_HOST:$SERVER_PORT;$CORE_SERVER_STATUS"

cd $WORKSPACE

NOW=`date +%s`
STOP=`expr $NOW + $DURATION`
export CYCLE=0

chmod +x crud-perf-test.sh
while [ `date +%s` -lt $STOP ];
do
	export ADDITIONAL_PERFREPO_TAGS="$BASE_PERFREPO_TAGS;soak-cycle=$CYCLE;timestamp="`date +%s`
	./crud-perf-test.sh;
    export CYCLE=`expr $CYCLE + 1`
done

# Do not clean docker containers - for the debugging purposes
#if [[ "$SERVER_HOST" == "localhost" ]];
#then
#  for i in `docker ps -a -q`; do docker rm -f $i; done
#  for i in `docker volume ls -q`; do docker volume rm $i; done
#fi