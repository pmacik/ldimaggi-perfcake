## Needed ENV Variables
#export WORKSPACE=$PWD
#export ITERATIONS=1000
#export THREADS=10
#export USERS=10 # keep it 1 until https://github.com/PerfCake/PerfCake/issues/379 is fixed
#export SERVER_HOST=api-perf.dev.rdu2c.fabric8.io
#export SERVER_PORT=80

## Actuall test

export PERFCAKE_VERSION=8.0-SNAPSHOT
export PERFCAKE_HOME=$WORKSPACE/perfcake-$PERFCAKE_VERSION

export PERFORMANCE_RESULTS=$WORKSPACE/devtools-performance-results

export TOKEN_LIST=$PERFORMANCE_RESULTS/token.keys
export WORK_ITEM_IDS=$PERFORMANCE_RESULTS/workitem-id.list
export POC_RESULTS=$PERFORMANCE_RESULTS/poc-results.log

# Get Perfcake, and our preconfigured Perfcake test config file
git clone -b devel  https://github.com/PerfCake/PerfCake PerfCake.git
cd PerfCake.git
git checkout c887baaa13b640dc83ef7203f79d8c4818512aa4
cd ..
mvn -f PerfCake.git/pom.xml clean package assembly:single -DskipTests
rm -rf $PERFCAKE_HOME
unzip PerfCake.git/perfcake/target/perfcake-$PERFCAKE_VERSION-bin.zip
rm -rvf PerfCake.git
cp create.xml $PERFCAKE_HOME/resources/scenarios/
cp read.xml $PERFCAKE_HOME/resources/scenarios/
cp update.xml $PERFCAKE_HOME/resources/scenarios/
cp delete.xml $PERFCAKE_HOME/resources/scenarios/

# Run the test (prepare clean env)
rm -rf $PERFORMANCE_RESULTS
mkdir -p $PERFORMANCE_RESULTS

# Parse/extract the token for the test
for i in $(seq 1 $USERS);
do
   auth_resp=$(curl --silent -X GET --header 'Accept: application/json' 'http://'$SERVER_HOST':'$SERVER_PORT'/api/login/generate')
   token=$(echo $auth_resp | cut -d ":" -f 3 | sed -e 's/","expires_in//g' | sed -e 's/"//g');
   echo $token >> $TOKEN_LIST;
done

# Run the test - single token == single user
export PERFCAKE_PROPS="-Dthread.count=$THREADS -Diteration.count=$ITERATIONS -Dworkitemid.list=file:$WORK_ITEM_IDS -Dauth.token.list=file:$TOKEN_LIST -Dserver.host=$SERVER_HOST -Dserver.port=$SERVER_PORT"

#workaround for https://github.com/PerfCake/PerfCake/issues/379
#export PERFCAKE_PROPS="-Dthread.count=$THREADS -Diteration.count=$ITERATIONS -Dworkitemid.list=file:$WORK_ITEM_IDS -Dauth.token=$token -Dserver.host=$SERVER_HOST -Dserver.port=$SERVER_PORT"

echo "Running $ITERATIONS iterations with $THREADS threads" >> $POC_RESULTS

# Get a baseline of workitems in DB
echo "BEFORE:" >> $POC_RESULTS
curl -silent -X GET --header 'Accept: application/json' 'http://'$SERVER_HOST':'$SERVER_PORT'/api/workitems' |  sed s/.*totalCount/\\n\\n\\n"totalCount of workitems in DB"/g | sed s/\"//g | sed s/}//g| grep totalCount >> $POC_RESULTS

# (C)RUD
$PERFCAKE_HOME/bin/perfcake.sh -s create $PERFCAKE_PROPS
cat $PERFCAKE_HOME/perfcake-validation.log | grep Response | sed -e 's,.*/api/workitems/\([^"/]*\)/.*".*,\1,g' > $WORK_ITEM_IDS
cat $PERFCAKE_HOME/create-average-throughput.csv
mv $PERFCAKE_HOME/create-average-throughput.csv $PERFORMANCE_RESULTS
#mv $PERFCAKE_HOME/perfcake-validation.log $PERFORMANCE_RESULTS/perfcake-validation-create.log
rm -vf $PERFCAKE_HOME/perfcake-validation.log
mv $PERFCAKE_HOME/perfcake.log $PERFORMANCE_RESULTS/perfcake-create.log

