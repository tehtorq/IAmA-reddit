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
    @can_navigate_back and AppAssistant.deviceIsTouchPad() #not Mojo.Environment.DeviceInfo.keyboardAvailable
    
  getViewMenuWidth: ->
    @viewmenu_width
    
  scrollToTop: ->
    @controller.getSceneScroller().mojo.scrollTo(0,0, true)
    
  spinSpinner: (bool) ->
    if bool
      @controller.get('spinner').mojo.start()
      @controller.get('loading').style.left = '0px'
    else
      @controller.get('loading').style.left = '-200px'
      #@controller.get('spinner').mojo.stop()
      
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
    
  getModHash: ->
    RedditAPI.getUser()?.modhash
    
  isLoggedIn: ->
    @getModHash()? and @getModHash() isnt ""
    
  updateHeading: (text) ->
    text = '' unless text?

    @controller.get('reddit-heading').style.left = '-500px'

    @controller.window.setTimeout(
      =>
        @controller.get('reddit-heading').update(text)
        @controller.get('reddit-heading').style.left = '0px'
      500
    )
    
  handleScrollUpdate: =>
    if @controller.get('puller').visible()
      offset = @controller.get('puller').viewportOffset()[1] - @controller.getSceneScroller().mojo.scrollerSize()['height']

      if offset < 0
        if @is_loading_content is false
          @loadMore()
    
  log: (thing, stringify = false) ->
    if stringify
      Mojo.Log.info(JSON.stringify(thing))
    else
      Mojo.Log.info(thing)
