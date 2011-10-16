class AboutAssistant
  
  constructor: (params) ->
    @allow_back = params.allow_back
  
  setup: ->
    viewmenu_width = _.min([@controller.window.innerWidth, @controller.window.innerHeight])
    
    if Mojo.Environment.DeviceInfo.keyboardAvailable or not @allow_back
      @viewMenuModel = {
        visible: true,
        items: [
            {items:[{},
                    { label: $L('About'), command: 'top', icon: "", width: viewmenu_width},
                    {}]}
        ]
      }
    else
      @viewMenuModel = {
        visible: true,
        items: [
            {items:[{},
                    {label: $L('Back'), icon:'', command:'back', width:80}
                    { label: $L('About'), command: 'top', icon: "", width: viewmenu_width - 80},
                    {}]}
        ]
      }

    @controller.setupWidget(Mojo.Menu.viewMenu, { menuClass:'no-fade' }, @viewMenuModel)
  
  activate: (event) ->
  deactivate: (event) ->
  cleanup: (event) ->
    
  handleCommand: (event) ->
    return if event.type isnt Mojo.Event.command

    switch event.command
      when 'top'
        @scrollToTop()
      when 'back'
        @controller.stageController.popScene()
