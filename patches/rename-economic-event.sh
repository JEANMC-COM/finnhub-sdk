#!/bin/sh

DATA=$(cat $SWAGGER_FILE_V3)
DATA=$(echo $DATA | jq '.components["schemas"]["EconomicEvent"] = .components["schemas"]["Economic event"]')
DATA=$(echo $DATA | jq '.components["schemas"]["EconomicCalendar"]["properties"]["economicCalendar"]["items"]["$ref"] = "#/components/schemas/EconomicEvent"')
DATA=$(echo $DATA | jq 'del(.components["schemas"]["Economic event"])')

echo $DATA | sed -e 's/\\n/\\\\n/g' > $SWAGGER_FILE_V3
