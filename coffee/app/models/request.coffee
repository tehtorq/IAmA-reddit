class Request

  constructor: (callback) ->
    @callback = callback

  request: (url, method, params, token) ->
    Mojo.Log.info(url + "," + method + "," + Object.toJSON(params))
    
    request = new Ajax.Request(
      url,
      {
        method : method
        parameters: params
        onSuccess: (inTransport) =>
          this.handleResponse(token, inTransport, true)
        onFailure: (inTransport) =>
          this.handleResponse(token, inTransport, true)
        onException: (inTransport, inException) =>
          this.handleResponse(token, inTransport, true)
      }
    )

    Request.store.push(request)

  get: (url, params, success, failure) ->
    this.request(url, 'get', params, success, failure)

  post: (url, params, success, failure) ->
    unless params.uh?
      new Banner("Not logged in.").send()
      return
    
    this.request(url, 'post', params, success, failure)

  handleResponse: (token, response, success) ->
    if @callback? 
      @callback.handleCallback({type: token, response: response, success: success})
    else
      Mojo.Controller.getAppController().sendToNotificationChain({type: token, response: response, success: success})

  @store = []

  @clear_all: ->
    _.each @store, (request) ->
      Mojo.Log.info("aborting request")
      request.transport.abort()

    @store.length = 0
