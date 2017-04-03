#set -x

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

if [[ "x$CYCLE" != "x" ]];
then
   export PERFORMANCE_RESULTS=$WORKSPACE/devtools-performance-results/$CYCLE;
else
   export PERFORMANCE_RESULTS=$WORKSPACE/devtools-performance-results;
fi

# Prepare clean environment
rm -rf $PERFORMANCE_RESULTS
mkdir -p $PERFORMANCE_RESULTS

export TOKEN_LIST=$PERFORMANCE_RESULTS/token.keys
export WORK_ITEM_IDS=$PERFORMANCE_RESULTS/workitem-id.list
export POC_RESULTS=$PERFORMANCE_RESULTS/poc-results.log

# Get Perfcake, and our preconfigured Perfcake test config file
if [[ "x$CYCLE" < "x1" ]];
then
   rm -rf PerfCake.git
   git clone -b devel  https://github.com/PerfCake/PerfCake PerfCake.git;
   cd PerfCake.git;
   git checkout f33795c8a3e2a4285e5b4a22cf4affcbb7785469;
   cd ..;
   echo "Building PerfCake..."
   mvn -f PerfCake.git/pom.xml clean install assembly:single -DskipTests 2>&1 > $PERFORMANCE_RESULTS/perfcake-build-maven.log

   rm -rf Plugins.git
   git clone https://github.com/PerfCake/Plugins Plugins.git;
   echo "Building PerfRepo Destination plugin..."
   mvn -f Plugins.git/perfrepo-destination/pom.xml clean install -DskipTests 2>&1 > $PERFORMANCE_RESULTS/perfrepo-destination-build-maven.log
   echo "Building HttpClientSender plugin..."
   mvn -f Plugins.git/httpclient-sender/pom.xml clean install -DskipTests 2>&1 > $PERFORMANCE_RESULTS/httpclient-sender-build-maven.log
fi

