class DashboardAssistant
  
  constructor: (params) ->
    @params = params
    @message = "Notification"
    @count = 1

  setup: ->
    @updateDashboard(@params)
  
  cleanup: ->

  launchMain: ->
    appController = Mojo.Controller.getAppController()
    appController.assistant.handleLaunch({source:"notification"})
    @controller.window.close()

  updateDashboard: (params) ->
    Mojo.Log.info 'params'
    Mojo.Log.info JSON.stringify(params)
    
    message = ""
    message += "New messages! " if params.new_messages
    message += "+#{params.comment_karma_delta} comment karma " if params.comment_karma_delta > 0
    message += "#{params.comment_karma_delta} comment karma " if params.comment_karma_delta < 0
    message += "+#{params.link_karma_delta} link karma " if params.link_karma_delta > 0
    message += "#{params.link_karma_delta} link karma " if params.link_karma_delta < 0
    
    info =
      message: params.message || message
      count: params.count || 1
      title: 'Notification'
      
    Mojo.Log.info 'info'
    Mojo.Log.info JSON.stringify(info)

    renderedInfo = Mojo.View.render({object: info, template: 'dashboard/item-info'})
    @controller.get('dashboardinfo').innerHTML = renderedInfo

  # launchMain: ->
  #   appController = Mojo.Controller.getAppController()
  #   appController.assistant.handleLaunch({source:"notification"})
  #   @controller.window.close()
