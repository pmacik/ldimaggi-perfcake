#!/usr/bin/bash

# set -x

token=$(curl --silent -X GET --header 'Accept: application/json' 'http://localhost:8080/api/login/generate' | cut -d ":" -f 3 | sed -e 's/","expires_in//g' | sed -e 's/"//g')

# echo $token

sed -e "s/THETOKEN/$token/g" perfcake-7.3/resources/scenarios/input.xml > perfcake-7.3/resources/scenarios/output.xml

$PERFCAKE_HOME/bin/perfcake.sh -s output.xml -Dthread.count=10 




