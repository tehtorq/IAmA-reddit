class Banner

  initialize: (message) ->
    @message = message

  send: ->
    Mojo.Controller.getAppController().showBanner(@message, {source: 'notification'})

