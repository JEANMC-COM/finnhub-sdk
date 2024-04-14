/* eslint-disable */

function patch(schema) {
  schema['components']['schemas']['EconomicEvent'] = schema['components']['schemas']['Economic event']
  delete schema['components']['schemas']['Economic event']

  schema['components']['schemas']['EconomicCalendar']['properties']['economicCalendar']['items']['$ref'] =
    '#/components/schemas/EconomicEvent'

  return schema
}

module.exports = patch
