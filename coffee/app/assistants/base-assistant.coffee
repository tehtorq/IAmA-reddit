class BaseAssistant
  
  constructor: ->
    @cardname = "card" + Math.floor(Math.random()*10000)
    
  setup: ->
    @can_navigate_back = @canNavigateBack()
    @viewmenu_width = _.min([@controller.window.innerWidth, @controller.window.innerHeight])
    
    StageAssistant.setTheme(@)
    
  activate: ->
    
  deactivate: ->
    @removeListeners()
    
  cleanup: ->
    Request.clear_all(@cardname)
  
  canNavigateBack: -> # only increments after setup finishes
    Mojo.Log.info("number of scenes: #{@controller.stageController.getScenes().length}")
    @controller.stageController.getScenes().length > 0
    
  showBackNavigation: ->
    @can_navigate_back #and not Mojo.Environment.DeviceInfo.keyboardAvailable
    
  getViewMenuWidth: ->
    @viewmenu_width
    
  scrollToTop: ->
    @controller.getSceneScroller().mojo.scrollTo(0,0, true)
    
  spinSpinner: (bool) ->
    if bool
      @controller.get('spinner').mojo.start()
      @controller.get('loading').show()
    else
      @controller.get('loading').hide()
      @controller.get('spinner').mojo.stop()
      
  addListeners: ->
    @listeners = arguments
    
    _.each @listeners, (listener) => Mojo.Event.listen(listener...)
    
  removeListeners: ->
    _.each @listeners, (listener) => Mojo.Event.stopListening(listener...)
