# #!/bin/sh

OBJ=$(cat << EOF
{
  "200": {
    "content": {
      "application/oct-stream": {
        "schema": {
          "format": "binary",
          "type": "string"
        }
      }
    },
    "description": "successful operation"
  }
}
EOF
)
OBJ=$(echo $OBJ | tr "\n" " " | tr -d " ")

DATA=$(cat $SWAGGER_FILE_V3)
DATA=$(echo $DATA | jq --argjson obj $OBJ '.paths["/global-filings/download"]["get"]["responses"] = $obj')

echo $DATA | sed -e 's/\\n/\\\\n/g' > $SWAGGER_FILE_V3