rm -rf $PERFCAKE_HOME;
unzip -q PerfCake.git/perfcake/target/perfcake-$PERFCAKE_VERSION-bin.zip;
cp -rf Plugins.git/perfrepo-destination/target/perfrepo-*.jar $PERFCAKE_HOME/lib/plugins/;
cp -rf Plugins.git/perfrepo-destination/target/lib/*.jar $PERFCAKE_HOME/lib/plugins/;
cp -rf Plugins.git/httpclient-sender/target/httpclient-*.jar $PERFCAKE_HOME/lib/plugins/;
cp -rf Plugins.git/httpclient-sender/target/lib/*.jar $PERFCAKE_HOME/lib/plugins/;
cp devtools-core-crud-create.xml $PERFCAKE_HOME/resources/scenarios/;
cp devtools-core-crud-read.xml $PERFCAKE_HOME/resources/scenarios/;
cp devtools-core-crud-update.xml $PERFCAKE_HOME/resources/scenarios/;
cp devtools-core-crud-delete.xml $PERFCAKE_HOME/resources/scenarios/;

# Get the work items space ID
spaces_resp=`curl -silent -X GET --header 'Accept: application/json' 'http://'$SERVER_HOST':'$SERVER_PORT'/api/spaces'`
export WORK_ITEMS_SPACE=`echo $spaces_resp | grep self | sed -e 's,.*"self":"[^"]*/api/spaces/\([^"]*\)".*,\1,g'`

export WORK_ITEMS_BASE_URI="api/spaces/$WORK_ITEMS_SPACE/workitems"
export WORK_ITEMS_URI="http://$SERVER_HOST:$SERVER_PORT/$WORK_ITEMS_BASE_URI"

if [[ "x$CYCLE" != "x" ]];
then
   echo "==========================================" >> $POC_RESULTS;
   echo "Cycle # $CYCLE:" >> $POC_RESULTS;
fi
echo "Running $ITERATIONS iterations with $THREADS threads" >> $POC_RESULTS

# Get a baseline of workitems in DB
echo "BEFORE:" >> $POC_RESULTS
curl -silent -X GET --header 'Accept: application/json' $WORK_ITEMS_URI |  sed s/.*totalCount/\\n\\n\\n"totalCount of workitems in DB"/g | sed s/\"//g | sed s/}//g| grep totalCount >> $POC_RESULTS

export PERFREPO_TAGS="threads=$THREADS;iterations=$ITERATIONS;users=$USERS;jenkins=$BUILD_TAG"
if [[ "x$ADDITIONAL_PERFREPO_TAGS" != "x" ]];
then
   export PERFREPO_TAGS="$PERFREPO_TAGS;$ADDITIONAL_PERFREPO_TAGS";
fi
export PERFCAKE_PROPS="-Dthread.count=$THREADS -Diteration.count=$ITERATIONS -Dworkitems.space.id=$WORK_ITEMS_SPACE -Dworkitemid.list=file:$WORK_ITEM_IDS -Dauth.token.list=file:$TOKEN_LIST -Dserver.host=$SERVER_HOST -Dserver.port=$SERVER_PORT -Dperfrepo.tags=$PERFREPO_TAGS -Dperfrepo.enabled=true -Dperfcake.fail.fast=false"

# (C)RUD
# Parse/extract the token for the test
bash -c ./generate-auth-tokens.sh
# Execute PerfCake
$PERFCAKE_HOME/bin/perfcake.sh -s devtools-core-crud-create $PERFCAKE_PROPS
echo "PerfCake Exited with code $?"
cat $PERFCAKE_HOME/perfcake-validation.log | grep Response | sed -e 's,.*/'$WORK_ITEMS_BASE_URI'/\([^"/]*\)/.*".*,\1,g' > $WORK_ITEM_IDS
cat $PERFCAKE_HOME/devtools-core-crud-create-average-throughput.csv
mv $PERFCAKE_HOME/devtools-core-crud-create-average-throughput.csv $PERFORMANCE_RESULTS
#mv $PERFCAKE_HOME/perfcake-validation.log $PERFORMANCE_RESULTS/perfcake-validation-create.log
rm -vf $PERFCAKE_HOME/perfcake-validation.log
mv $PERFCAKE_HOME/perfcake.log $PERFORMANCE_RESULTS/perfcake-create.log

echo "After CREATE:" >> $POC_RESULTS
curl -silent -X GET --header 'Accept: application/json' $WORK_ITEMS_URI |  sed s/.*totalCount/\\n\\n\\n"totalCount of workitems in DB"/g | sed s/\"//g | sed s/}//g| grep totalCount >> $POC_RESULTS

chmod +x ./generate-auth-tokens.sh

# C(R)UD
# Parse/extract the token for the test
bash -c ./generate-auth-tokens.sh
# Execute PerfCake
$PERFCAKE_HOME/bin/perfcake.sh -s devtools-core-crud-read $PERFCAKE_PROPS
echo "PerfCake Exited with code $?"
cat $PERFCAKE_HOME/devtools-core-crud-read-average-throughput.csv
mv $PERFCAKE_HOME/devtools-core-crud-read-average-throughput.csv $PERFORMANCE_RESULTS
#mv $PERFCAKE_HOME/perfcake-validation.log $PERFORMANCE_RESULTS/perfcake-validation-read.log
rm -vf $PERFCAKE_HOME/perfcake-validation.log
mv $PERFCAKE_HOME/perfcake.log $PERFORMANCE_RESULTS/perfcake-read.log

echo "After READ:" >> $POC_RESULTS
curl -silent -X GET --header 'Accept: application/json' $WORK_ITEMS_URI |  sed s/.*totalCount/\\n\\n\\n"totalCount of workitems in DB"/g | sed s/\"//g | sed s/}//g| grep totalCount >> $POC_RESULTS

# CR(U)D
#TODO: Coming soon...
# Parse/extract the token for the test
bash -c ./generate-auth-tokens.sh
## Execute PerfCake
$PERFCAKE_HOME/bin/perfcake.sh -s devtools-core-crud-update $PERFCAKE_PROPS
echo "PerfCake Exited with code $?"
cat $PERFCAKE_HOME/devtools-core-crud-update-average-throughput.csv
mv $PERFCAKE_HOME/devtools-core-crud-update-average-throughput.csv $PERFORMANCE_RESULTS
#mv $PERFCAKE_HOME/perfcake-validation.log $PERFORMANCE_RESULTS/perfcake-validation-update.log
rm -vf $PERFCAKE_HOME/perfcake-validation.log
mv $PERFCAKE_HOME/perfcake.log $PERFORMANCE_RESULTS/perfcake-update.log

echo "After UPDATE:" >> $POC_RESULTS
curl -silent -X GET --header 'Accept: application/json' $WORK_ITEMS_URI |  sed s/.*totalCount/\\n\\n\\n"totalCount of workitems in DB"/g | sed s/\"//g | sed s/}//g| grep totalCount >> $POC_RESULTS

# CRU(D)
# Parse/extract the token for the test
bash -c ./generate-auth-tokens.sh
# Execute PerfCake
$PERFCAKE_HOME/bin/perfcake.sh -s devtools-core-crud-delete $PERFCAKE_PROPS
echo "PerfCake Exited with code $?"
cat $PERFCAKE_HOME/devtools-core-crud-delete-average-throughput.csv
mv $PERFCAKE_HOME/devtools-core-crud-delete-average-throughput.csv $PERFORMANCE_RESULTS
#mv $PERFCAKE_HOME/perfcake-validation.log $PERFORMANCE_RESULTS/perfcake-validation-delete.log
rm -vf $PERFCAKE_HOME/perfcake-validation.log
mv $PERFCAKE_HOME/perfcake.log $PERFORMANCE_RESULTS/perfcake-delete.log

echo "After DELETE:" >> $POC_RESULTS
curl -silent -X GET --header 'Accept: application/json' $WORK_ITEMS_URI |  sed s/.*totalCount/\\n\\n\\n"totalCount of workitems in DB"/g | sed s/\"//g | sed s/}//g| grep totalCount >> $POC_RESULTS

cat $POC_RESULTS

# Copy the PerfCake results to the jenkins' workspace to be able to archive
cp -rvf $PERFCAKE_HOME/perfcake-chart $PERFORMANCE_RESULTS

