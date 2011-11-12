class ImageAssistant extends BaseAssistant

  constructor: (params) ->
    super
    
    @slideshow = false
    @start_slideshow = params.slideshow || false
    @image_array = params.images
    @article_array = params.articles
    @current_index = params.index
    
    if params.articles?
      @article_array = params.articles
    else 
      @article_array = []

  setup: ->
    super
    
    @controller.setupWidget "spinner", @attributes = {}, @model = {spinning: true}
    
    @controller.setupWidget(
      "ImageId" 
      @attributes = 
        noExtractFS: true
      @model =
        onLeftFunction: =>
          @updateUrls(-1)
        onRightFunction: =>
          @updateUrls(1)
    )
      
    command_menu_items = null
    
    action_items = [
      {label:$L("copy"), command:$L("copy-cmd")},
      {label:$L("email"), command:$L("email-cmd")},
      {label:$L("sms"), command:$L("sms-cmd")},
      {label: $L('save'), icon:'save', command:'save'}
      {label: $L('wallpaper'), command:'wallpaper-cmd'}
    ]
      
    action_items.push({label:$L("slideshow"), command:$L("slideshow-cmd")}) if @image_array.length > 1
    
    @controller.setupWidget('sub-menu', null, {items: action_items})
    
    if not @showBackNavigation()
      if @article_array.length > 0
        command_menu_items = [
          {}
          {label: $L('Prev'), icon:'back', command:'prev'}
          {label: $L('Article'), icon:'info', command:'article'}
          {label: (@current_index + 1) + "/" + @image_array.length, command: 'top', icon: "", width: @getViewMenuWidth() - 240}
          {submenu: "sub-menu", iconPath: 'images/options.png'}
          {label: $L('Forward'), icon:'forward', command:'forward'}
          {}
        ]
      else
        command_menu_items = [
          {}
          {label: $L('Prev'), icon:'back', command:'prev'}
          {label: (@current_index + 1) + "/" + @image_array.length, command: 'top', icon: "", width: @getViewMenuWidth() - 180}
          {submenu: "sub-menu", iconPath: 'images/options.png'}
          {label: $L('Forward'), icon:'forward', command:'forward'}
          {}
        ]
    else
      if @article_array.length > 0
        command_menu_items = [
          {}
          {label: $L('Prev'), icon:'back', command:'prev'}
          {label: $L('Article'), icon:'info', command:'article'}
          {label: $L('Back'), icon:'', command:'back', width:80}
          {label: (@current_index + 1) + "/" + @image_array.length, command: 'top', icon: "", width: @getViewMenuWidth() - 320}
          {submenu: "sub-menu", iconPath: 'images/options.png'}
          {label: $L('Forward'), icon:'forward', command:'forward'}
          {}
        ]
      else
        command_menu_items = [
          {}
          {label: $L('Prev'), icon:'back', command:'prev'}
          {label: $L('Back'), icon:'', command:'back', width:80}
          {label: (@current_index + 1) + "/" + @image_array.length, command: 'top', icon: "", width: @getViewMenuWidth() - 260}
          {submenu: "sub-menu", iconPath: 'images/options.png'}
          {label: $L('Forward'), icon:'forward', command:'forward'}
          {}
        ]

    @cmdMenuModel = {
      visible: false
      items: [{items: command_menu_items}]
    }

    @controller.setupWidget(Mojo.Menu.commandMenu, { menuClass:'palm-dark' }, @cmdMenuModel)

  activate: (event) ->
    super
    
    @addListeners(
      [@controller.get('ImageId'), Mojo.Event.imageViewChanged, @changedImage]
      [@controller.get('wrappertest'), Mojo.Event.tap, @handleTap]
      [@controller.window, 'resize', @handleWindowResize, false]
    )
    
    @controller.get('image_title').hide()
    @updateUrls(0)
  
  cleanup: (event) ->
    super
    @disableSlideShow({silent: true})

  ready: ->
    @controller.get('wrappertest').style.width = "#{@controller.window.innerWidth}px"
    @controller.get('wrappertest').style.height = "#{@controller.window.innerHeight}px"
    @controller.get('ImageId').mojo.manualSize(@controller.window.innerWidth,@controller.window.innerHeight)
    @enableSlideShow() if @start_slideshow is true

  changedImage: =>
    @spinSpinner(false)

  handleWindowResize: (event) =>
    @controller.get('wrappertest').style.width = "#{@controller.window.innerWidth}px"
    @controller.get('wrappertest').style.height = "#{@controller.window.innerHeight}px"
    @controller.get('ImageId').mojo.manualSize(@controller.window.innerWidth, @controller.window.innerHeight)

  toggleSlideshow: ->
    if @slideshow is true
      @disableSlideShow()
    else
      @enableSlideShow()
  
  enableSlideShow: (options = {}) ->
    return unless @slideshow is false
    Banner.send('Enabling slideshow') unless options.silent is true or @slideshow is true
    @slideshow = true
    @timerID = @controller.window.setInterval(@slideshowTick, 10000)
    
  disableSlideShow: (options = {}) ->
    return unless @slideshow is true
    Banner.send('Slideshow disabled') unless options.silent is true or @slideshow is false
    @slideshow = false
    @controller.window.clearInterval(@timerID) if @timerID?
    
  slideshowTick: =>
    delta = 1
    delta = (0 - @current_index) if (@current_index + delta) is @image_array.length
    @updateUrls(delta)
   
  handleCommand: (event) ->
    if event.type is Mojo.Event.command
      switch event.command
        when 'slideshow-cmd'
          @toggleSlideshow()
        when 'copy-cmd'
          @setClipboard(@urlForIndex(@current_index))
        when 'wallpaper-cmd'
          @download(@urlForIndex(@current_index), {wallpaper: true})
        when 'save'
          @download(@urlForIndex(@current_index))
        when 'email-cmd'
          @mail()
        when 'sms-cmd'
          @sms()
        when 'article'
          AppAssistant.cloneCard(@, {name:"article"}, {article: {kind: 't3', data: @article_array[@current_index].data}})
        when 'prev'
          @disableSlideShow()
          @spinSpinner(true)
          @updateUrls(-1)
        when 'forward'
          @disableSlideShow()
          @spinSpinner(true)
          @updateUrls(1)
        when 'back'
          @controller.stageController.popScene()

  urlForIndex: (index) ->
    if index < 0
      return null
      index += @image_array.length
    else if index >= @image_array.length
      return null
      index -= @image_array.length

    @image_array[index]

  updateUrls: (delta) ->
    new_index = @current_index + delta

    return if new_index < 0 or new_index >= @image_array.length

    @current_index = new_index

    if not @showBackNavigation()
      if @article_array.length > 0
        @cmdMenuModel.items[0].items[3].label = (@current_index + 1) + "/" + @image_array.length
        @cmdMenuModel.items[0].items[1].disabled = (@current_index == 0)
        @cmdMenuModel.items[0].items[5].disabled = (@current_index == (@image_array.length - 1))
      else
        @cmdMenuModel.items[0].items[2].label = (@current_index + 1) + "/" + @image_array.length
        @cmdMenuModel.items[0].items[1].disabled = (@current_index == 0)
        @cmdMenuModel.items[0].items[4].disabled = (@current_index == (@image_array.length - 1))
    else
      if @article_array.length > 0
        @cmdMenuModel.items[0].items[4].label = (@current_index + 1) + "/" + @image_array.length
        @cmdMenuModel.items[0].items[1].disabled = (@current_index == 0)
        @cmdMenuModel.items[0].items[6].disabled = (@current_index == (@image_array.length - 1))
      else
        @cmdMenuModel.items[0].items[3].label = (@current_index + 1) + "/" + @image_array.length
        @cmdMenuModel.items[0].items[1].disabled = (@current_index == 0)
        @cmdMenuModel.items[0].items[5].disabled = (@current_index == (@image_array.length - 1))
    
    @controller.modelChanged(@cmdMenuModel)

    image = @controller.get('ImageId')

    if (@current_index > -1) and (@current_index < @image_array.length)
      image.mojo.centerUrlProvided(@urlForIndex(@current_index))

    if (@current_index > 0) and (@current_index < @image_array.length)
      image.mojo.leftUrlProvided(@urlForIndex(@current_index - 1))

    if (@current_index > -1) and (@current_index < (@image_array.length - 1))
      image.mojo.rightUrlProvided(@urlForIndex(@current_index + 1))
    
    @controller.get('image_title').update(@currentTitle())
    
  currentTitle: ->
    if @article_array.length > 0
      @article_array[@current_index].data.title
    else
      ''

  handleTap: =>
    @cmdMenuModel.visible = !@cmdMenuModel.visible
    @controller.modelChanged(@cmdMenuModel)
    @controller.get('image_title').toggle()
    
    if @cmdMenuModel.visible and @currentTitle() isnt ''
      @controller.get('image_title').show()
    else
      @controller.get('image_title').hide()

  download: (filename, options={}) ->
    @spinSpinner(true)
    targetDir = "/media/internal/reddit_downloads/"
    target = filename.substring(filename.lastIndexOf('/') + 1)

    try
      @controller.serviceRequest(
        'palm://com.palm.downloadmanager/'
        method: 'download'
        parameters:
          target: filename
          targetDir : targetDir
          keepFilenameOnRedirect: false
          subscribe: true
        onSuccess: (response) =>
          if response.completed is true 
            if response.completionStatusCode is 200
              return @createWallpaper(response.destFile) if options.wallpaper is true
              @spinSpinner(false)
              Banner.send("Saved image " + response.destFile)
            else
              @spinSpinner(false)
              Banner.send("Action not completed")
        onFailure: =>
          @spinSpinner(false)
          Banner.send("Action not completed")
      )
    catch e
  
  mail: ->
    @controller.serviceRequest(
      "palm://com.palm.applicationManager",
      {
        method: 'open'
        parameters:
          id: "com.palm.app.email",
          params:
            summary: @currentTitle(),
            text: @urlForIndex(@current_index),
            recipients: [{
              type:"email",
              role:1,
              value:"",
              contactDisplay:""
            }]
      }
    )

  sms: ->
    @controller.serviceRequest(
      "palm://com.palm.applicationManager"
      {
        method: 'open'
        parameters:
          id: "com.palm.app.messaging",
          params:
            messageText: @currentTitle() + "\n\n" + @urlForIndex(@current_index)
      }
    )
    
  setWallpaper: (wallpaper) -> 
    @controller.serviceRequest('palm://com.palm.systemservice', {
      method:"setPreferences",
      parameters:{"wallpaper": wallpaper},
      onSuccess: (e) =>
        @spinSpinner(false)
        Mojo.Log.info("setPreferences success, results="+JSON.stringify(e))
        Banner.send("Set as wallpaper")
      onFailure: (e) =>
        @spinSpinner(false)
        Mojo.Log.info("setPreferences failure, results="+JSON.stringify(e))
        Banner.send("Action not completed")
    })
   
  createWallpaper: (target) -> 
    targetDir = "/media/internal/reddit_downloads/"
    
    @controller.serviceRequest('palm://com.palm.systemservice/wallpaper', {
      method:"importWallpaper",
      parameters:{ "target": targetDir + target },
      onSuccess: (e) =>
        Mojo.Log.info("importWallpaper success, results="+JSON.stringify(e))
        @setWallpaper(e.wallpaper)
      onFailure: (e) =>
        @spinSpinner(false)
        Mojo.Log.info("importWallpaper failure, results="+JSON.stringify(e))
        Banner.send("Action not completed")
    })
