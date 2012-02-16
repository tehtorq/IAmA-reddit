class UsersAssistant extends BaseAssistant
  
  constructor: (params) ->
    super
    
    @listModel =
      items: []

  setup: ->
    super
    
    @controller.setupWidget "spinner", @attributes = {}, @model = {spinning: true}
    
    @controller.setupWidget("users-list", {
      itemTemplate: "users/list-item",
      emptyTemplate: "list/empty_template",
      nullItemTemplate: "users/null_item_template"
      }, @listModel)

  activate: (event) ->
    super
    
    @addListeners(
      [@controller.get("users-list"), Mojo.Event.listTap, @itemTapped]
    )
    
    @loadUsers()

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
  
  loadUsers: ->
    @spinSpinner(false)
    @listModel.items.clear()
    @users = RedditAPI.getUsers()
    
    _.each @users, (user) =>
      @listModel.items.push(user)
    
    @controller.modelChanged(@listModel)
    
    @controller.get('users-list').mojo.noticeAddedItems(0, [null]) if @listModel.items.length is 0

  itemTapped: (event) =>
    index = event.index
    
    @controller.popupSubmenu({
      onChoose: @handleTapSelection,
      items: [
        {label: $L('Log in'), command: 'login-cmd ' + index}
        {label: $L('Forget'), command: 'forget-cmd ' + index}
        {label: $L('Log out'), command: 'logout-cmd ' + index}
      ]
    })
    
  login: (index) ->
    user = @users[index]
    
    RedditAPI.setUser(user.username, user.modhash, user.reddit_session)
    Banner.send("Logged in as #{user.username}")
    
    Mojo.Log.info("modhash: #{@getModHash()}")
    Mojo.Log.info("reddit_session: #{StageAssistant.cookieValue("reddit_session", '')}")
    Mojo.Log.info("user: #{JSON.stringify(RedditAPI.getUser())}")
    @controller.stageController.popScene()
    
  logout: (index) ->
    params = {uh: @getModHash()}
    new User(@).logout(params)
     
  handleTapSelection: (command) =>
    return unless command?

    params = command.split(' ')

    switch params[0]
      when 'login-cmd'
        @login(params[1])
      when 'forget-cmd'
        @login(params[1])
      when 'logout-cmd'
        @logout(params[1])
  
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
        
  handleCallback: (params) ->    
    return params unless params? and params.success
    
    if params.type is 'user-logout'
      Mojo.Log.info(JSON.stringify(params))
      Banner.send("Logged out")
