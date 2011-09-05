class GifAssistant

  constructor: (params) ->
    @image_array = params.images
    @current_index = params.index

  setup: ->
    StageAssistant.setTheme(@)
    
    @cmdMenuModel = {
      visible: false,
      items: [
          {items:[{},
                  { label: (@current_index + 1) + "/" + @image_array.length, command: 'top', icon: "", width: Mojo.Environment.DeviceInfo.screenWidth - 180},
                  {label: $L('Save'), icon:'save', command:'save'},                  
                  {}]}
      ]
    }

    @controller.setupWidget(Mojo.Menu.commandMenu, { menuClass:'palm-dark' }, @cmdMenuModel)
    @handleTapBind = @handleTap.bind(@)
    
    Mojo.Event.listen(@controller.get('wrappertest'), Mojo.Event.tap, @handleTapBind)

  activate: (event) ->
    StageAssistant.defaultWindowOrientation(@, "up")
    
    mydiv = @controller.document.createElement('img')
    mydiv.setAttribute('src', @image_array[0])
    mydiv.setAttribute('alt', @image_array[0])
    mydiv.setAttribute('style', 'max-width: 320px')
    #mydiv.setAttribute('align', 'middle')

    @controller.get('centered').appendChild(mydiv)

  ready: ->

  deactivate: (event) ->

  cleanup: (event) ->
    Mojo.Event.stopListening(@controller.get('wrappertest'), Mojo.Event.tap, @handleTapBind)

  handleCommand: (event) ->
    return if event.type isnt Mojo.Event.command
    
    if event.command is 'save'
      @download(@urlForIndex(@current_index))

  handleTap: ->
    @cmdMenuModel.visible = !@cmdMenuModel.visible
    @controller.modelChanged(@cmdMenuModel)

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
