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
          @handleResponse(token, inTransport, true)
        onFailure: (inTransport) =>
          @handleResponse(token, inTransport, false)
        onException: (inTransport, inException) =>
          @handleResponse(token, inTransport, false)
      }
    )

    Request.store.push(request)

  get: (url, params, success, failure) ->
    @request(url, 'get', params, success, failure)

  post: (url, params, success, failure) ->
    unless params.uh?
      new Banner("Not logged in.").send()
      return
    
    @request(url, 'post', params, success, failure)

  handleResponse: (token, response, success) ->
    #return unless response.readyState is 4
    
    Mojo.Log.info("handleResponse: {token: #{token}, success:#{success}}")
    
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
