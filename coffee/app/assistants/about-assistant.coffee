class AboutAssistant extends BaseAssistant
  
  constructor: (params) ->
    super
  
  setup: ->
    super
    
    if @showBackNavigation()
      @viewMenuModel = {
        visible: true,
        items: [
            {items:[{},
                    { label: $L('About'), command: 'top', icon: "", width: @getViewMenuWidth()},
                    {}]}
        ]
      }
    else
      @viewMenuModel = {
        visible: true,
        items: [
            {items:[{},
                    {label: $L('Back'), icon:'', command:'back', width:80}
                    { label: $L('About'), command: 'top', icon: "", width: @getViewMenuWidth() - 80},
                    {}]}
        ]
      }

    @controller.setupWidget(Mojo.Menu.viewMenu, { menuClass:'no-fade' }, @viewMenuModel)
    
  handleCommand: (event) ->
    return if event.type isnt Mojo.Event.command

    switch event.command
      when 'top'
        @scrollToTop()
      when 'back'
        @controller.stageController.popScene()
