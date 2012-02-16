class UserAssistant extends BaseAssistant

  constructor: (params) ->
    super
    
    @user = params.user
    @url = 'http://reddit.com/user/' + @user + '.json'
    @listModel =
      items:
        []

  setup: ->
    super
    
    if @showBackNavigation()
      @viewMenuModel =
        visible: true
        items: 
          [
            items:
              [{label: $L('Back'), icon:'', command:'back', width:80}]
        ]

      @controller.setupWidget(Mojo.Menu.commandMenu, { menuClass:'no-fade' }, @viewMenuModel)
    
    @updateHeading("overview for " + @user)

    @controller.setupWidget("list", {
      itemTemplate : "user/list-item",
      formatters:
        title: @titleFormatter
        content: @contentFormatter
        description: @descriptionFormatter
      }, @listModel)
    
    @controller.setupWidget("messageButton", {}, {label : "Send Message"})

  activate: (event) ->
    super
    
    @addListeners(
      [@controller.get("list"), Mojo.Event.listTap, @itemTapped]
      [@controller.get("messageButton"), Mojo.Event.tap, @sendMessageTapped]
    )

    if @listModel.items.length is 0
      @about()
      @fetchComments()

  updateHeading: (text) ->
    text = '' unless text?
    @controller.get('reddit-heading').update(text)
    
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
        @scrollToTop()
      when 'back'
        @controller.stageController.popScene()

  handleCallback: (params) ->
    return params unless params? and params.success

    if params.type is "user-comments"
      @handleUserCommentsResponse(params.response)
    else if params.type is "user-about"
      @handleUserAboutResponse(params.response)

  fetchComments: ->
    params = {user: @user}

    new User(@).comments(params)

  about: ->
    params = {user: @user}

    new User(@).about(params)

  handleUserCommentsResponse: (response) ->
    return unless response? and response.responseJSON? and response.responseJSON.data? and response.responseJSON.data.children?
    children = response.responseJSON.data.children
    
    _.each children, (child) =>
      @listModel.items.push child

    @controller.modelChanged(@listModel)

  handleUserAboutResponse: (response) ->
    userinfo = response.responseJSON

    @controller.get('created_field').update(StageAssistant.timeFormatter(userinfo.data.created_utc))
    @controller.get('comment_karma_field').update(userinfo.data.comment_karma)
    @controller.get('link_karma_field').update(userinfo.data.link_karma)
    
  sendMessageTapped: (event) =>
    @controller.stageController.pushScene({name:"compose-message"}, {to: @user})

  itemTapped: (event) =>
    article = event.item;
    thread_id = null
    thread_title = null

    if article.kind is 't3' # post
      thread_id = article.data.name
      thread_title = article.data.title
    else if article.kind is 't1' # comment
      thread_id = article.data.link_id
      thread_title = article.data.link_title

    hash =
      url: 'http://reddit.com/comments/' + thread_id.substr(3)
      title: thread_title

    @controller.stageController.pushScene({name:"article",transition: Mojo.Transition.crossFade}, hash)
