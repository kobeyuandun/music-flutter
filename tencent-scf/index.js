const api = require('./src/service/api.js');

function parseQuery(event) {
    // SCF Function URL: queryString is an object { key: value }
    if (event.queryString && typeof event.queryString === 'object' && !Array.isArray(event.queryString)) {
        return event.queryString;
    }
    // API Gateway 2.0 / SCF standard
    if (event.queryStringParameters && typeof event.queryStringParameters === 'object') {
        return event.queryStringParameters;
    }
    // API Gateway 1.0: queryString is a raw string like "a=1&b=2"
    if (event.queryString && typeof event.queryString === 'string') {
        const params = {};
        const search = new URLSearchParams(event.queryString);
        for (const [key, value] of search) {
            params[key] = value;
        }
        return params;
    }
    // Fallback: some versions put it directly in queryParameters
    if (event.queryParameters && typeof event.queryParameters === 'object') {
        return event.queryParameters;
    }
    return {};
}

exports.main_handler = async (event, context) => {
    // Normalize event for compatibility
    const normalizedEvent = {
        ...event,
        queryStringParameters: parseQuery(event),
    };

    // Handle CORS preflight
    const method = (event.httpMethod || event.requestContext?.http?.method || 'GET').toUpperCase();
    if (method === 'OPTIONS') {
        return {
            statusCode: 204,
            headers: {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
                'Access-Control-Allow-Headers': '*',
            },
            body: '',
        };
    }

    const result = await api(normalizedEvent);

    // Ensure CORS headers are present
    const headers = result.headers || {};
    headers['Access-Control-Allow-Origin'] = '*';
    headers['Access-Control-Allow-Methods'] = 'GET, POST, OPTIONS';
    headers['Access-Control-Allow-Headers'] = '*';
    result.headers = headers;

    // API Gateway expects body as string
    if (result.body && typeof result.body !== 'string') {
        result.body = JSON.stringify(result.body);
    }

    return result;
};
