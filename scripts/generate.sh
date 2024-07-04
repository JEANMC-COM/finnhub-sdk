#!/bin/sh
# cSpell:ignore modelerfour

if [ "$SWAGGER_FILE_URL" = "" ]; then
  echo "No swagger file url"
  exit 1
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

SWAGGER_FILE=./tmp/swagger.json
SWAGGER_FILE_V3=./tmp/swagger-v3.json

check_error () {
  if [ $? -ne 0 ]; then
    echo "There are errors. Exiting..."
    exit 1
  fi
}

echo "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
echo "┃ Fetching API swagger file ┃"
echo "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"

curl --fail-with-body $SWAGGER_FILE_URL > $SWAGGER_FILE
check_error

echo "┏━━━━━━━━━━━━━━━━━━━━━━━━━┓"
echo "┃ Converting to OpenAPI 3 ┃"
echo "┗━━━━━━━━━━━━━━━━━━━━━━━━━┛"

cat $SWAGGER_FILE | curl --fail-with-body -H 'Content-Type: application/json' -X POST --data-binary @- $SWAGGER_CONVERT_API | sed -e 's/\\n/\\\\n/g' > $SWAGGER_FILE_V3
check_error

echo "┏━━━━━━━━━━━━━━━━━━━━┓"
echo "┃ Included endpoints ┃"
echo "┗━━━━━━━━━━━━━━━━━━━━┛"

ENDPOINTS=$(jq '.paths | keys' $SWAGGER_FILE_V3)
echo $ENDPOINTS | jq -r '.'
check_error

SHA_EXE=$(which sha1sum)
if [ $? -eq 1 ]; then
  SHA_EXE="$(which shasum)"
fi

BUILD_HASH=$(echo $ENDPOINTS | $SHA_EXE | cut -d' ' -f1)
PKG_INFO=$(yarn npm info $PACKAGE_NAME --json 2>&1 | head -n 1)
PKG_INFO_ERROR=$(echo $PKG_INFO | jq -r '.type')
PKG_INFO_ERROR_MSG=$(echo $PKG_INFO | jq -r '.data')
BUILD_HASH_EXISTS=$(echo $PKG_INFO | jq -r '.["dist-tags"] | keys | contains(["'$BUILD_HASH'"])')
DEPLOY_VERSION=$(echo $PKG_INFO | jq -r '.version')
check_error

if [ "$PKG_INFO_ERROR" = "error" ] && [ "$PKG_INFO_ERROR_MSG" != "Package not found" ]; then
  echo "┏━━━━━━━━━━━━━━━━━━━┓"
  echo "┃ Failed with error ┃"
  echo "┗━━━━━━━━━━━━━━━━━━━┛"
  echo $PKG_INFO_ERROR_MSG
  exit 1
fi


FORCE_GEN="0"
if [ "$1" = "--force" ]; then
  FORCE_GEN="1"
fi

if [ "$FORCE_GEN" = "0" ] && [ "$BUILD_HASH_EXISTS" = "true" ]; then
  echo "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
  echo "┃ Target version is already existed ┃"
  echo "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"
  echo $DEPLOY_VERSION
  exit 0
fi

if [ "$DEPLOY_VERSION" != "null" ]; then
  DEPLOY_VERSION=$(semver --increment minor $DEPLOY_VERSION)
else
  DEPLOY_VERSION="1.0.0"
fi
check_error

echo "┏━━━━━━━━━━━━━━━━━━┓"
echo "┃ Applying patches ┃"
echo "┗━━━━━━━━━━━━━━━━━━┛"

# escape special charaters in json string
for file in ./patches/*.sh; do
  echo "Applying '$(basename $file)'"
  . $file
done
check_error

echo "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
echo "┃ Generating new API version ┃ $DEPLOY_VERSION"
echo "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"
echo "┏━━━━━━━━━━━━┓"
echo "┃ Build Hash ┃ $BUILD_HASH"
echo "┗━━━━━━━━━━━━┛"

if [ "$DEPLOY_VERSION" = "" ] && [ "$BUILD_HASH" = "" ]; then
  echo "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
  echo "┃ Empty 'version' or 'build hash' ┃"
  echo "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"
  exit 1
fi

autorest ./config-file.yml \
  --add-credentials=false \
  --azure-sdk-for-js=false \
  --input-file=$SWAGGER_FILE_V3 \
  --output-folder=$AUTOREST_OUTPUT_FOLDER \
  --package-name=$PACKAGE_NAME \
  --package-version=$DEPLOY_VERSION \
  --use=@autorest/modelerfour \
  --use=@autorest/typescript
check_error

git apply ./patches/rollup.config.patch

cp ./.npmignore $AUTOREST_OUTPUT_FOLDER/
cd $AUTOREST_OUTPUT_FOLDER

FILE=$(cat ./package.json)
echo $FILE | jq '.buildHash = "'$BUILD_HASH'"' > ./package.json

if [ "$PACKAGE_PUBLISH" = "true" ]; then
  yarn workspace $PACKAGE_NAME add -D builtin-modules @types/node
  yarn npm publish && sleep 10
  yarn npm tag add $PACKAGE_NAME@$DEPLOY_VERSION $BUILD_HASH
fi
