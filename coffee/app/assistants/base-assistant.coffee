class BaseAssistant
  
  constructor: ->
    @cardname = "card" + Math.floor(Math.random()*10000)
    
  setup: ->
    @can_navigate_back = @canNavigateBack()
    @viewmenu_width = _.min([@controller.window.innerWidth, @controller.window.innerHeight])
    
    StageAssistant.setTheme(@)
    
  cleanup: ->
    Request.clear_all(@cardname)
  
  canNavigateBack: -> # only increments after setup finishes
    Mojo.Log.info("number of scenes: #{@controller.stageController.getScenes().length}")
    @controller.stageController.getScenes().length > 0
    
  showBackNavigation: ->
    @can_navigate_back #and not Mojo.Environment.DeviceInfo.keyboardAvailable
    
  getViewMenuWidth: ->
    @viewmenu_width