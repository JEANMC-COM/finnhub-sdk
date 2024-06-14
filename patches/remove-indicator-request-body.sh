#!/bin/sh

DATA=$(cat $SWAGGER_FILE_V3)
DATA=$(echo $DATA | jq 'del(.paths["/indicator"]["get"]["requestBody"])')

echo $DATA | sed -e 's/\\n/\\\\n/g' > $SWAGGER_FILE_V3
