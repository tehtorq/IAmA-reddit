class MessageAssistant
  
  constructor: (action) ->
    @listModel:
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
    
    @viewMenuModel = {
      visible: true,
      items: [
          {items:[{},
                  { label: 'inbox', command: 'top', icon: "", width: Mojo.Environment.DeviceInfo.screenWidth - 60},
                  {icon:'search', submenu: "sub-menu", width: 60},
                  {}]}
      ]
    }
    
    @controller.setupWidget(Mojo.Menu.viewMenu, { menuClass:'no-fade' }, @viewMenuModel)
    
    @controller.setupWidget("contentarea", {
      itemTemplate: "message/list-item",
      emptyTemplate: "message/emptylist",
      formatters: 
        time: @timeFormatter
        description: @descriptionFormatter
      }, @listModel)

    @controller.listen("contentarea", Mojo.Event.listTap, @itemTapped.bind(@))

  activate: (event) ->
    StageAssistant.defaultWindowOrientation(@, "free")
    @loadMessages('inbox')

  deactivate: (event) ->
  cleanup: (event) ->
  
  timeFormatter: (propertyValue, model) =>
    return "" if (model.kind isnt 't1') and (model.kind isnt 't3') and (model.kind isnt 't4')
    StageAssistant.timeFormatter(model.data.created_utc)
  
  descriptionFormatter: (propertyValue, model) =>
    return "" if (model.kind isnt 't1') and (model.kind isnt 't3') and (model.kind isnt 't4')
    
    desc = ""
    
    if model.kind is 't1'
      desc = "from <b>" + model.data.author + "</b> via " + model.data.subreddit + " sent " + StageAssistant.timeFormatter(model.data.created_utc)
    else
      desc = "from <b>" + model.data.author + "</b> sent " + StageAssistant.timeFormatter(model.data.created_utc)
    
    desc
  
  handleCallback: (params) ->
    return params unless params? and params.success

    if (params.type is "message-inbox") or
        (params.type is "message-unread") or
        (params.type is "message-messages") or
        (params.type is "message-comments") or
        (params.type is "message-selfreply") or
        (params.type is "message-sent")
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
    @spinSpinner(false)
    
    return if response.readyState isnt 4
    
    children = response.responseJSON.data.children
    
    _.each children, (child) =>
      child.data.body_html = child.data.body_html.unescapeHTML()
      @listModel.items.push(child)

    @controller.modelChanged(@listModel)

  itemTapped: (event) ->
    item = event.item
    #@controller.stageController.pushScene({name:"user"},{linky:item.item["author"]})
  
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
  
  spinSpinner: (bool) ->
    if bool
      @controller.get('loading').show()
    else
      @controller.get('loading').hide()
