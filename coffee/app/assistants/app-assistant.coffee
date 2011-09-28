class AppAssistant

  considerForNotification: (params) ->
    return unless params?

    if params.success
      new Banner("Action completed.").send()
    else
      new Banner("Action not completed.").send()
  
  handleLaunch: (params) ->
    if params.dockMode or params.touchstoneMode
      @launchDockMode()
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
    samecard = StageAssistant.cookieValue("prefs-samecard", "off")
  
    if (samecard is "on") and (StageAssistant.stages.length > 0)
      assistant.controller.stageController.pushScene(sceneArguments, sceneParameters)
      return
  
    # only allow one card for prefs
  
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
        stageController.pushScene("frontpage")
  
    StageAssistant.stages.push(cardname)

    appController = Mojo.Controller.getAppController()
    appController.createStageWithCallback({name: cardname, lightweight: true}, pushCard, "card")
