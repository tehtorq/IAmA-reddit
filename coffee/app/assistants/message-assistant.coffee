class MessageAssistant
  
  constructor: (params) ->
    @allow_back = params.allow_back
    @cardname = "card" + Math.floor(Math.random()*10000)
    @listModel =
      items: []

  setup: ->
    StageAssistant.setTheme(@)
    
    @controller.setupWidget(
      "spinner"
      @attributes = {}
      @model = {spinning: true}
    )
    
    @controller.setupWidget 'sub-menu', null, {items: [
      {label:$L("all"), command:$L("message inbox")}
      {label:$L("unread"), command:$L("message unread")}
      {label:$L("messages"), command:$L("message messages")}
      {label:$L("comment replies"), command:$L("message comments")}
      {label:$L("post replies"), command:$L("message selfreply")}
      {label:$L("sent"), command:$L("message sent")}
    ]}
    
    if Mojo.Environment.DeviceInfo.keyboardAvailable or not @allow_back
      @viewMenuModel =
        visible: true,
        items: [
            {items:[{},
                    { label: 'inbox', command: 'top', icon: "", width: @controller.window.innerWidth - 60},
                    {icon:'search', submenu: "sub-menu", width: 60},
                    {}]}
        ]
    else
      @viewMenuModel =
        visible: true,
        items: [
            {items:[{},
                    {label: $L('Back'), icon:'', command:'back', width:80}
                    { label: 'inbox', command: 'top', icon: "", width: @controller.window.innerWidth - 140},
                    {icon:'search', submenu: "sub-menu", width: 60},
                    {}]}
        ]    
    
    @controller.setupWidget(Mojo.Menu.viewMenu, { menuClass:'no-fade' }, @viewMenuModel)
    
    @controller.setupWidget("contentarea", {
      itemTemplate: "message/list-item",
      emptyTemplate: "message/emptylist",
      formatters: 
        time: @timeFormatter
        description: @descriptionFormatter
      }, @listModel)

  activate: (event) ->
    @controller.listen(@controller.get("contentarea"), Mojo.Event.listTap, @itemTapped)
    StageAssistant.defaultWindowOrientation(@, "free")
    @loadMessages('inbox')

  deactivate: (event) ->
    @controller.stopListening(@controller.get("contentarea"), Mojo.Event.listTap, @itemTapped)
    
  cleanup: (event) ->
    Request.clear_all(@cardname)
  
  timeFormatter: (propertyValue, model) =>
    return "" if model.kind not in ['t1','t3','t4']
    StageAssistant.timeFormatter(model.data.created_utc)
  
  descriptionFormatter: (propertyValue, model) =>
    return "" if model.kind not in ['t1','t3','t4']
    
    if model.kind is 't1'
      "from <b>" + model.data.author + "</b> via " + model.data.subreddit + " sent " + StageAssistant.timeFormatter(model.data.created_utc)
    else
      "from <b>" + model.data.author + "</b> sent " + StageAssistant.timeFormatter(model.data.created_utc)
  
  handleCallback: (params) ->
    return params unless params? and params.success
    
    if params.type in ['message-inbox','message-unread','message-messages','message-comments','message-selfreply','message-sent']
      @handleMessagesResponse(params.response)
  
  loadMessages: (type) ->
    @spinSpinner(true)
    @listModel.items.clear()
    @controller.modelChanged(@listModel)
    
    switch type
      when 'inbox'
        new Message(@).inbox({mark: true})
      when 'unread'
        new Message(@).unread({mark: true})
      when 'messages'
        new Message(@).messages({})
      when 'comments'
        new Message(@).comments({})
      when 'selfreply'
        new Message(@).selfreply({})
      when 'sent'
        new Message(@).sent({})

  handleMessagesResponse: (response) ->
    return if response.readyState isnt 4
    @spinSpinner(false)
    
    children = response.responseJSON.data.children
    
    _.each children, (child) =>
      child.data.body_html = child.data.body_html.unescapeHTML()
      @listModel.items.push(child)

    @controller.modelChanged(@listModel)

  itemTapped: (event) =>
    item = event.item
    #@controller.stageController.pushScene({name:"user"},{user:item.item["author"],allow_back:true})
  
  scrollToTop: ->
    @controller.getSceneScroller().mojo.scrollTo(0,0, true)
  
  handleCommand: (event) ->
    return if event.type isnt Mojo.Event.command
    
    params = event.command.split(' ')
    
    switch params[0]
      when 'top'
        @scrollToTop()
      when 'message'
        @loadMessages(params[1])
      when 'back'
        @controller.stageController.popScene()
  
  spinSpinner: (bool) ->
    if bool
      @controller.get('loading').show()
    else
      @controller.get('loading').hide()
