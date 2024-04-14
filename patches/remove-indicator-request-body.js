/* eslint-disable */

function patch(schema) {
  delete schema['paths']['/indicator']['get']['requestBody']

  return schema
}

module.exports = patch
