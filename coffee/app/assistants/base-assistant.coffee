class BaseAssistant
  
  constructor: ->
    @cardname = "card" + Math.floor(Math.random()*10000)
    
  setup: ->
    @can_navigate_back = @canNavigateBack()
    @viewmenu_width = _.min([@controller.window.innerWidth, @controller.window.innerHeight])
    @loadTheme()
    
  activate: ->
    StageAssistant.defaultWindowOrientation(@, "free")
    
  deactivate: ->
    @removeListeners()
    
  cleanup: ->
    Request.clear_all(@cardname)
  
  canNavigateBack: ->
    @controller.stageController.getScenes().length > 0 # only increments after setup finishes
    
  showBackNavigation: ->
    @can_navigate_back and not Mojo.Environment.DeviceInfo.keyboardAvailable
    
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
    
  loadTheme: ->
    Mojo.loadStylesheet(@controller.document, Preferences.getThemePath())
    
  toggleSearch: ->
    @scrollToTop() if @controller.getSceneScroller()? # prevent grey area in list
    ff = @controller.get("filterfield")

    if (ff._mojoController.assistant.filterOpen)
       ff.mojo.close()
    else
       ff.mojo.open()

  setClipboard: (text) ->
    Banner.send("Sent to Clipboard")
    @controller.stageController.setClipboard(text, true)  
