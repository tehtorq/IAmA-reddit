
Request = Class.create({

  initialize: function(callback) {
    this.callback = callback;
  },

  request: function(url, method, params, token) {
    Mojo.Log.info(url + "," + method + "," + Object.toJSON(params));
    
    var request = new Ajax.Request(
      url,
      {
        method : method,
        parameters: params,
        onSuccess : function(inTransport) {this.handleResponse(token, inTransport, true);}.bind(this),
        onFailure : function(inTransport) {this.handleResponse(token, inTransport, true);}.bind(this),
        onException : function(inTransport, inException) {this.handleResponse(token, inTransport, true);}.bind(this)
      }
    )

    Request.store.push(request);
  },

  get: function(url, params, success, failure) {
    this.request(url, 'get', params, success, failure);
  },

  post: function(url, params, success, failure) {
    if (params.uh == undefined) {
      new Banner("Not logged in.").send();
      return;
    }
    
    this.request(url, 'post', params, success, failure);
  },

  handleResponse: function(token, response, success) {
    if (this.callback != undefined) {      
      this.callback.handleCallback({type: token, response: response, success: success});
    }
    else {
       Mojo.Controller.getAppController().sendToNotificationChain({type: token, response: response, success: success});
    }
  }

});

Request.store = [];

Request.clear_all = function() {
  for (var i = 0; i < Request.store.length; i++) {
    Mojo.Log.info("aborting request");
    Request.store[i].transport.abort();
  }

  Request.store.length = 0;
}