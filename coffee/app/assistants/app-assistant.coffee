
class IamaReddit

class AppAssistant
  
  setup: ->
    IamaReddit.Metrix = new Metrix() # instantiate metrix library
    IamaReddit.Metrix.postDeviceData()

  considerForNotification: (params) ->
    return unless params?

    if params.success
      if params.type is 'user-me'
        @handleCheckedMessages(params.response)
      else
        Banner.send("Action completed.")
    else
      Banner.send("Action not completed.")
      
  handleCheckedMessages: (response) ->
    return unless response? and response.responseJSON? and response.responseJSON.data?
    data = response.responseJSON.data
    
    #data.link_karma = Math.floor(Math.random()*11)
    #data.comment_karma = Math.floor(Math.random()*11)
    
    Mojo.Log.info('response data')
    Mojo.Log.info(JSON.stringify(data))
    
    comment_karma_delta = 0
    link_karma_delta = 0
    new_messages = data.has_mail
    
    cached_data = JSON.parse(StageAssistant.cookieValue("reddit-tracking", JSON.stringify(data)))
    Mojo.Log.info("cached data:")
    Mojo.Log.info(cached_data)
    
    if data.name is cached_data['name']
      comment_karma_delta = data.comment_karma - cached_data['comment_karma']
      link_karma_delta = data.link_karma - cached_data['link_karma']
    
    new Mojo.Model.Cookie("reddit-tracking").put(JSON.stringify(data))
    
    if new_messages or (comment_karma_delta isnt 0) or (link_karma_delta isnt 0)
      Mojo.Log.info "You have messages!"
      @createDashboard({new_messages: new_messages, comment_karma_delta: comment_karma_delta, link_karma_delta: link_karma_delta})
    else
      Mojo.Log.info "No new messages :("
  
  createDashboard: (params) ->
    appController = Mojo.Controller.getAppController()
    @dashboardcount += 1
    count = @dashboardcount
    dashboardStage = appController.getStageProxy("dashboard")
    
    if dashboardStage
      dashboardStage.delegateToSceneAssistant("updateDashboard", params)
    else
      @dashboardcount = 1
      count = @dashboardcount
      pushDashboard = (stageController) -> stageController.pushScene('dashboard', params)
      appController.createStageWithCallback({name: "dashboard", lightweight: true}, pushDashboard, 'dashboard')
    
  checkMessages: ->
    Preferences.updateNotifications()
    new User().me()
  
  handleLaunch: (params) ->    
    Mojo.Log.info("app #{Mojo.appInfo.id} launched with:")
    Mojo.Log.info JSON.stringify(params)
    		
    if params.action is "checkMessages"
      @checkMessages()
    else if params.dockMode or params.touchstoneMode
      @launchDockMode()
    else if params.searchString
      AppAssistant.cloneCard(null, {name:"frontpage"}, {search: params.searchString})
    else
      AppAssistant.cloneCard(null, {name:"frontpage"})
  
  launchDockMode: ->
    dockStage = @controller.getStageController('dock')
    
    if dockStage
      dockStage.window.focus()
    else
      f = (stageController) =>
        stageController.pushScene('dock', {dockmode:true})
        
      @controller.createStageWithCallback({name: 'dock', lightweight: true}, f, "dockMode")

  @cloneCard = (assistant, sceneArguments, sceneParameters) ->
    sceneParameters or= {}
    samecard = StageAssistant.cookieValue("prefs-samecard", "off")
  
    if assistant? and (samecard is "on") and (StageAssistant.stages.length > 0)
      assistant.controller.stageController.pushScene(sceneArguments, sceneParameters)
      return
  
    # only allow one card for prefs and about scenes
  
    if sceneArguments? and (sceneArguments.name in ['prefs','about'])
      stageController = Mojo.Controller.getAppController().getStageController(sceneArguments.name)
    
      if stageController?
        stageController.activate()
        return
        
    cardname = "card" + Math.floor(Math.random()*10000)
    cardname = sceneArguments.name if sceneArguments? and (sceneArguments.name in ['prefs','about'])

    pushCard = (stageController) =>
      if sceneArguments?
        stageController.pushScene(sceneArguments, sceneParameters)
      else
        stageController.pushScene("frontpage",{})
  
    StageAssistant.stages.push(cardname)
    Mojo.Controller.getAppController().createStageWithCallback({name: cardname, lightweight: true}, pushCard, "card")
