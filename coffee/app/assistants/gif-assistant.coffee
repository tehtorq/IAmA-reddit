class GifAssistant

  constructor: (params) ->
    @cardname = "card" + Math.floor(Math.random()*10000)
    @image_array = params.images
    @article_array = params.articles
    @current_index = params.index
    
    @article_array = [] unless @article_array?

  setup: ->
    StageAssistant.setTheme(@)
    
    @controller.setupWidget("spinner",
      @attributes = {}
      @model = {spinning: true}
    )
    
    command_menu_items = null
    
    if @article_array.length > 0
      command_menu_items = [
        {}
        {label: $L('Back'), icon:'back', command:'back'}
        {label: $L('Article'), icon:'info', command:'article'}
        {label: (@current_index + 1) + "/" + @image_array.length, command: 'top', icon: "", width: @controller.window.innerWidth - 240}
        {label: $L('Save'), icon:'save', command:'save'}
        {label: $L('Forward'), icon:'forward', command:'forward'}
        {}
      ]
    else
      command_menu_items = [
        {}
        {label: $L('Back'), icon:'back', command:'back'}
        {label: (@current_index + 1) + "/" + @image_array.length, command: 'top', icon: "", width: @controller.window.innerWidth - 180}
        {label: $L('Save'), icon:'save', command:'save'}
        {label: $L('Forward'), icon:'forward', command:'forward'}
        {}
      ]
    
    @cmdMenuModel = {
      visible: false,
      items: [{items: command_menu_items}]
    }

    @controller.setupWidget(Mojo.Menu.commandMenu, { menuClass:'palm-dark' }, @cmdMenuModel)
    
    @mydiv = @controller.document.createElement('img')
    @mydiv.setAttribute('id', 'ImageId')
    #@mydiv.setAttribute('alt', @image_array[0]) # set this to fallback image
    
    @controller.get('centered').appendChild(@mydiv)
    
    Mojo.Event.listen(@controller.get('wrappertest'), Mojo.Event.tap, @handleTap)
    Mojo.Event.listen(@controller.get('ImageId'), 'load', @handleImageLoaded)
    
  handleImageLoaded: =>
    @spinSpinner false
    @controller.get('image_title').show() if @cmdMenuModel.visible
    @mydiv.show()

  activate: (event) ->
    StageAssistant.defaultWindowOrientation(@, "up")
    
    @setImageSrc @urlForIndex(@current_index)
    @mydiv.setAttribute('style', "max-width: #{@controller.window.innerWidth}px")
    #mydiv.setAttribute('align', 'middle')

  ready: ->
    @controller.get('wrappertest').style.width = "#{@controller.window.innerWidth}px"
    @controller.get('wrappertest').style.height = "#{@controller.window.innerHeight}px"

  deactivate: (event) ->

  cleanup: (event) ->
    Request.clear_all(@cardname)
    Mojo.Event.stopListening(@controller.get('wrappertest'), Mojo.Event.tap, @handleTap)
    Mojo.Event.stopListening(@controller.get('ImageId'), 'load', @handleImageLoaded)

  handleCommand: (event) ->
    return if event.type isnt Mojo.Event.command
    
    switch event.command
      when 'save'
        @download(@urlForIndex(@current_index))
      when 'article'
        AppAssistant.cloneCard(@, {name:"article"}, {article: {kind: 't3', data: @article_array[@current_index].data}})
      when 'back'
        @spinSpinner(true)
        @updateUrls(-1)
      when 'forward'
        @spinSpinner(true)
        @updateUrls(1)
      
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

    if @article_array.length > 0
      @cmdMenuModel.items[0].items[3].label = (@current_index + 1) + "/" + @image_array.length
      @cmdMenuModel.items[0].items[1].disabled = (@current_index == 0)
      @cmdMenuModel.items[0].items[5].disabled = (@current_index == (@image_array.length - 1))
    else
      @cmdMenuModel.items[0].items[2].label = (@current_index + 1) + "/" + @image_array.length
      @cmdMenuModel.items[0].items[1].disabled = (@current_index == 0)
      @cmdMenuModel.items[0].items[4].disabled = (@current_index == (@image_array.length - 1))

    @controller.modelChanged(@cmdMenuModel)

    if (@current_index > -1) and (@current_index < @image_array.length)
      @setImageSrc @urlForIndex(@current_index)
    
  setImageSrc: (src) ->
    @mydiv.hide()
    @controller.get('image_title').hide() unless @cmdMenuModel.visible
    @controller.get('image_title').update(@article_array[@current_index].data.title) if @article_array.length > 0
    @spinSpinner(true)
    @mydiv.setAttribute('src', src)

  handleTap: =>
    @cmdMenuModel.visible = !@cmdMenuModel.visible
    @controller.modelChanged(@cmdMenuModel)
    @controller.get('image_title').show() if @cmdMenuModel.visible
    @controller.get('image_title').hide() unless @cmdMenuModel.visible

  download: (filename) ->
    name = filename.substring(filename.lastIndexOf('/') + 1)

    try
      @controller.serviceRequest 'palm://com.palm.downloadmanager/', {
        method: 'download'
        parameters:
          target: filename,
          targetDir : "/media/internal/reddit_downloads/",
          keepFilenameOnRedirect: false,
          subscribe: true
        onSuccess: (response) ->
          new Banner("Saved image " + name).send() if response.completed
      }
    catch e
      
  spinSpinner: (bool) ->
    if bool
      @controller.get('loading').show()
    else
      @controller.get('loading').hide()
