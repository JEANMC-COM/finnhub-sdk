/* eslint-disable */

function patch(schema) {
  schema['paths']['/global-filings/download']['get']['responses'] = {
    200: {
      content: {
        'application/oct-stream': {
          schema: {
            format: 'binary',
            type: 'string',
          },
        },
      },
      description: 'successful operation',
    },
  }

  return schema
}

module.exports = patch
