class UserAssistant

  constructor: (url) ->
    @user = url.linky
    @url = 'http://reddit.com/user/' + @user + '.json'
    @listModel:
      items:
        []

  setup: ->
    StageAssistant.setTheme(this);
    
    @viewMenuModel
      visible: true
      items: 
        [
          items:
            [{},
            { label: "overview for " + @user, command: 'top', icon: "", width: Mojo.Environment.DeviceInfo.screenWidth},
            {}
            ]
      ]

    @controller.setupWidget(Mojo.Menu.viewMenu, { menuClass:'no-fade' }, @viewMenuModel)

    @controller.setupWidget("list", {
      itemTemplate : "user/list-item",
      formatters:
        title: this.titleFormatter
        content: this.contentFormatter
        description: this.descriptionFormatter
      }, @listModel)

    @itemTappedBind = this.itemTapped.bind(this)
    Mojo.Event.listen(@controller.get("list"), Mojo.Event.listTap, @itemTappedBind)

  activate: (event) ->
    StageAssistant.defaultWindowOrientation(this, "free")
    @listModel.items.clear()
    @controller.modelChanged(@listModel)

    this.about()
    this.fetchComments()

  deactivate: (event) ->

  cleanup: (event) ->
    Mojo.Event.stopListening(@controller.get("list"), Mojo.Event.listTap, @itemTappedBind)

  titleFormatter: (propertyValue, model) =>
    return model.data.link_title if model.kind is 't1'
    return model.data.title if model.kind is 't3'
    ""

  contentFormatter: (propertyValue, model) =>
    return model.data.body if model.kind is 't1'
    return model.data.selftext if model.kind is 't3'
    ""

  descriptionFormatter: (propertyValue, model) =>
    if model.kind is 't1'
      return StageAssistant.scoreFormatter(model) + " " + StageAssistant.timeFormatter(model.data.created_utc)
    else if model.kind is 't3'
      return "submitted " + StageAssistant.timeFormatter(model.data.created_utc) + " to " + model.data.subreddit

    ""

  handleCommand: (event) ->
    return if event.type isnt Mojo.Event.command
    
    switch event.command
      when 'top'
        this.scrollToTop()
  
  scrollToTop: ->
    @controller.getSceneScroller().mojo.scrollTo(0,0, true)

  handleCallback: (params) ->
    return params unless params? and params.success

    if params.type is "user-comments"
      this.handleUserCommentsResponse(params.response)
    else if params.type is "user-about"
      this.handleUserAboutResponse(params.response)

  fetchComments: ->
    params = {user: @user}

    new User(this).comments(params)

  about: ->
    params = {user: @user}

    new User(this).about(params)

  handleUserCommentsResponse: (response) ->
    children = response.responseJSON.data.children
    
    _.each children, (child) =>
      @listModel.items.push child

    @controller.modelChanged(@listModel)

  handleUserAboutResponse: (response) ->
    userinfo = response.responseJSON

    @controller.get('created_field').update(StageAssistant.timeFormatter(userinfo.data.created_utc))
    @controller.get('comment_karma_field').update(userinfo.data.comment_karma)
    @controller.get('link_karma_field').update(userinfo.data.link_karma)

  itemTapped: (event) ->
    article = event.item;
    thread_id = null
    thread_title = null

    if article.kind is 't3' # post
      thread_id = article.data.name
      thread_title = article.data.title
    else if article.kind is 't1' # comment
      thread_id = article.data.link_id
      thread_title = article.data.link_title

    hash
      url: '/comments/' + thread_id.substr(3)
      title: thread_title

    @controller.stageController.pushScene({name:"article",transition: Mojo.Transition.crossFade}, hash)
