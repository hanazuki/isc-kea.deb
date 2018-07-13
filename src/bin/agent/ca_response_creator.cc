// Copyright (C) 2017-2018 Internet Systems Consortium, Inc. ("ISC")
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#include <config.h>

#include <agent/ca_command_mgr.h>
#include <agent/ca_response_creator.h>
#include <cc/data.h>
#include <http/post_request_json.h>
#include <http/response_json.h>
#include <boost/pointer_cast.hpp>
#include <iostream>

using namespace isc::data;
using namespace isc::http;

namespace isc {
namespace agent {

HttpRequestPtr
CtrlAgentResponseCreator::createNewHttpRequest() const {
    return (HttpRequestPtr(new PostHttpRequestJson()));
}

HttpResponsePtr
CtrlAgentResponseCreator::
createStockHttpResponse(const ConstHttpRequestPtr& request,
                        const HttpStatusCode& status_code) const {
    HttpResponsePtr response = createStockHttpResponseInternal(request, status_code);
    response->finalize();
    return (response);
}

HttpResponsePtr
CtrlAgentResponseCreator::
createStockHttpResponseInternal(const ConstHttpRequestPtr& request,
                                const HttpStatusCode& status_code) const {
    // The request hasn't been finalized so the request object
    // doesn't contain any information about the HTTP version number
    // used. But, the context should have this data (assuming the
    // HTTP version is parsed ok).
    HttpVersion http_version(request->context()->http_version_major_,
                             request->context()->http_version_minor_);
    // We only accept HTTP version 1.0 or 1.1. If other version number is found
    // we fall back to HTTP/1.0.
    if ((http_version < HttpVersion(1, 0)) || (HttpVersion(1, 1) < http_version)) {
        http_version.major_ = 1;
        http_version.minor_ = 0;
    }
    // This will generate the response holding JSON content.
    HttpResponsePtr response(new HttpResponseJson(http_version, status_code));
    return (response);
}

HttpResponsePtr
CtrlAgentResponseCreator::
createDynamicHttpResponse(const ConstHttpRequestPtr& request) {
    // The request is always non-null, because this is verified by the
    // createHttpResponse method. Let's try to convert it to the
    // ConstPostHttpRequestJson type as this is the type generated by the
    // createNewHttpRequest. If the conversion result is null it means that
    // the caller did not use createNewHttpRequest method to create this
    // instance. This is considered an error in the server logic.
    ConstPostHttpRequestJsonPtr request_json = boost::dynamic_pointer_cast<
        const PostHttpRequestJson>(request);
    if (!request_json) {
        // Notify the client that we have a problem with our server.
        return (createStockHttpResponse(request, HttpStatusCode::INTERNAL_SERVER_ERROR));
    }

    // We have already checked that the request is finalized so the call
    // to getBodyAsJson must not trigger an exception.
    ConstElementPtr command = request_json->getBodyAsJson();

    // Process command doesn't generate exceptions but can possibly return
    // null response, if the handler is not implemented properly. This is
    // again an internal server issue.
    ConstElementPtr response = CtrlAgentCommandMgr::instance().processCommand(command);
    if (!response) {
        // Notify the client that we have a problem with our server.
        return (createStockHttpResponse(request, HttpStatusCode::INTERNAL_SERVER_ERROR));
    }
    // The response is ok, so let's create new HTTP response with the status OK.
    HttpResponseJsonPtr http_response = boost::dynamic_pointer_cast<
        HttpResponseJson>(createStockHttpResponseInternal(request, HttpStatusCode::OK));
    http_response->setBodyAsJson(response);
    http_response->finalize();

    return (http_response);
}



} // end of namespace isc::agent
} // end of namespace isc
