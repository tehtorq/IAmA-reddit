var Request;
var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
Request = (function() {
  function Request(callback) {
    this.callback = callback;
  }
  Request.prototype.request = function(url, method, params, token) {
    var request;
    Mojo.Log.info(url + "," + method + "," + Object.toJSON(params));
    request = new Ajax.Request(url, {
      method: method,
      parameters: params,
      onSuccess: __bind(function(inTransport) {
        return this.handleResponse(token, inTransport, true);
      }, this),
      onFailure: __bind(function(inTransport) {
        return this.handleResponse(token, inTransport, true);
      }, this),
      onException: __bind(function(inTransport, inException) {
        return this.handleResponse(token, inTransport, true);
      }, this)
    });
    return Request.store.push(request);
  };
  Request.prototype.get = function(url, params, success, failure) {
    return this.request(url, 'get', params, success, failure);
  };
  Request.prototype.post = function(url, params, success, failure) {
    if (params.uh == null) {
      new Banner("Not logged in.").send();
      return;
    }
    return this.request(url, 'post', params, success, failure);
  };
  Request.prototype.handleResponse = function(token, response, success) {
    if (this.callback != null) {
      return this.callback.handleCallback({
        type: token,
        response: response,
        success: success
      });
    } else {
      return Mojo.Controller.getAppController().sendToNotificationChain({
        type: token,
        response: response,
        success: success
      });
    }
  };
  Request.store = [];
  Request.clear_all = function() {
    _.each(this.store, function(request) {
      Mojo.Log.info("aborting request");
      return request.transport.abort();
    });
    return this.store.length = 0;
  };
  return Request;
})();