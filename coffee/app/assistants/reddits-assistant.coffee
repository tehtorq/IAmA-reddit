class RedditsAssistant extends BaseAssistant

  constructor: (params) ->
    super
    
    @reddit_api = new RedditAPI()
    @redditsModel = { items : [] }

  setup: ->
    super
    @updateHeading('subreddits')
    
    @controller.setupWidget "spinner", @attributes = {}, @model = {spinning: true}
    
    back_button = if @showBackNavigation()
      {label: $L('Back'), icon:'', command:'back', width:80}
    else
      {}
    
    @controller.setupWidget(Mojo.Menu.commandMenu,
      { menuClass:'no-fade' },
      items: [
        back_button
        {}
        toggleCmd : "popular-cmd"
        items: [
          { label : "Popular", command : "popular-cmd" }
          { label : "New", command : "new-cmd" }
          { label : "Mine", command : "mine-cmd" }
        ]
        {}
        {label: $L('Search'), icon:'search', command:'search'}
      ]
    )
    
    @spinnerModel = {spinning: false}
    
    @controller.setupWidget("progressSpinner",
      attributes =
        spinnerSize: 'large',
        superClass: 'palm-activity-indicator-large',
        fps: 60,
        startLastFrame: 0,
        mainFrameCount: 12,
        frameHeight: 128
      @spinnerModel
    )
    
    @controller.setupWidget(Mojo.Menu.appMenu, {}, {
      visible: true,
      items:
        [
          {label: "Frontpage", command: 'frontpage-cmd'}
        ]
      }
    )
    
    @controller.setupWidget("reddit-list", {
      itemTemplate : "reddits/reddit",
      emptyTemplate : "list/empty_template",
      nullItemTemplate: "list/null_item_template",
      swipeToDelete: true,
      preventDeleteProperty: 'prevent_delete',
      lookahead : 25,
      renderLimit : 1000
      formatters: 
        image: @imageFormatter
    }, @redditsModel)
    
    #@controller.get('puller').hide()

    @controller.setupWidget('filterfield', {delay: 2000})
    @controller.listen('filterfield', Mojo.Event.filter, @filter)

  activate: (event) ->
    super
    
    @addListeners(
      [@controller.get("reddit-list"), Mojo.Event.listTap, @itemTapped]
      [@controller.get("reddit-list"), Mojo.Event.hold, @itemHold]
      [@controller.get("puller"), Mojo.Event.tap, @loadMore]
      [@controller.get("reddit-list"), Mojo.Event.listDelete, @handleDeleteItem]
      [@controller.getSceneScroller(), Mojo.Event.dragging, @handleScrollUpdate]
    )
    
    @loadReddits() if @redditsModel.items.length is 0
    
  imageFormatter: (propertyValue, model) =>
    if model.header_img? and model.header_img isnt ""
      return "<img class='subreddit_header_image' src='#{model.header_img}'>"
        
    ""
  
  handleCategorySwitch: (category) ->
    @reddit_api.setRedditsCategory(category)
    @loadReddits()
    
  handleCommand: (event) ->
    return if event.type isnt Mojo.Event.command

    switch event.command
      when 'top'
        @scrollToTop()
      when 'frontpage-cmd'
        @controller.stageController.swapScene({name:AppAssistant.frontpageSceneName()})
      when 'popular-cmd'
        @handleCategorySwitch('popular')
      when 'new-cmd'
        @handleCategorySwitch('new')
      when 'mine-cmd'
        @handleCategorySwitch('mine')
      when 'back'
        @controller.stageController.popScene()
      when 'search'
        @toggleSearch()

  filter: (filterEvent) =>
    return if filterEvent.filterString.length is 0

    @controller.get('filterfield').mojo.close()
    @searchReddits(filterEvent.filterString)
  
  searchReddits: (searchTerm) ->
    @reddit_api.setRedditsSearchTerm(searchTerm)
    #@updateHeading(searchTerm)
    @loadReddits()

  handleCallback: (params) ->
    return params unless params? and params.success
    
    params.type = params.type.split(' ')

    if params.type[0] is "subreddit-subscribe"
      if params.type[1]?
        Subreddit.cached_list = _.select Subreddit.cached_list, (item) -> item.command isnt "subreddit #{params.type[2]}"
        Subreddit.cached_list.push({label: params.type[2], command: 'subreddit ' + params.type[2], subscribed: true})
      
      Banner.send("Subscribed!")
    else if params.type[0] is "subreddit-unsubscribe"
      if params.type[1]?
        Subreddit.cached_list = _.select Subreddit.cached_list, (item) -> item.command isnt "subreddit #{params.type[2]}"
      
      Banner.send("Unsubscribed!")
    else if params.type[0] is "subreddit-load"
      @handleLoadRedditsResponse(params.response)

  subscribe: (subreddit_name, display_name) ->
    params =
      action: 'sub'
      sr: subreddit_name
      uh: @getModHash()
      display_name: display_name

    new Subreddit(@).subscribe(params)

  unsubscribe: (subreddit_name, display_name) ->
    params =
      action: 'unsub'
      sr: subreddit_name
      uh: @getModHash()
      display_name: display_name

    new Subreddit(@).unsubscribe(params)

  handleDeleteItem: (event) =>
    @unsubscribe(event.item.name, event.item.display_name)

  loadMore: =>
    @loadReddits()

  loadReddits: ->
    @is_loading_content = true
    parameters = {}
    parameters.limit = 25
    @displayButtonLoading()
    
    if @reddit_api.last_reddit?
      parameters.after = @reddit_api.last_reddit
    else
      @controller.get('reddit-list').mojo.noticeRemovedItems(0, @controller.get('reddit-list').mojo.getLength())
    
    if @reddit_api.search?
      parameters.q = @reddit_api.search
      parameters.restrict_sr = 'off'
      parameters.sort = 'relevance'
    
    parameters.url = @reddit_api.getRedditsUrl()
    
    new Subreddit(@).fetch(parameters)

  handleLoadRedditsResponse: (response) ->
    @is_loading_content = false
    return unless response? and response.responseJSON? and response.responseJSON.data?
    items = response.responseJSON.data.children
    
    new_items = []
    new_items.length = 0
    length = @controller.get('reddit-list').mojo.getLength()

    _.each items, (item) =>
      if (length < 1) or (item.data.name isnt @last_name) # ugly hack for possible bug in reddits/mine    
        if item.data.description?
          item.data.description = item.data.description.replace(/\n/gi, "<br/>")
          #item.data.description = item.data.description.replace(/\[([^\]]*)\]\(([^\)]+)\)/gi, "<a class='linky' onClick=\"return false\" href='$2'>$1</a>")
          item.data.description = item.data.description.replace(/\[([^\]]*)\]\(([^\)]+)\)/gi, "<a class='linky' href='$2'>$1</a>")

        item.data.prevent_delete = (@reddit_api.reddits_category isnt 'mine')
        new_items.push(item.data)
        @last_name = item.data.name

    @controller.get('reddit-list').mojo.noticeAddedItems(length, new_items)
    @displayButtonLoadMore()
    
    @reddit_api.last_reddit = response.responseJSON.data.after

    if @reddit_api.last_reddit?
      @controller.get('puller').show()
    else
      @controller.get('puller').hide()
    
    if @controller.get('reddit-list').mojo.getLength() is 0
      @controller.get('reddit-list').mojo.noticeAddedItems(0, [null])

  displayButtonLoadMore: ->
    @controller.get('puller').update('pull to refresh')
    @controller.get('puller').show()

  displayButtonLoading: ->
    @controller.get('puller').update('loading')
    @controller.get('puller').show()

  itemTapped: (event) =>
    item = event.item
    element_tapped = event.originalEvent.target
    
    if event.srcElement.up('.linky')
      Banner.send "linky"
      
    #@log event.srcElement.className, true

    if element_tapped.className is 'linky'
      linky = Linky.parse(element_tapped.href)

      if linky.subtype is 'reddit'
        AppAssistant.openFrontpage("swap", {reddit:linky.reddit}, @controller)
        return

      return

    if element_tapped.className is 'comment_counter'
      @controller.get("drawer_" + item.name).toggleClassName('toggle_hidden')
      return
    
    if @isLoggedIn()
      edit_option = '+frontpage'
      edit_action = 'frontpage-add-cmd'
      
      _.each Subreddit.cached_list, (cached_item) ->
        if (cached_item.label is item.display_name) and (cached_item.subscribed is true)
          edit_option = '-frontpage'
          edit_action = 'frontpage-remove-cmd'
      
      @controller.popupSubmenu({
               onChoose: @handleActionCommand,
               items: [{label: $L('Visit'), command: 'view-cmd ' + item.display_name},
                         {label: $L(edit_option), command: edit_action + ' ' + item.name + ' ' + item.display_name}]
      })
    else
      @controller.popupSubmenu({
               onChoose: @handleActionCommand,
               items: [{label: $L('Visit'), command: 'view-cmd ' + item.display_name}]
      })
      
  itemHold: (event) =>
    event.preventDefault()
    thing = event.srcElement.up('.thing-container')
    reddit = @findByName(thing.id)
    @log "reddit: #{reddit} #{thing.id} "
    AppAssistant.openFrontpage("swap", {reddit:thing.id}, @controller)

  findByName: (name) ->
    _.first _.select @redditsModel.items, (item) -> item.display_name is name
    
  handleActionCommand: (command) =>
    return unless command?

    params = command.split(' ')

    if params[0] is 'view-cmd'
      AppAssistant.openFrontpage("clone", {reddit:params[1]}, @controller)
    else if params[0] is 'frontpage-add-cmd'
      @subscribe(params[1], params[2])
    else if params[0] is 'frontpage-remove-cmd'
      @unsubscribe(params[1], params[2])
