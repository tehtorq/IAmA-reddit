class AboutAssistant extends BaseAssistant
  
  constructor: (params) ->
    super
    @params = params
  
  setup: ->
    super
    
    if @params?.skip is true
      @viewMenuModel = {
        visible: true,
        items: [
            {items:[{},
                    { label: $L('Continue'), command: 'continue', icon: "", width: @getViewMenuWidth()},
                    {}]}
        ]
      }
      
      @controller.setupWidget(Mojo.Menu.viewMenu, { menuClass:'no-fade' }, @viewMenuModel)
    else
      if not @showBackNavigation()
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
      when 'continue'
        @controller.stageController.swapScene({name:"frontpage",transition: Mojo.Transition.crossFade})
