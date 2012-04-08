class UsersAssistant extends BaseAssistant
  
  constructor: (params) ->
    super
    
    @listModel =
      items: []
      
    @selected = -1

  setup: ->
    super
    @updateHeading('manage accounts')
    
    back_button = if AppAssistant.deviceIsTouchPad() or true
      {label: $L('Back'), icon:'', command:'back', width:80}
    else
      {}
    
    @viewMenuModel =
      visible: true
      items: [
        back_button
        items: [
          {}
          {label: $L('Register'), command: 'register-cmd'}
          {label: $L('New Login'), command:'login-cmd'}
          {}
        ]
        {}
      ]
      
    @controller.setupWidget(Mojo.Menu.commandMenu, { menuClass:'no-fade' }, @viewMenuModel)
    
    @controller.setupWidget "spinner", @attributes = {}, @model = {spinning: true}
    
    @controller.setupWidget("users-list", {
      itemTemplate: "users/list-item",
      emptyTemplate: "list/empty_template",
      nullItemTemplate: "users/null_item_template"
      swipeToDelete: true
      formatters: 
        selected: @selectedFormatter
      }, @listModel)

  activate: (event) ->
    super
    
    @addListeners(
      [@controller.get("users-list"), Mojo.Event.listTap, @itemTapped]
      [@controller.get("users-list"), Mojo.Event.listDelete, @handleDeleteItem]
    )
    
    @loadUsers()
    
  handleDeleteItem: (event) =>
    user_to_forget = @users[event.index]
    users_to_remember = _.select @users, (user) -> user.username isnt user_to_forget.username
    new Mojo.Model.Cookie("iama-reddit-users").put(JSON.stringify(users_to_remember))
    @listModel.items.splice(event.index, 1)
    Banner.send('Forgotten!')
    
  selectedFormatter: (propertyValue, model) =>
    if model.username is RedditAPI.findCurrentUser()?.username
      return "(logged in)"
      
    ""

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
    user = @users[index]
    
    if user.username is RedditAPI.findCurrentUser()?.username
      @controller.popupSubmenu({
        onChoose: @handleTapSelection,
        items: [
          {label: $L('Log in'), command: 'login-cmd ' + index}
          {label: $L('Log out'), command: 'logout-cmd'}
        ]
      })
    else      
      @controller.popupSubmenu({
        onChoose: @handleTapSelection,
        items: [
          {label: $L('Log in'), command: 'login-cmd ' + index}
        ]
      })
    
  login: (index) ->
    @selected = index
    user = @users[index]
    
    params =
      user: user.username
      passwd: user.password
      api_type: 'json'

    new User(@).login(params)
    
  logout: (index) ->
    @selected = index
    params = {uh: @getModHash()}
    new User(@).logout(params)
     
  handleTapSelection: (command) =>
    return unless command?

    params = command.split(' ')

    switch params[0]
      when 'login-cmd'
        @spinSpinner(true)
        @login(params[1])
      when 'logout-cmd'
        @spinSpinner(true)
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
        @controller.stageController.swapScene({name:AppAssistant.frontpageSceneName()})
      when 'login-cmd'
        @controller.stageController.pushScene({name:"login",transition: Mojo.Transition.crossFade}, {})
      when 'register-cmd'
        @controller.stageController.pushScene({name:"register",transition: Mojo.Transition.crossFade}, {})
    
  handleCallback: (params) ->
    return params unless params? and params.success
    
    if params.type is 'user-logout'
      @spinSpinner(false)
      new Mojo.Model.Cookie("reddit_session").put("")
      Subreddit.cached_list.length = 0
      @controller.get('users-list').mojo.noticeUpdatedItems(0, @listModel.items)
      Banner.send("Logged out")
      @controller.stageController.swapScene({name:AppAssistant.frontpageSceneName()})
    else if params.type is 'user-login'
      @handleLoginResponse(params.response)      
  
  handleLoginResponse: (response) ->
    return if response.readyState isnt 4
    @spinSpinner(false)

    if response.responseJSON?
      json = response.responseJSON.json

      if json.data?
        @loginSuccess(json)
      else
        @loginFailure(json)
    else
      Banner.send("Login failure")

  loginSuccess: (response) ->
    cookie = response.data.cookie
    modhash = response.data.modhash
    
    user = @users[@selected]

    RedditAPI.setUser(user.username, modhash, cookie, user.password)
    Subreddit.cached_list.length = 0

    Banner.send("Logged in as #{user.username}")
    @controller.stageController.swapScene({name:AppAssistant.frontpageSceneName()})

  loginFailure: (response) ->
    Banner.send(response.errors[0][1])
