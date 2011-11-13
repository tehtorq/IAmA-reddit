class SplitFrontpageAssistant extends PowerScrollBase
  
  constructor: (params) ->
    super
    
    @articles = { items : [] }
    @reddit_api = new RedditAPI()
    @params = params
    
    default_frontpage = StageAssistant.cookieValue("prefs-frontpage", "frontpage")
        
    @reddit_api.setSubreddit(default_frontpage)

    if params?
      if params.reddit?
        @reddit_api.setSubreddit(params.reddit)
      else if params.permalink?
        @reddit_api.set_permalink(params.permalink)
      else if params.search?
        @search = unescape(params.search)

  setup: ->
    super
    
    Preferences.updateNotifications()
    
    @controller.setupWidget "spinner", @attributes = {}, @model = {spinning: true}
    @controller.setupWidget "comment-spinner", @attributes = {}, @model = {spinning: false}
    
    new_items = [{label:$L("what's new"), command:$L("category new")},{label:$L("new"), command:$L("category new sort new")},{label:$L("rising"), command:$L("category new sort rising")}]
    controversial_items = [{label:$L("today"), command:$L("category controversial t day")},{label:$L("this hour"), command:$L("category controversial t hour")},{label:$L("this week"), command:$L("category controversial t week")},{label:$L("this month"), command:$L("category controversial t month")},{label:$L("this year"), command:$L("category controversial t year")},{label:$L("all time"), command:$L("category controversial t all")}]
    top_items = [{label:$L("today"), command:$L("category top t day")},{label:$L("this hour"), command:$L("category top t hour")},{label:$L("this week"), command:$L("category top t week")},{label:$L("this month"), command:$L("category top t month")},{label:$L("this year"), command:$L("category top t year")}]

    @controller.setupWidget('category-submenu', null, {items: [
      {label:$L("hot"), command:$L("category hot")}
      {label:$L("new"), items: new_items}
      {label:$L("controversial"), items: controversial_items}
      {label:$L("top"), items: top_items}
      {label:$L("saved"), command:$L("category saved")}
      {label:$L("friends"), command:$L("subreddit friends")}
      ]})
    
    array = []
    
    if Subreddit.cached_list.length > 0    
      # subscribed reddits
      
      _.each Subreddit.cached_list, (item) ->
        if item.subscribed is true
          array.push {label: item.label, command: 'subreddit ' + item.label}
      
      # unsubscribed reddits
      
      if array.length is 0
        _.each Subreddit.cached_list, (item) ->
          if item.subscribed isnt true
            array.push {label: item.label, command: 'subreddit ' + item.label}
      
      array.sort (a, b) ->
        return -1 if a.label.toLowerCase() < b.label.toLowerCase()
        return 1 if a.label.toLowerCase() > b.label.toLowerCase()
        0
    
      array.unshift({label: 'random', command: 'subreddit random'})
      array.unshift({label: 'all', command: 'subreddit all'})
      array.unshift({label: 'frontpage', command: 'subreddit frontpage'})
    
    @subredditSubmenuModel = {items: array}

    @controller.setupWidget('subreddit-submenu', null, @subredditSubmenuModel)
    
    heading = if @reddit_api.subreddit? then @reddit_api.subreddit else 'Frontpage'

    if not @showBackNavigation()
      @viewMenuModel =
        visible: true
        items: [
          items: [
            {}
            { label: $L('/r'), submenu: "subreddit-submenu", icon: "", width: 61}
            { label: heading, command: 'new-card', icon: "", width: @getViewMenuWidth() - 181}
            {label: $L('Search'), icon:'search', command:'search'}
            { label: '', submenu: "category-submenu", width: 60, iconPath: 'images/options.png'}
            {}
          ]
        ]
    else
      @viewMenuModel =
        visible: true
        items: [
          items: [
            {}
            { label: $L('/r'), submenu: "subreddit-submenu", icon: "", width: 61}
            {label: $L('Back'), icon:'', command:'back', width:80}
            { label: heading, command: 'new-card', icon: "", width: @getViewMenuWidth() - 261}
            {label: $L('Search'), icon:'search', command:'search'}
            { label: '', submenu: "category-submenu", width: 60, iconPath: 'images/options.png'}
            {}
          ]
        ]    
    
    @controller.setupWidget(Mojo.Menu.viewMenu, { menuClass:'no-fade' }, @viewMenuModel)

    @helpMenuDisabled = false
      
    menu_items = [
      {label: "Friends", command: 'friend-scene'}
      {label: "Gallery", command: 'gallery-cmd'}
      {label: "Manage User", items:
        [
          {label: "Login", command: 'login-cmd'}
          {label: "Register", command: 'register-cmd'}
          #{label: "Logout", command: 'logout-cmd'}
        ]}
      {label: "Messages", items:
        [
          {label: "Compose", command: 'compose-message-cmd'}
          {label: "Inbox", command: 'messages-cmd'}
        ]}
      {label: "Recent Comments", command: 'recent-comments-cmd'}
      {label: "Reddits", command: 'reddits-cmd'}
      {label: "Preferences", command: Mojo.Menu.prefsCmd}
      {label: "About", command: 'about-scene'}
    ]
    
    if Mojo.appInfo.id is 'com.tehtorq.reddit-hb'
      menu_items = _.union([
        {label: "Donate", command: 'donation-cmd'}
        {label: "Purchase", command: 'purchase-cmd'}
      ], menu_items)

    @controller.setupWidget(Mojo.Menu.appMenu, {omitDefaultItems: true}, {visible: true, items: menu_items})

    @controller.setupWidget('filterfield', {delay: 2000})
    @controller.listen('filterfield', Mojo.Event.filter, @filter)

    @controller.setupWidget("article-list", {
      itemTemplate: "frontpage/article"
      emptyTemplate: "frontpage/emptylist"
      nullItemTemplate: "list/null_item_template"
      swipeToDelete: true
      preventDeleteProperty: 'can_unsave'
      formatters: 
        tag: @tagFormatter
        thumbnail: @thumbnailFormatter
        vote: @voteFormatter
      }, @articles)
      
    @comment_list = new CommentList('', @)

    @activityButtonModel = {label : "Load more"}
    @controller.setupWidget("loadMoreButton", {type:Mojo.Widget.activityButton}, @activityButtonModel)
    @controller.get('loadMoreButton').hide()
    
    @loadingCommentsButtonModel = {label : "Loading comments"}
    @controller.setupWidget("loadingCommentsButton", {type:Mojo.Widget.activityButton}, @loadingCommentsButtonModel)
    @controller.get('loadingCommentsButton').hide()
    
    this.controller.setupWidget("article-scroller",
      this.attributes = {
          mode: 'vertical'
      },
      this.model = {
      }
    );
    
    this.controller.setupWidget("comment-scroller",
      this.attributes = {
          mode: 'vertical'
      },
      this.model = {
      }
    );
  
  activate: (event) ->
    super
    
    @addListeners(
      [@controller.window, 'resize', @handleOrientationChange, false]
      # [document, 'orientationchange', @handleOrientationChange]
      [@controller.get("article-list"), Mojo.Event.listTap, @itemTapped]
      [@controller.get("article-list"), Mojo.Event.hold, @itemHold]
      [@controller.get("article-list"), Mojo.Event.listDelete, @handleDeleteItem]
      [@controller.get("loadMoreButton"), Mojo.Event.tap, @loadMoreArticles]
      [@controller.get("comment-list"), Mojo.Event.listTap, @comment_list.itemTapped]
      [@controller.get("comment-list"), Mojo.Event.hold, @comment_list.itemHold]
    )
    
    @spinCommentSpinner(false)
    
    if event? and event.replied is true
      item = @comment_list.comments.items[0]
      @comment_list.comments.items.clear()
      @comment_list.comments.items.push(item)
      @jump_to_comment = event.comment_id
    
      if @comment_list.comments.items.length < 2
        #@controller.get('loadMoreButton').mojo.activate()
        @loadArticleComments({kind: 't3', data: @comment_list.article}, true)
      
      return

    if @articles.items.length is 0
      if @search?
        @searchReddit(@search)
      else if @reddit_api.subreddit is 'random'
        @switchSubreddit(@reddit_api.subreddit)
      else
        @loadArticles()

    @fetchSubreddits('mine')

  deactivate: (event) ->
    super
  
  cleanup: (event) ->
    super
  
  tagFormatter: (propertyValue, model) =>
    return "" unless model.data?
      
    if @reddit_api.subreddit is model.data.subreddit
      return (model.data.ups - model.data.downs) + " points " + StageAssistant.timeFormatter(model.data.created_utc) + " by " + model.data.author
    
    (model.data.ups - model.data.downs) + " points in " + model.data.subreddit + " by " + model.data.author
  
  thumbnailFormatter: (propertyValue, model) =>
    Article.thumbnailFormatter(model)
    
  voteFormatter: (propertyValue, model) =>
    return '' if model.kind not in ['t1','t3']
    return '+1' if model.data.likes is true
    return '-1' if model.data.likes is false
    ''

  getModHash: ->
    @modhash
  
  ready: ->
    @controller.get('article-scroller').style.height = "#{@controller.window.innerHeight - 50}px"
    @controller.get('comment-scroller').style.height = "#{@controller.window.innerHeight - 50}px"
    
  handleOrientationChange: (orientation) =>
    @controller.get('article-scroller').style.height = "#{@controller.window.innerHeight - 50}px"
    @controller.get('comment-scroller').style.height = "#{@controller.window.innerHeight - 50}px"
    
  filter: (filterEvent) =>
    return if filterEvent.filterString.length is 0
    
    @controller.get('filterfield').mojo.close()
    @searchReddit(filterEvent.filterString)
  
  handleCategorySwitch: (params) ->
    return unless params?
    
    if params.length is 2
      @reddit_api.setCategory(params[1])
    else
      @reddit_api.setCategory(params[1], {key: params[2], value: params[3]})
    
    @loadArticles()
  
  handleCallback: (params) ->
    return params unless params? and params.success
    
    index = -1
    params.type = params.type.split(' ')
    
    @spinSpinner(false) unless params.type[0] in ['subreddit-load','subreddit-load-mine']

    switch params.type[0]
      when "article-unsave"
        if params.type[1]?
          index = @findArticleIndex(params.type[1])
      
          if index > -1
            @articles.items[index].data.saved = false
            @controller.get('article-list').mojo.noticeUpdatedItems(index, [@articles.items[index]])
    
        Banner.send("Unsaved!")
      when "article-save"
        if params.type[1]?
          index = @findArticleIndex(params.type[1])
      
          if index > -1
            @articles.items[index].data.saved = true
            @controller.get('article-list').mojo.noticeUpdatedItems(index, [@articles.items[index]])
    
        Banner.send("Saved!")
      when 'load-articles'
        @handleLoadArticlesResponse(params.response)
      when 'random-subreddit'
        @handleRandomSubredditResponse(params.response)
      when 'subreddit-load'
        @handleFetchSubredditsResponse(params.response)
      when 'subreddit-load-mine'
        @handleFetchSubredditsResponse(params.response)
        @fetchSubreddits()
      when "comment-upvote"
        index = @findArticleIndex(params.type[1])

        if index > -1
          if not @articles.items[index].data.likes is false
            @articles.items[index].data.downs--

          @articles.items[index].data.likes = true
          @articles.items[index].data.ups++
          @controller.get('article-list').mojo.noticeUpdatedItems(index, [@articles.items[index]])
    
        Banner.send("Upvoted!")
      when "comment-downvote"
        index = @findArticleIndex(params.type[1]);
    
        if index > -1
          if @articles.items[index].data.likes is true
            @articles.items[index].data.ups--

          @articles.items[index].data.likes = false
          @articles.items[index].data.downs++
          @controller.get('article-list').mojo.noticeUpdatedItems(index, [@articles.items[index]])
    
        Banner.send("Downvoted!")
      when "comment-vote-reset"
        index = @findArticleIndex(params.type[1])
    
        if index > -1
          if @articles.items[index].data.likes is true
            @articles.items[index].data.ups--
          else
            @articles.items[index].data.downs--

          @articles.items[index].data.likes = null     
          @controller.get('article-list').mojo.noticeUpdatedItems(index, [@articles.items[index]])
    
        Banner.send("Vote reset!")
      when "article-comments"
        @handlefetchCommentsResponse(params.response)

  handleDeleteItem: (event) =>
    @unsaveArticle(event.item)
    @articles.items.splice(event.index, 1)
  
  subredditsLoaded: ->
    Subreddit.cached_list.length > 0
  
  fetchSubreddits: (type) ->
    return if @subredditsLoaded()
    
    if type is 'mine'
      new Request(@).get('http://www.reddit.com/reddits/mine/.json', {}, 'subreddit-load-mine')
    else
      new Request(@).get('http://www.reddit.com/reddits/.json', {}, 'subreddit-load')
  
  searchReddit: (searchTerm) ->
    @reddit_api.setSearchTerm(searchTerm)
    @loadArticles()
  
  randomSubreddit: ->
    new Request(@).get('http://www.reddit.com/r/random/', {}, 'random-subreddit')
  
  switchSubreddit: (subreddit) ->
    return unless subreddit?
  
    if subreddit is 'random'
      @spinSpinner(true)
      @randomSubreddit()
      return
  
    @reddit_api.setSubreddit(subreddit)
    @loadArticles()
  
  updateHeading: (text) ->
    text = '' unless text?
  
    if not @showBackNavigation()
      @viewMenuModel.items[0].items[2].label = text
    else
      @viewMenuModel.items[0].items[3].label = text
    
    @controller.modelChanged(@viewMenuModel)
  
  loadMoreArticles: =>
    @reddit_api.load_next = true
    @loadArticles()
  
  displayLoadingButton: ->
    @controller.get('loadMoreButton').mojo.activate()
    @activityButtonModel.label = "Loading"
    @activityButtonModel.disabled = true
    @controller.modelChanged(@activityButtonModel)
    
  displayLoadingCommentsButton: (bool) ->
    if bool
      @controller.get('loadingCommentsButton').mojo.activate()
      @controller.get('loadingCommentsButton').show()
    else
      @controller.get('loadingCommentsButton').mojo.deactivate()
      @controller.get('loadingCommentsButton').hide()
  
  loadArticles: ->
    parameters = {}
    parameters.limit = @reddit_api.getArticlesPerPage()
    
    if @reddit_api.load_next
      parameters.after = @articles.items[@articles.items.length - 1].data.name
      @displayLoadingButton()
    else
      @comment_list.comments.items.clear()
      @controller.modelChanged(@comment_list.comments)
      
      length = @articles.items.length
      @articles.items.clear()
      @controller.get('loadMoreButton').hide()
      @spinSpinner(true)
      @controller.modelChanged(@articles)

    if @reddit_api.category? and (@reddit_api.category is 'saved')
      @updateHeading(@reddit_api.category)    
    else if @reddit_api.subreddit?
      @updateHeading(@reddit_api.subreddit)
    else if @reddit_api.domain?
      @updateHeading(@reddit_api.domain)
    else if @reddit_api.search?
      @updateHeading(@reddit_api.search)
      parameters.q = @reddit_api.search
      parameters.restrict_sr = 'off'
      parameters.sort = 'relevance'
    else
      @updateHeading(null)
  
    new Request(@).get(@reddit_api.getArticlesUrl(), parameters, 'load-articles')
  
  handleLoadArticlesResponse: (response) ->
    length = @articles.items.length
    @reddit_api.load_next = false
    json = response.responseJSON
  
    return unless response.responseJSON?
    
    data = if json.length > 0 then json[1].data else json.data
    
    @modhash = data.modhash
    items = data.children
    
    _.each items, (item) =>
      item.can_unsave = if item.data.saved then false else true
      @articles.items.push(item)
    
    @controller.get('article-list').mojo.noticeAddedItems(length, items)
    
    @spinSpinner(false)
    @controller.get('loadMoreButton').mojo.deactivate()
    @activityButtonModel.label = "Load more"
    @activityButtonModel.disabled = false
    @controller.modelChanged(@activityButtonModel)
  
    if items.length > 0
      @controller.get('loadMoreButton').show()
    else
      @controller.get('loadMoreButton').hide()
    
    @controller.get('article-list').mojo.noticeAddedItems(0, [null]) if @articles.items.length is 0
  
  handleRandomSubredditResponse:(response) ->
    headers = response.getAllHeaders()
    start_offset = headers.indexOf('Location: /r/') + 13
    end_offset = headers.indexOf('/', start_offset)
    subreddit = headers.substring(start_offset, end_offset)
  
    @switchSubreddit(subreddit)
  
  handleFetchSubredditsResponse: (response) ->
    return unless response? and response.responseJSON? and response.responseJSON.data?
     
    data = response.responseJSON.data
    children = data.children
    array = []
    i = 0
    
    _.each children, (child) ->
      Subreddit.cached_list.push {label: child.data.display_name, subscribed: (data.modhash? and (data.modhash isnt "")), name: child.data.name}
    
    _.each Subreddit.cached_list, (item) ->
      if item.subscribed is true
        array.push {label: item.label, command: 'subreddit ' + item.label}
    
    # unsubscribed reddits
  
    if array.length is 0
      _.each Subreddit.cached_list, (item) ->
        if item.subscribed isnt true
          array.push {label: item.label, command: 'subreddit ' + item.label}
  
    array.sort (a, b) ->
      return -1 if a.label.toLowerCase() < b.label.toLowerCase()
      return 1 if a.label.toLowerCase() > b.label.toLowerCase()
      0
    
    array.unshift {label: 'random', command: 'subreddit random'}
    array.unshift {label: 'all', command: 'subreddit all'}
    array.unshift {label: 'frontpage', command: 'subreddit frontpage'}
    
    @subredditSubmenuModel.items = array
    @controller.modelChanged @subredditSubmenuModel
  
  handleActionSelection: (command) =>
    return unless command?
    
    params = command.split ' '
  
    switch params[0]
      when 'open-link-cmd'
        article = @articles.items[parseInt(params[1])]
        
        if article.data.url?
          AppAssistant.open(article.data.url)
        else
          @controller.stageController.pushScene({name:"article"}, {article: article})
      when 'domain-cmd'
        @reddit_api.setDomain(params[1])
        @loadArticles()
      when 'upvote-cmd'
        @spinSpinner(true)
        @voteOnComment('1', params[1], params[2])
      when 'downvote-cmd'
        @spinSpinner(true)
        @voteOnComment('-1', params[1], params[2])
      when 'reset-vote-cmd'
        @spinSpinner(true)
        @voteOnComment('0', params[1], params[2])
      when 'save-cmd'
        @spinSpinner(true)
        @saveArticle(@findArticleByName(params[1]))
      when 'unsave-cmd'
        @spinSpinner(true)
        @unsaveArticle(@findArticleByName(params[1]))
  
  findArticleIndex: (article_name) ->
    index = -1
    
    _.each @articles.items, (item, i) ->
      index = i if item.data.name is article_name
  
    index
    
  findArticleByName: (name) ->
    _.first _.select @articles.items, (article) -> article.data.name is name
  
  saveArticle: (article) ->
    params =
      executed: 'saved'
      id: article.data.name
      uh: @modhash
  
    new Article(@).save(params)
  
  unsaveArticle: (article) ->
    params =
      executed: 'unsaved'
      id: article.data.name
      uh: @modhash
  
    new Article(@).unsave(params)
  
  voteOnComment: (dir, comment_name, subreddit) ->
    params =
      dir: dir
      id: comment_name
      uh: @modhash
      r: subreddit
  
    if dir is '1'
      new Comment(@).upvote(params)
    else if dir is '-1'
      new Comment(@).downvote(params)
    else
      new Comment(@).reset_vote(params)
  
  isLoggedIn: ->
    @modhash and (@modhash isnt "")
    
  spinCommentSpinner: (bool) ->
    if bool
      @controller.get('comment-spinner').mojo.start()
      @controller.get('right-pane-loading').show()
    else
      @controller.get('right-pane-loading').hide()
      @controller.get('comment-spinner').mojo.stop()

  startTimer: (article) ->
    @spinCommentSpinner(true)
    @controller.get('comment-scroller').mojo.revealTop()
    @controller.get('right-pane').addClassName('take-it-away')
    
    setTimeout(@loadArticleComments, 500, article)
          
  loadArticleComments: (article, reload = false) =>
    #@controller.get('right-pane').addClassName('take-it-away')
    
    unless reload is true
      #@startTimer()
      @displayLoadingCommentsButton(true)
      @comment_list.setArticle(article)
      @comment_list.comments.items.clear()
      @comment_list.comments.items.push({kind: 't3', data: article.data})
      @controller.modelChanged(@comment_list.comments)
    
    params = {url: 'http://reddit.com' + article.data.permalink + '.json'}
    new Article(@).comments(params)
    
  handlefetchCommentsResponse: (response) ->
    @controller.get('right-pane').removeClassName('take-it-away')
    @controller.get('right-pane').addClassName('bring-it-in')
    @spinCommentSpinner(false)
    @displayLoadingCommentsButton(false)
    return unless response? and response.responseJSON?

    json = response.responseJSON
    @modhash = json[0].data.modhash if json[0].data? and json[0].data.modhash?

    @populateComments(json)

    #@controller.get('loadMoreButton').hide()
    
  populateComments: (object) ->
    @populateCommentReplies(object[1].data.children, 0, @comment_list.comments)
    @controller.modelChanged(@comment_list.comments)
    
  populateCommentReplies: (replies, indent, array) ->
    _.each replies, (child) =>
      if child.kind isnt 'more'

        child.data.indent = indent
        child.easyLinksHTML = StageAssistant.easylinksFormatter(child)

        array.items.push(child)

        data = child.data

        if data.replies?.data?.children?
          unless child?.hiding_comments > 0 
            @populateCommentReplies(data.replies.data.children, indent + 1, array)
  
  itemTapped: (event) =>
    article = event.item
    element_tapped = event.originalEvent.target
  
    if element_tapped.className.indexOf('comment_counter') isnt -1
      @startTimer(article)
      return
  
    if element_tapped.id.indexOf('image_') isnt -1
      StageAssistant.cloneImageCard(@, article)
      return
  
    if element_tapped.id.indexOf('youtube_') isnt -1 or element_tapped.id.indexOf('web_') isnt -1
      AppAssistant.open(Linky.parse(article.data.url).url)
      return
    
    if @isLoggedIn()
      upvote_icon = if article.data.likes is true then 'selected_upvote_icon' else 'upvote_icon'
      downvote_icon = if article.data.likes is false then 'selected_downvote_icon' else 'downvote_icon'
      upvote_action = if article.data.likes is true then 'reset-vote-cmd' else 'upvote-cmd'
      downvote_action = if article.data.likes is false then 'reset-vote-cmd' else 'downvote-cmd'
      save_action = if article.data.saved is true then 'unsave-cmd' else 'save-cmd'
      save_label = if article.data.saved is true then 'Unsave' else 'Save'
  
      @controller.popupSubmenu {
       onChoose: @handleActionSelection,
       #placeNear:element_tapped,
       items: [                         
         {label: $L('Upvote'), command: upvote_action + ' ' + article.data.name + ' ' + article.data.subreddit, secondaryIcon: upvote_icon}
         {label: $L('Downvote'), command: downvote_action + ' ' + article.data.name + ' ' + article.data.subreddit, secondaryIcon: downvote_icon}
         {label: $L('Open Link'), command: 'open-link-cmd ' + event.index}
         {label: $L(save_label), command: save_action + ' ' + article.data.name}
         {label: $L(article.data.domain), command: 'domain-cmd ' + article.data.domain}
         ]
      }
    else
      @controller.popupSubmenu {
       onChoose: @handleActionSelection,
       #placeNear:element_tapped,
       items: [
         {label: $L('Open Link'), command: 'open-link-cmd ' + event.index}
         {label: $L(article.data.domain), command: 'domain-cmd ' + article.data.domain}
         ]
       }
  
  handleCommand: (event) ->
    return if event.type isnt Mojo.Event.command
  
    params = event.command.split(' ')
  
    @handleCategorySwitch(params) if params[0] is 'category'
  
    switch params[0]
      when 'new-card'
        AppAssistant.openFrontpage("clone", {})
      when 'subreddit'
        @switchSubreddit(params[1])
      when 'search'
        @toggleSearch()
      when 'back'
        @controller.stageController.popScene()
    
    switch event.command
      when Mojo.Menu.prefsCmd
        @controller.stageController.pushScene({name:"prefs"}, {})
      when 'login-cmd'
        @controller.stageController.pushScene({name:"login",transition: Mojo.Transition.crossFade}, {})
      when 'logout-cmd'
        new User(@).logout({})        
      when 'register-cmd'
        @controller.stageController.pushScene({name:"register",transition: Mojo.Transition.crossFade}, {})
      when 'reddits-cmd'
        @controller.stageController.pushScene({name:"reddits"}, {})
      when 'gallery-cmd'
        @controller.stageController.pushScene({name:"gallery"}, {})
      when 'recent-comments-cmd'
        @controller.stageController.pushScene({name:"recent-comment"}, {})
      when 'friend-scene'
        @controller.stageController.pushScene({name:"friend"}, {})
      when 'messages-cmd'
        @controller.stageController.pushScene({name:"message"}, {})
      when 'compose-message-cmd'
        @controller.stageController.pushScene({name:"compose-message"},{})
      when 'about-scene'
        @controller.stageController.pushScene({name:"about"}, {})
      when 'donation-cmd'
        AppAssistant.open_donation_link()
      when 'purchase-cmd'
        AppAssistant.open_purchase_link()

  itemHold: (event) =>
    event.preventDefault()
    thing = event.srcElement.up('.thing-container')
    article = @findArticleByName(thing.id)
    
    @controller.stageController.pushScene({name:"article"}, {article: article})
