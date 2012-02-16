
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
    
    comment_karma_delta = 0
    link_karma_delta = 0
    new_messages = data.has_mail
    
    cached_data = JSON.parse(StageAssistant.cookieValue("reddit-tracking", JSON.stringify(data)))
    
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
    
    RedditAPI.checkIfLoggedIn()
    		
    if params.action is "checkMessages"
      @checkMessages()
    else if params.dockMode or params.touchstoneMode
      @launchDockMode()
    else if params.searchString
      AppAssistant.openFrontpage("clone", {search: params.searchString})
    else
      if @shouldDisplayAboutScene()
        AppAssistant.cloneCard(null, {name:"about"}, {skip: true})
      else
        AppAssistant.openFrontpage("clone", {})
  
  shouldDisplayAboutScene: ->
    if Mojo.appInfo.id is 'com.tehtorq.reddit-hb'
      if cookie = new Mojo.Model.Cookie("show-about-screen")
        value = cookie.get()
        return true if value is undefined
    false
    
  launchDockMode: ->
    dockStage = @controller.getStageController('dock')
    
    if dockStage
      dockStage.window.focus()
    else
      f = (stageController) =>
        stageController.pushScene('dock', {dockmode:true})
        
      @controller.createStageWithCallback({name: 'dock', lightweight: true}, f, "dockMode")

  @cloneCard = (controller, sceneArguments, sceneParameters) ->
    sceneParameters or= {}
    samecard = StageAssistant.cookieValue("prefs-samecard", "off")
  
    if controller? and (samecard is "on") and (StageAssistant.stages.length > 0)
      controller.stageController.pushScene(sceneArguments, sceneParameters)
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
    
  @open: (url) ->
    new Mojo.Service.Request("palm://com.palm.applicationManager", {
      method: "open",
      parameters:
        target: url
        onSuccess: ->
        onFailure: ->
      })
      
  @open_donation_link: ->
    @open("https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=BNANW6F5RNWD6")
    
  @open_purchase_link: ->
    @open("http://developer.palm.com/appredirect/?packageid=com.tehtorq.reddit")
  
  @frontpageSceneName: ->
    if @deviceIsTouchPad() then 'split-frontpage' else 'frontpage'

  @deviceIsTouchPad: ->
    return true if Mojo.Environment.DeviceInfo.modelNameAscii.indexOf("ouch") > -1
    return true if Mojo.Environment.DeviceInfo.screenWidth is 1024
    return true if Mojo.Environment.DeviceInfo.screenHeight is 1024
    false
    
  @openFrontpage: (type, params = {}, controller) ->
    if type is "clone"
      if AppAssistant.frontpageSceneName() is "split-frontpage"
        AppAssistant.cloneCard(controller, {name:"split-frontpage",disableSceneScroller: true}, params)
      else
        AppAssistant.cloneCard(controller, {name:"frontpage"}, params)
    else if type is "swap"
      if AppAssistant.frontpageSceneName() is "split-frontpage"
        controller.stageController.swapScene({name: "split-frontpage", disableSceneScroller: true, transition: Mojo.Transition.crossFade}, params)
      else
        controller.stageController.swapScene({name: "frontpage", transition: Mojo.Transition.crossFade}, params)
