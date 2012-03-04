class MessageAssistant extends BaseAssistant
  
  constructor: (params) ->
    super
    
    @listModel =
      items: []

  setup: ->
    super
    
    @controller.setupWidget "spinner", @attributes = {}, @model = {spinning: true}
    
    @controller.setupWidget 'sub-menu', null, {items: [
      {label:$L("all"), command:$L("message inbox")}
      {label:$L("unread"), command:$L("message unread")}
      {label:$L("messages"), command:$L("message messages")}
      {label:$L("comment replies"), command:$L("message comments")}
      {label:$L("post replies"), command:$L("message selfreply")}
      {label:$L("sent"), command:$L("message sent")}
    ]}
    
    back_button = if @showBackNavigation()
      {label: $L('Back'), icon:'', command:'back', width:80}
    else
      {}
    
    @viewMenuModel =
      visible: true,
      items: [
        back_button
        items: [
          {label: $L('Compose'), icon:'new', command:'compose-message-cmd'}
          {submenu: "sub-menu", width: 60, iconPath: 'images/options.png'}
        ]
      ]
  
    @controller.setupWidget(Mojo.Menu.commandMenu, { menuClass:'no-fade' }, @viewMenuModel)
    
    @controller.setupWidget("message-list", {
      itemTemplate: "message/list-item",
      emptyTemplate: "list/empty_template",
      nullItemTemplate: "list/null_item_template"
      formatters: 
        time: @timeFormatter
        description: @descriptionFormatter
      }, @listModel)

  activate: (event) ->
    super
    
    @addListeners(
      [@controller.get("message-list"), Mojo.Event.listTap, @itemTapped]
    )
    
    @loadMessages('inbox')

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
    
    @controller.get('message-list').mojo.noticeAddedItems(0, [null]) if @listModel.items.length is 0

  itemTapped: (event) =>
    item = event.item
    
    @controller.popupSubmenu({
      onChoose: @handleTapSelection,
      items: [
        {label: $L(item.data.author), command: 'view-user-cmd ' + item.data.author}
        {label: $L('Reply'), command: 'reply-cmd ' + item.data.name + ' ' + item.data.author + ' ' + item.data.subreddit}
      ]
    })
     
  handleTapSelection: (command) =>
    return unless command?

    params = command.split(' ')

    switch params[0]
      when 'view-user-cmd'
        @controller.stageController.pushScene({name:"user"}, {user:params[1]})
      when 'reply-cmd'
        @controller.stageController.pushScene(
          {name: "reply",transition: Mojo.Transition.crossFade}
          {thing_id:params[1], user: params[2], modhash: @getModHash(), subreddit: params[3]}
        )      
  
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
      when 'compose-message-cmd'
        @controller.stageController.pushScene({name:"compose-message"},{})
