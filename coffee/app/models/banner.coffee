class Banner

  @send: (message) ->
    Mojo.Controller.getAppController().showBanner(message, {source: 'notification'})

