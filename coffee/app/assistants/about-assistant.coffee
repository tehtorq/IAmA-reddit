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
      
      @controller.setupWidget(Mojo.Menu.appMenu, {}, {visible: true, items: [{label: "Feedback", command: 'feedback-cmd'}]})
  
  ready: ->
    expiration = new Date(new Date().getTime() + 24 * 60 * 60000)
    new Mojo.Model.Cookie("show-about-screen").put(expiration, expiration)
    
  handleCommand: (event) ->
    return if event.type isnt Mojo.Event.command

    switch event.command
      when 'top'
        @scrollToTop()
      when 'back'
        @controller.stageController.popScene()
      when 'continue'
        @controller.stageController.swapScene({name:"frontpage",transition: Mojo.Transition.crossFade})
      when 'feedback-cmd'
        @mail()
        
  mail: ->
    @controller.serviceRequest(
      "palm://com.palm.applicationManager",
      {
        method: 'open'
        parameters:
          id: "com.palm.app.email",
          params:
            summary: 'IAmA reddit feedback',
            text: '',
            recipients: [{
              type:"email",
              role:1,
              value:"i.am.douglas.anderson@gmail.com",
              contactDisplay:"IAmA reddit"
            }]
      }
    )
