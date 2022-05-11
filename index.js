const url = require('url');

exports.handler = async (event, context) => {
    const request = event.Records[0].cf.request;

    var params = new URLSearchParams(request.querystring);
    params.set("_elServingDomain", request.headers.host[0].value);
    request.querystring = params.toString();

    return request;
};
