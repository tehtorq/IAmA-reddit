class ArticleAssistant extends PowerScrollBase

  constructor: (params) ->
    super
    
    @params = params
    @url = 'http://reddit.com'

    if params.article?
      @article = params.article.data      
      @url += @article.permalink
      @params.title = @article.title
    else if params.url?
      @url = params.url

  setup: ->
    super
    
    @controller.setupWidget "spinner", @attributes = {}, @model = {spinning: true}
    
    @controller.setupWidget('sub-menu', null, {items: [
      {label:$L("sorted by"), items: [{label:$L("hot"), command:$L("sort hot")},
                                          {label:$L("new"), command:$L("sort new")},
                                          {label:$L("controversial"), command:$L("sort controversial")},
                                          {label:$L("top"), command:$L("sort top")},
                                          {label:$L("old"), command:$L("sort old")},
                                          {label:$L("best"), command:$L("sort confidence")}]},
      {label:$L("show"), items: [{label:$L("top 200 comments"), command:$L("show 200")},
                                {label:$L("top 500 comments"), command:$L("show 500")}]},
      {label:$L("share"), items: [{label:$L("email"), command:$L("email-cmd")},
                                {label:$L("link"), command:$L("share-link-cmd")},
                                {label:$L("sms"), command:$L("sms-cmd")}]},
      {label:$L("related"), command:$L("related")},
      {label:$L("other discussions"), command:$L("duplicates")},
      {label:$L("save"), command:$L("save-cmd")},
      ]})
    
    if not @showBackNavigation()
      @viewMenuModel = {
        visible: true,
        items: [
            {items:[{},
                    { label: @params.title.substr(0, 40), command: 'top', icon: "", width: @getViewMenuWidth() - 60},
                    {submenu: "sub-menu", width: 60, iconPath: 'images/options.png'},
                    {}]}
        ]
      }
    else
      @viewMenuModel = {
        visible: true,
        items: [
            {items:[{},
                    {label: $L('Back'), icon:'', command:'back', width:80}
                    { label: @params.title.substr(0, 40), command: 'top', icon: "", width: @getViewMenuWidth() - 140},
                    {submenu: "sub-menu", width: 60, iconPath: 'images/options.png'},
                    {}]}
        ]
      }
    
    @controller.setupWidget(Mojo.Menu.viewMenu, { menuClass:'no-fade' }, @viewMenuModel)
    
    @comment_list = new CommentList({kind: 't3', data: @article}, @)

    @controller.setupWidget("loadMoreButton", {type:Mojo.Widget.activityButton}, {label : "Loading replies", disabled: true})

  activate: (event) ->
    super
    
    @addListeners(
      [@controller.get("comment-list"), Mojo.Event.listTap, @comment_list.itemTapped]
      [@controller.get("comment-list"), Mojo.Event.hold, @comment_list.itemHold]
    )

    @spinSpinner(false)
    
    if event? and event.replied is true
      item = @comment_list.comments.items[0]
      @comment_list.comments.items.clear()
      @comment_list.comments.items.push(item)
      @jump_to_comment = event.comment_id
    
    if @comment_list.comments.items.length < 2
      @controller.get('loadMoreButton').mojo.activate()
      @fetchComments({})

  loadComments: (params) ->
    item = @comment_list.comments.items[0]
    @comment_list.comments.items.clear()
    @comment_list.comments.items.push(item)

    @controller.modelChanged(@comment_list.comments)
    @controller.get('loadMoreButton').mojo.activate()
    @controller.get('loadMoreButton').show()
    @fetchComments(params)

  handleCommand: (event) ->
    return unless event.type is Mojo.Event.command
    
    switch event.command
      when 'back'
        @controller.stageController.popScene()
      when 'top'
        @scrollToTop()
      when 'save-cmd'
        @saveArticle()
      when 'email-cmd'
        @mailArticle()
      when 'share-link-cmd'
        @setClipboard(@url)
      when 'sms-cmd'
        @smsArticle()
      when 'show 200'
        @loadComments({limit: 200})
      when 'show 500'
        @loadComments({limit: 500})
      when 'related','duplicates'
        url = @url.replace(/\/comments\//, '/'+event.command+'/').replace('http://www.reddit.com/', '').replace('http://reddit.com/', '')
        AppAssistant.openFrontpage("clone", {permalink:url}, @controller)
      when 'sort hot','sort new','sort controversial','sort top','sort old','sort confidence'
        params = event.command.split(' ')
        @loadComments({sort: params[1]})
    
  updateHeading: (text) ->
    text = '' unless text?
    text = text.substr(0, 40)

    if not @showBackNavigation()
      @viewMenuModel.items[0].items[1].label = text
    else
      @viewMenuModel.items[0].items[2].label = text
      
    @controller.modelChanged(@viewMenuModel)

  getModHash: ->
    @modhash

  populateComments: (object) ->
    unless @article?
      @article = object[0].data.children[0].data
      @comment_list.setArticle({kind: 't3', data: @article})
      @updateHeading(@article.title)
      @comment_list.comments.items.push({kind: 't3', data: @article})
      @controller.modelChanged(@comment_list.comments)
    
    @comment_list.populateReplies(object[1].data.children, 0, @comment_list.comments)
    
    @controller.modelChanged(@comment_list.comments)
    
    #@controller.get('list').mojo.setLengthAndInvalidate(@comment_list.comments.items.length)

  fetchComments: (params) ->
    params.url = @url + '.json'    
    new Article(@).comments(params)
  
  handlefetchCommentsResponse: (response) ->
    return unless response? and response.responseJSON?
    
    json = response.responseJSON
    @modhash = json[0].data.modhash if json[0].data? and json[0].data.modhash?

    @populateComments(json)
    
    @controller.get('loadMoreButton').hide()
    
    if @jump_to_comment?
      @controller.getSceneScroller().mojo.revealElement(@jump_to_comment)
      @jump_to_comment = null

  handleCallback: (params) ->
    return params unless params? and params.success
    
    @spinSpinner(false)
    
    params.type = params.type.split(' ')
    index = -1

    if params.type[0] is "article-save"
      Banner.send("Saved!")
    else if params.type[0] is "article-comments"
      @handlefetchCommentsResponse(params.response)

  mailArticle: ->
    @controller.serviceRequest(
      "palm://com.palm.applicationManager",
      {
        method: 'open'
        parameters:
          id: "com.palm.app.email",
          params:
            summary: @article.title,
            text: 'http://reddit.com' + @article.permalink,
            recipients: [{
              type:"email",
              role:1,
              value:"",
              contactDisplay:""
            }]
      }
    )

  smsArticle: ->
    @controller.serviceRequest(
      "palm://com.palm.applicationManager"
      {
        method: 'open'
        parameters:
          id: "com.palm.app.messaging",
          params:
            messageText: @article.title + "\n\n" + 'http://reddit.com' + @article.permalink
      }
    )

  saveArticle: ->
    params =
      executed: 'saved'
      id: @article.name
      uh: @modhash
      renderstyle: 'html'

    new Article(@).save(params)
  
  isLoggedIn: ->
    @modhash and (@modhash isnt "")
  