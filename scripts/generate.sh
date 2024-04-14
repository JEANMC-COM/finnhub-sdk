#!/bin/sh
# cSpell:ignore modelerfour

FORCE_GEN="0"
if [ "$1" = "--force" ]; then
  FORCE_GEN="1"
fi

if [ "$SWAGGER_CONVERT_API" = "" ]; then
  SWAGGER_CONVERT_API=https://converter.swagger.io/api/convert
fi

if [ "$AUTOREST_OUTPUT_FOLDER" = "" ]; then
  AUTOREST_OUTPUT_FOLDER=./packages/generated
fi

if [ ! -d ./tmp ]; then
  mkdir ./tmp
fi

FINNHUB_SWAGGER_FILE=https://finnhub.io/static/swagger.json
SWAGGER_TMP=./tmp/swagger-temp.json
SWAGGER_FILE=./tmp/swagger.json

check_error () {
  if [ $? -ne 0 ]; then
    echo "Failed to fetch API swagger file"
    exit 1
  fi
}

echo "======================================================================================================"
echo " Fetching API swagger file"
echo "======================================================================================================"
curl --fail-with-body $FINNHUB_SWAGGER_FILE > $SWAGGER_TMP
check_error

echo "======================================================================================================"
echo " Converting to OpenAPI 3"
echo "======================================================================================================"
cat $SWAGGER_TMP | curl --fail-with-body -H 'Content-Type: application/json' -X POST --data-binary @- $SWAGGER_CONVERT_API > $SWAGGER_FILE
check_error

echo "======================================================================================================"
echo " Included endpoints"
echo "======================================================================================================"
ENDPOINTS=$(node -p "Object.keys(require(\"$SWAGGER_FILE\").paths).sort()")
node -p "JSON.stringify($ENDPOINTS, null, 4)"

SHA_EXE=$(which sha1sum)
if [ $? -eq 1 ]; then
  SHA_EXE="$(which shasum)"
fi

BUILD_HASH=$(echo $ENDPOINTS | $SHA_EXE | cut -d' ' -f1)
PKG_INFO=$(yarn npm info @jeanmc/finnhub-sdk --json 2>&1 | head -n 1)
PKG_INFO_ERROR=$(node -p "JSON.parse('$PKG_INFO')?.type === 'error'")
PKG_INFO_ERROR_MSG=$(node -p "JSON.parse('$PKG_INFO')?.data ?? ''")
BUILD_HASH_EXISTS=$(node -p "Object.keys(JSON.parse('$PKG_INFO')?.['dist-tags'] ?? {}).includes('$BUILD_HASH')")
DEPLOY_VERSION=$(node -p "JSON.parse('$PKG_INFO')?.version ?? ''")

if [ "$PKG_INFO_ERROR" = "true" ] && [ "$PKG_INFO_ERROR_MSG" != "Package not found" ]; then
  echo "======================================================================================================"
  echo " Failed with error: $PKG_INFO_ERROR_MSG"
  echo "======================================================================================================"
  exit 1
fi

if [ "$FORCE_GEN" = "0" ] && [ "$BUILD_HASH_EXISTS" = "true" ]; then
  echo "======================================================================================================"
  echo " Finnhub API version already existed: $DEPLOY_VERSION"
  echo "======================================================================================================"
  exit 0
fi

if [ "$DEPLOY_VERSION" != "" ]; then
  DEPLOY_VERSION=$(semver --increment minor $DEPLOY_VERSION)
else
  DEPLOY_VERSION="1.0.0"
fi

echo "======================================================================================================"
echo " Applying patches"
echo "======================================================================================================"

cat $SWAGGER_FILE | sed -e 's/\\n/\\\\n/g' > $SWAGGER_TMP
cat $SWAGGER_TMP > $SWAGGER_FILE

for file in ./patches/*.js; do
  echo "Applying '$(basename $file)'"
  node -p "const schema=require(\"./$SWAGGER_FILE\"); const patch=require(\"./$file\"); JSON.stringify(patch(schema));" > $SWAGGER_TMP
  cat $SWAGGER_TMP > $SWAGGER_FILE
done

echo "======================================================================================================"
echo " Generating Finnhub API version: $DEPLOY_VERSION"
echo " Build Hash: $BUILD_HASH"
echo "======================================================================================================"

autorest ./config-file.yml \
  --add-credentials=false \
  --azure-sdk-for-js=false \
  --input-file=$SWAGGER_FILE \
  --output-folder=$AUTOREST_OUTPUT_FOLDER \
  --package-version=$DEPLOY_VERSION \
  --use:@autorest/modelerfour \
  --use:@autorest/typescript

cp ./.npmignore $AUTOREST_OUTPUT_FOLDER/

node -p "const pkgInfo=require(\"$AUTOREST_OUTPUT_FOLDER/package.json\"); pkgInfo.buildHash='$BUILD_HASH'; JSON.stringify(pkgInfo, null, 2);" > $AUTOREST_OUTPUT_FOLDER/package-temp.json
mv $AUTOREST_OUTPUT_FOLDER/package-temp.json $AUTOREST_OUTPUT_FOLDER/package.json
