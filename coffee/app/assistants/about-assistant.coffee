class AboutAssistant
  
  constructor: (params) ->
    @allow_back = params.allow_back
  
  setup: ->
    if Mojo.Environment.DeviceInfo.keyboardAvailable or not @allow_back
      @viewMenuModel = {
        visible: true,
        items: [
            {items:[{},
                    { label: $L('About'), command: 'top', icon: "", width: @controller.window.innerWidth},
                    {}]}
        ]
      }
    else
      @viewMenuModel = {
        visible: true,
        items: [
            {items:[{},
                    {label: $L('Back'), icon:'', command:'back', width:80}
                    { label: $L('About'), command: 'top', icon: "", width: @controller.window.innerWidth - 80},
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
