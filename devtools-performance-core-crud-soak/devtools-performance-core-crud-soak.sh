#set +x
cd $WORKSPACE
source ./_setenv.sh

echo "Running against the $SERVER_HOST:$SERVER_PORT instance"

export STATUS_ATTEMPT=1
while true;
do
   echo "Checking if the Core server is up and running $STATUS_ATTEMPT/10..."
   curl -silent http://$SERVER_HOST:$SERVER_PORT/api/status
   [[ $STATUS_ATTEMPT -lt 11 ]] && [[ $? -eq 0 ]] && break
   export STATUS_ATTEMPT=`expr $STATUS_ATTEMPT + 1`
   echo "The Core server is not responding, trying again after 10s."
   sleep 10
done
CORE_SERVER_STATUS=`curl -silent http://$SERVER_HOST:$SERVER_PORT/api/status | grep commit | sed -e 's,":",=,g' | sed -e 's,[{"}],,g' | sed -e 's,\,,;,g'`
BASE_PERFREPO_TAGS="$ADDITIONAL_PERFREPO_TAGS;server=$SERVER_HOST:$SERVER_PORT;$CORE_SERVER_STATUS"
export CORE_SERVER_COMMIT=`echo $CORE_SERVER_STATUS | sed -e 's,.*commit=\([^;]*\);.*,\1,g'`

NOW=`date +%s`
STOP=`expr $NOW + $DURATION`
export CYCLE=0

chmod +x crud-perf-test.sh
while [ `date +%s` -lt $STOP ];
do
	export SOAK_TIMESTAMP=`date +%s`
	export ADDITIONAL_PERFREPO_TAGS="$BASE_PERFREPO_TAGS;soak-cycle=$CYCLE;timestamp=$SOAK_TIMESTAMP"
	./crud-perf-test.sh;
	export CYCLE=`expr $CYCLE + 1`
done
