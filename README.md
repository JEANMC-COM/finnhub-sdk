# Finnhub API client library for JavaScript

[![NPM Version](https://img.shields.io/npm/v/%40jeanmc%2Ffinnhub-sdk)](https://www.npmjs.com/package/@jeanmc/finnhub-sdk)
[![NPM Downloads](https://img.shields.io/npm/dw/%40jeanmc%2Ffinnhub-sdk)](https://www.npmjs.com/package/@jeanmc/finnhub-sdk)

This package contains an isomorphic SDK (runs both in Node.js and in browsers) for Finnhub API client.

## Getting started

### Currently supported environments

- [LTS versions of Node.js](https://github.com/nodejs/release#release-schedule)
- Latest versions of Safari, Chrome, Edge and Firefox.

See the [support policy](https://github.com/Azure/azure-sdk-for-js/blob/main/SUPPORT.md) for more details.

### Install the `@jeanmc/finnhub-sdk` package

Install the FinnhubApi client library for JavaScript with `npm`:

```bash
npm install @jeanmc/finnhub-sdk
```

```ts
const client = new FinnhubAPI()

client.pipeline.addPolicy({
    name: 'add-api-key',
    sendRequest(req, next) {
        req.headers.set('X-Finnhub-Token', '')
        return next(req)
    },
})
```

### JavaScript Bundle
To use this client library in the browser, first you need to use a bundler. For details on how to do this, please refer to the [bundling documentation](https://aka.ms/AzureSDKBundling).

### For more information about the Finnhub API, please visit:
- https://finnhub.io/static/swagger.json
- https://finnhub.io/docs/api
