class FrontpageAssistant extends PowerScrollBase
  
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
      else
        @search = params

  setup: ->
    StageAssistant.setTheme(this)
    
    @controller.setupWidget "spinner", this.attributes = {}, this.model = {spinning: true}
    
    new_items = [{label:$L("what's new"), command:$L("category new")},{label:$L("new"), command:$L("category new sort new")},{label:$L("rising"), command:$L("category new sort rising")}]
    controversial_items = [{label:$L("today"), command:$L("category controversial t day")},{label:$L("this hour"), command:$L("category controversial t hour")},{label:$L("this week"), command:$L("category controversial t week")},{label:$L("this month"), command:$L("category controversial t month")},{label:$L("this year"), command:$L("category controversial t year")},{label:$L("all time"), command:$L("category controversial t all")}]
    top_items = [{label:$L("today"), command:$L("category top t day")},{label:$L("this hour"), command:$L("category top t hour")},{label:$L("this week"), command:$L("category top t week")},{label:$L("this month"), command:$L("category top t month")},{label:$L("this year"), command:$L("category top t year")}]

    @controller.setupWidget('category-submenu', null, {items: [
      {label:$L("hot"), command:$L("category hot")},
      {label:$L("new"), items: new_items},
      {label:$L("controversial"), items: controversial_items},
      {label:$L("top"), items: top_items},
      {label:$L("saved"), command:$L("category saved")}
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
    
    this.subredditSubmenuModel = {items: array}

    @controller.setupWidget('subreddit-submenu', null, this.subredditSubmenuModel)
    
    heading = if @reddit_api.subreddit? then @reddit_api.subreddit else 'Frontpage'

    @viewMenuModel = {
      visible: true
      items: [
        items: [
          {}
          { label: '', submenu: "subreddit-submenu", icon: "search", width: 60}
          { label: heading, command: 'new-card', icon: "", width: Mojo.Environment.DeviceInfo.screenWidth - 120}
          { label: '', submenu: "category-submenu", width: 60, iconPath: 'images/options.png'}
          {}
        ]
      ]
    }
    
    @controller.setupWidget(Mojo.Menu.viewMenu, { menuClass:'no-fade' }, @viewMenuModel)

    this.helpMenuDisabled = false

    @controller.setupWidget(Mojo.Menu.appMenu, {omitDefaultItems: true}, StageAssistant.appMenuModel)

    @controller.setupWidget('filterfield', {delay: 2000})
    @controller.listen('filterfield', Mojo.Event.filter, this.filter.bind(this))

    @controller.setupWidget("article-list", {
      itemTemplate: "frontpage/article"
      emptyTemplate: "frontpage/emptylist"
      nullItemTemplate: "list/null_item_template"
      swipeToDelete: true
      preventDeleteProperty: 'can_unsave'
      lookahead: 25
      renderLimit: 1000
      formatters: 
        tag: this.tagFormatter.bind(this)
        thumbnail: this.thumbnailFormatter.bind(this)
        vote: this.voteFormatter.bind(this)
      }, @articles)

    this.activityButtonModel = {label : "Load more"}
    @controller.setupWidget("loadMoreButton", {type:Mojo.Widget.activityButton}, this.activityButtonModel)
    @controller.get('loadMoreButton').hide()

    this.itemTappedBind = this.itemTapped.bind(this)
    this.loadMoreArticlesBind = this.loadMoreArticles.bind(this)
    this.handleDeleteItemBind = this.handleDeleteItem.bind(this)
    this.handleKeyUpBind = this.handleKeyUp.bindAsEventListener(this)
    this.handleKeyDownBind = this.handleKeyDown.bindAsEventListener(this)

    Mojo.Event.listen(@controller.get("article-list"), Mojo.Event.listTap, this.itemTappedBind)
    Mojo.Event.listen(@controller.get("article-list"), Mojo.Event.listDelete, this.handleDeleteItemBind)
    Mojo.Event.listen(@controller.document,Mojo.Event.keyup, this.handleKeyUpBind, true)
    Mojo.Event.listen(@controller.document,Mojo.Event.keydown, this.handleKeyDownBind, true)
    Mojo.Event.listen(@controller.get("loadMoreButton"), Mojo.Event.tap, this.loadMoreArticlesBind)

  activate: (event) ->
    super
    StageAssistant.defaultWindowOrientation(this, "free")
    this.metakey = false

    if @articles.items.length is 0
      if @search?
        @searchReddit(@search)
      else if @reddit_api.subreddit is 'random'
        this.switchSubreddit(@reddit_api.subreddit)
      else
        this.loadArticles()

    this.fetchSubreddits('mine')

  deactivate: (event) ->
    super

  cleanup: (event) ->
    Request.clear_all()
    
    Mojo.Event.stopListening(@controller.document,Mojo.Event.keyup, this.handleKeyUpBind)
    Mojo.Event.stopListening(@controller.document,Mojo.Event.keydown, this.handleKeyDownBind)
    Mojo.Event.stopListening(@controller.get("article-list"), Mojo.Event.listTap, this.itemTappedBind)
    Mojo.Event.stopListening(@controller.get("article-list"), Mojo.Event.listDelete, this.handleDeleteItemBind)
    Mojo.Event.stopListening(@controller.get("loadMoreButton"), Mojo.Event.tap, this.loadMoreArticlesBind)

  tagFormatter: (propertyValue, model) ->
    return "" unless model.data?
      
    if @reddit_api.subreddit is model.data.subreddit
      return (model.data.ups - model.data.downs) + " points " + StageAssistant.timeFormatter(model.data.created_utc) + " by " + model.data.author
    
    (model.data.ups - model.data.downs) + " points in " + model.data.subreddit + " by " + model.data.author
  
  thumbnailFormatter: (propertyValue, model) ->
    Article.thumbnailFormatter(model)
    
  voteFormatter: (propertyValue, model) ->
    return '' if model.kind isnt 't1' and model.kind isnt 't3'
    return '+1' if model.data.likes is true
    return '-1' if model.data.likes is false
    ''
    
  filter: (filterEvent) ->
    return if filterEvent.filterString.length is 0
    
    @controller.get('filterfield').mojo.close()
    @searchReddit(filterEvent.filterString)
  
  handleKeyUp: (event) ->
    e = event.originalEvent
    this.metakey = false if e.metaKey is false
  
  handleKeyDown: (event) ->
    e = event.originalEvent
    this.metakey = true if e.metaKey is true
  
  spinSpinner: (bool) ->
    if bool
      @controller.get('loading').show()
    else
      @controller.get('loading').hide()
  
  handleCategorySwitch: (params) ->
    return unless params?
    
    if params.length is 2
      @reddit_api.setCategory(params[1])
    else
      @reddit_api.setCategory(params[1], {key: params[2], value: params[3]})
    
    this.loadArticles()
  
  showMessageInbox: ->
    @controller.stageController.pushScene({name:"message",transition: Mojo.Transition.crossFade},{action:'inbox'})
  
  showComposeMessage: ->
    @controller.stageController.pushScene({name:"compose-message",transition: Mojo.Transition.crossFade},{action:'compose'})
  
  handleCallback: (params) ->
    return params unless params? and params.success
  
    this.spinSpinner(false)
  
    index = -1
    params.type = params.type.split(' ')

    switch params.type[0]
      when "article-unsave"
        if params.type[1]?
          index = this.findArticleIndex(params.type[1])
      
          if index > -1
            @articles.items[index].data.saved = false
            @controller.get('article-list').mojo.noticeUpdatedItems(index, [@articles.items[index]])
    
        new Banner("Unsaved!").send()
      when "article-save"
        if params.type[1]?
          index = this.findArticleIndex(params.type[1])
      
          if index > -1
            @articles.items[index].data.saved = true
            @controller.get('article-list').mojo.noticeUpdatedItems(index, [@articles.items[index]])
    
        new Banner("Saved!").send()
      when 'load-articles'
        this.handleLoadArticlesResponse(params.response)
      when 'random-subreddit'
        this.handleRandomSubredditResponse(params.response)
      when 'subreddit-load'
        this.handleFetchSubredditsResponse(params.response)
      when 'subreddit-load-mine'
        this.handleFetchSubredditsResponse(params.response)
        this.fetchSubreddits()
      when "comment-upvote"
        index = this.findArticleIndex(params.type[1])

        if index > -1
          if not @articles.items[index].data.likes is false
            @articles.items[index].data.downs--

          @articles.items[index].data.likes = true
          @articles.items[index].data.ups++
          @controller.get('article-list').mojo.noticeUpdatedItems(index, [@articles.items[index]])
    
        new Banner("Upvoted!").send()
      when "comment-downvote"
        index = this.findArticleIndex(params.type[1]);
    
        if index > -1
          if @articles.items[index].data.likes is true
            @articles.items[index].data.ups--

          @articles.items[index].data.likes = false
          @articles.items[index].data.downs++
          @controller.get('article-list').mojo.noticeUpdatedItems(index, [@articles.items[index]])
    
        new Banner("Downvoted!").send()
      when "comment-vote-reset"
        index = this.findArticleIndex(params.type[1])
    
        if index > -1
          if @articles.items[index].data.likes is true
            @articles.items[index].data.ups--
          else
            @articles.items[index].data.downs--

          @articles.items[index].data.likes = null     
          @controller.get('article-list').mojo.noticeUpdatedItems(index, [@articles.items[index]])
    
        new Banner("Vote reset!").send()

  handleDeleteItem: (event) ->
    this.unsaveArticle(event.item)
    @articles.items.splice(event.index, 1)
  
  subredditsLoaded: ->
    Subreddit.cached_list.length > 0
  
  fetchSubreddits: (type) ->
    return if this.subredditsLoaded()
    
    if type is 'mine'
      new Request(this).get('http://www.reddit.com/reddits/mine/.json', {}, 'subreddit-load-mine')
    else
      new Request(this).get('http://www.reddit.com/reddits/.json', {}, 'subreddit-load')
  
  searchReddit: (searchTerm) ->
    @reddit_api.setSearchTerm(searchTerm)
    this.loadArticles()
  
  randomSubreddit: ->
    new Request(this).get('http://www.reddit.com/r/random/', {}, 'random-subreddit')
  
  switchSubreddit: (subreddit) ->
    return unless subreddit?
  
    if subreddit is 'random'
      this.spinSpinner(true)
      this.randomSubreddit()
      return
  
    @reddit_api.setSubreddit(subreddit)
    this.loadArticles()
  
  updateHeading: (text) ->
    text = '' unless text?
  
    @viewMenuModel.items[0].items[2].label = text
    @controller.modelChanged(@viewMenuModel)
  
  loadMoreArticles: ->
    @reddit_api.load_next = true
    this.loadArticles()
  
  displayLoadingButton: ->
    @controller.get('loadMoreButton').mojo.activate()
    this.activityButtonModel.label = "Loading"
    this.activityButtonModel.disabled = true
    @controller.modelChanged(this.activityButtonModel)
  
  loadArticles: ->
    parameters = {}
    parameters.limit = @reddit_api.getArticlesPerPage()
    
    if @reddit_api.load_next
      parameters.after = @articles.items[@articles.items.length - 1].data.name
      this.displayLoadingButton()
    else
      length = @articles.items.length
      @articles.items.clear()
      @controller.get('loadMoreButton').hide()
      this.spinSpinner(true)
      @controller.get('article-list').mojo.noticeRemovedItems(0, length)
    
    if @reddit_api.subreddit?
      this.updateHeading(@reddit_api.subreddit)
    else if @reddit_api.domain?
      this.updateHeading(@reddit_api.domain)
    else if @reddit_api.search?
      this.updateHeading(@reddit_api.search)
      parameters.q = @reddit_api.search
      parameters.restrict_sr = 'off'
      parameters.sort = 'relevance'
    else
      this.updateHeading(null)
  
    new Request(this).get(@reddit_api.getArticlesUrl(), parameters, 'load-articles')
  
  handleLoadArticlesResponse: (response) ->
    @reddit_api.load_next = false
    json = response.responseJSON
  
    return unless response.responseJSON?
    
    data = if json.length > 0 then json[1].data else json.data
    
    @modhash = data.modhash
    items = data.children
    
    _.each items, (item) ->
      item.can_unsave = if item.data.saved then false else true
      @articles.items.push(item)
    
    @controller.modelChanged(@articles)
    this.spinSpinner(false)
    @controller.get('loadMoreButton').mojo.deactivate()
    this.activityButtonModel.label = "Load more"
    this.activityButtonModel.disabled = false
    @controller.modelChanged(this.activityButtonModel)
  
    if items.length > 0
      @controller.get('loadMoreButton').show()
    else
      @controller.get('loadMoreButton').hide()
    
    if @articles.items.length is 0
      @controller.get('article-list').mojo.noticeAddedItems(0, [null])
  
  handleRandomSubredditResponse:(response) ->
    headers = response.getAllHeaders()
    start_offset = headers.indexOf('Location: /r/') + 13
    end_offset = headers.indexOf('/', start_offset)
    subreddit = headers.substring(start_offset, end_offset)
  
    this.switchSubreddit(subreddit)
  
  handleFetchSubredditsResponse: (response) ->
    Mojo.Log.info(response);
    return unless response? and response.responseJSON? and response.responseJSON.data?
     
    data = response.responseJSON.data
    children = data.children
    array = []
    i = 0
    
    _.each children, (child) ->
      Subreddit.cached_list.push {label: child.data.display_name, subscribed: (data.modhash? and data.modhash isnt ""), name: child.data.name}
    
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
    
    this.subredditSubmenuModel.items = array
    @controller.modelChanged this.subredditSubmenuModel
  
  handleActionSelection: (command) ->
    return unles command?
    
    params = command.split ' '
  
    if params[0] is 'domain-cmd'
      @reddit_api.setDomain(params[1])
      this.loadArticles()
    else if params[0] is 'comments-cmd'
      article = @articles.items[parseInt(params[1])]
      @controller.stageController.pushScene({name:"article"}, {article: article})
    else if params[0] is 'upvote-cmd'
      this.spinSpinner(true)
      this.voteOnComment('1', params[1], params[2])
    else if params[0] is 'downvote-cmd'
      this.spinSpinner(true)
      this.voteOnComment('-1', params[1], params[2])
    else if params[0] is 'reset-vote-cmd'
      this.spinSpinner(true)
      this.voteOnComment('0', params[1], params[2])
    else if params[0] is 'save-cmd'
      this.spinSpinner(true)
      this.saveArticle(@articles.items[params[1]])
    else if params[0] is 'unsave-cmd'
      this.spinSpinner(true)
      this.unsaveArticle(@articles.items[params[1]])
  
  findArticleIndex: (article_name) ->
    index = -1
    
    _.each @articles.items, (item, i) ->
      index = i if item.data.name is article_name
  
    index
  
  saveArticle: (article) ->
    params:
      executed: 'saved'
      id: article.data.name
      uh: @modhash
  
    new Article(this).save(params)
  
  unsaveArticle: (article) ->
    params:
      executed: 'unsaved'
      id: article.data.name
      uh: @modhash
  
    new Article(this).unsave(params)
  
  voteOnComment: (dir, comment_name, subreddit) ->
    params:
      dir: dir
      id: comment_name
      uh: @modhash
      r: subreddit
  
    if dir is 1
      new Comment(this).upvote(params)
    else if dir is -1
      new Comment(this).downvote(params)
    else
      new Comment(this).reset_vote(params)
  
  isLoggedIn: ->
    @modhash and @modhash isnt ""
  
  itemTapped: (event) ->
    article = event.item
    element_tapped = event.originalEvent.target
  
    if element_tapped.className.indexOf('comment_counter') isnt -1
      AppAssistant.cloneCard(this, {name:"article"}, {article: article})
      return
  
    if element_tapped.id.indexOf('image_') isnt -1
      StageAssistant.cloneImageCard(this, article)
      return
  
    if element_tapped.id.indexOf('youtube_') isnt -1 or element_tapped.id.indexOf('web_') isnt -1
      @controller.serviceRequest "palm://com.palm.applicationManager", {
        method : "open",
        parameters: {
          target: Linky.parse(article.data.url).url
          onSuccess: ->
          onFailure: ->
        }
      }
        
      return
    
    if this.isLoggedIn()
      upvote_icon = if article.data.likes is true then 'selected_upvote_icon' else 'upvote_icon'
      downvote_icon = if article.data.likes is false then 'selected_downvote_icon' else 'downvote_icon'
      upvote_action = if article.data.likes is true then 'reset-vote-cmd' else 'upvote-cmd'
      downvote_action = if article.data.likes is false then 'reset-vote-cmd' else 'downvote-cmd'
      save_action = if article.data.saved is true then 'unsave-cmd' else 'save-cmd'
      save_label = if article.data.saved is true then 'Unsave' else 'Save'
  
      @controller.popupSubmenu {
       onChoose: this.handleActionSelection.bind(this),
       placeNear:element_tapped,
       items: [                         
         {label: $L('Upvote'), command: upvote_action + ' ' + article.data.name + ' ' + article.data.subreddit, secondaryIcon: upvote_icon},
         {label: $L('Downvote'), command: downvote_action + ' ' + article.data.name + ' ' + article.data.subreddit, secondaryIcon: downvote_icon},
         {label: $L('Comments'), command: 'comments-cmd ' + event.index},
         {label: $L(save_label), command: save_action + ' ' + event.index},
         {label: $L(article.data.domain), command: 'domain-cmd ' + article.data.domain}]
      }
    else
      @controller.popupSubmenu {
       onChoose: this.handleActionSelection.bind(this),
       placeNear:element_tapped,
       items: [
         {label: $L('Comments'), command: 'comments-cmd ' + event.index},
         {label: $L(article.data.domain), command: 'domain-cmd ' + article.data.domain}]
       }
  
  handleCommand: (event) ->
    return if event.type isnt Mojo.Event.command
  
    params = event.command.split(' ')
  
    this.handleCategorySwitch(params) is params[0] is 'category'
  
    switch params[0]
      when 'new-card'
        AppAssistant.cloneCard()
      when 'subreddit'
        this.switchSubreddit(params[1])
    
    controller = Mojo.Controller.getAppController().getActiveStageController()
    currentScene = controller.activeScene()
  
    switch event.type
      when Mojo.Event.commandEnable
        switch event.command
          when Mojo.Menu.prefsCmd
            if not currentScene.assistant.prefsMenuDisabled
              event.stopPropagation()
          when Mojo.Menu.helpCmd
            if not currentScene.assistant.helpMenuDisabled
              event.stopPropagation()
        
      when Mojo.Event.command
        switch event.command
          when Mojo.Menu.helpCmd
            controller.pushScene('support')
          when Mojo.Menu.prefsCmd
            AppAssistant.cloneCard(this, {name:"prefs"}, {})
          when 'login-cmd'
            controller.pushScene({name:"login",transition: Mojo.Transition.crossFade})
          when 'logout-cmd'
            new User(this).logout({})        
          when 'register-cmd'
            controller.pushScene({name:"register",transition: Mojo.Transition.crossFade})
          when 'reddits-cmd'
            AppAssistant.cloneCard(this, {name:"reddits"}, {})
          when 'gallery-cmd'
            AppAssistant.cloneCard(this, {name:"gallery"}, {})
          when 'recent-comments-cmd'
            AppAssistant.cloneCard(this, {name:"recent-comment"}, {})
          when 'messages-cmd'
            AppAssistant.cloneCard(this, {name:"message"}, {})