echo "After CREATE:" >> $POC_RESULTS
curl -silent -X GET --header 'Accept: application/json' 'http://'$SERVER_HOST':'$SERVER_PORT'/api/workitems' |  sed s/.*totalCount/\\n\\n\\n"totalCount of workitems in DB"/g | sed s/\"//g | sed s/}//g| grep totalCount >> $POC_RESULTS

# C(R)UD
$PERFCAKE_HOME/bin/perfcake.sh -s read $PERFCAKE_PROPS
cat $PERFCAKE_HOME/read-average-throughput.csv
mv $PERFCAKE_HOME/read-average-throughput.csv $PERFORMANCE_RESULTS
#mv $PER	FCAKE_HOME/perfcake-validation.log $PERFORMANCE_RESULTS/perfcake-validation-read.log
rm -vf $PERFCAKE_HOME/perfcake-validation.log
mv $PERFCAKE_HOME/perfcake.log $PERFORMANCE_RESULTS/perfcake-read.log

echo "After READ:" >> $POC_RESULTS
curl -silent -X GET --header 'Accept: application/json' 'http://'$SERVER_HOST':'$SERVER_PORT'/api/workitems' |  sed s/.*totalCount/\\n\\n\\n"totalCount of workitems in DB"/g | sed s/\"//g | sed s/}//g| grep totalCount >> $POC_RESULTS

# CR(U)D
#TODO: Coming soon...
#$PERFCAKE_HOME/bin/perfcake.sh -s update $PERFCAKE_PROPS
#cat $PERFCAKE_HOME/update-average-throughput.csv
#mv $PERFCAKE_HOME/update-average-throughput.csv $PERFORMANCE_RESULTS
#mv $PERFCAKE_HOME/perfcake-validation.log $PERFORMANCE_RESULTS/perfcake-validation-update.log
#rm -vf $PERFCAKE_HOME/perfcake-validation.log
#mv $PERFCAKE_HOME/perfcake.log $PERFORMANCE_RESULTS/perfcake-update.log

echo "After UPDATE:" >> $POC_RESULTS
curl -silent -X GET --header 'Accept: application/json' 'http://'$SERVER_HOST':'$SERVER_PORT'/api/workitems' |  sed s/.*totalCount/\\n\\n\\n"totalCount of workitems in DB"/g | sed s/\"//g | sed s/}//g| grep totalCount >> $POC_RESULTS

# CRU(D)
$PERFCAKE_HOME/bin/perfcake.sh -s delete $PERFCAKE_PROPS
cat $PERFCAKE_HOME/delete-average-throughput.csv
mv $PERFCAKE_HOME/delete-average-throughput.csv $PERFORMANCE_RESULTS
#mv $PERFCAKE_HOME/perfcake-validation.log $PERFORMANCE_RESULTS/perfcake-validation-delete.log
rm -vf $PERFCAKE_HOME/perfcake-validation.log
mv $PERFCAKE_HOME/perfcake.log $PERFORMANCE_RESULTS/perfcake-delete.log

echo "After DELETE:" >> $POC_RESULTS
curl -silent -X GET --header 'Accept: application/json' 'http://'$SERVER_HOST':'$SERVER_PORT'/api/workitems' |  sed s/.*totalCount/\\n\\n\\n"totalCount of workitems in DB"/g | sed s/\"//g | sed s/}//g| grep totalCount >> $POC_RESULTS

cat $POC_RESULTS

# Copy the PerfCake results to the jenkins' workspace to be able to archive
cp -rvf $PERFCAKE_HOME/perfcake-chart $PERFORMANCE_RESULTS

