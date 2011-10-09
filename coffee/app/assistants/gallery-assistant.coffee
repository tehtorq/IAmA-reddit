class GalleryAssistant

  constructor: (params) ->
    @allow_back = params.allow_back
    @cardname = "card" + Math.floor(Math.random()*10000)
    @image_limit = 20
    @fetching_images = false
    @last_article_id = null
    @sr = 'pics'

  handleCallback: (params) ->
    return unless params?
    
    if params.type is "article-list"
      @fetching_images = false
      @handleLoadArticlesResponse(params.response) if params.success?

  setup: ->
    StageAssistant.setTheme(@)
    
    sfw_reddits = StageAssistant.cookieValue("prefs-galleries", '1000words,aviation,battlestations,gifs,itookapicture,photocritique,pics,vertical,wallpaper,wallpapers,windowshots').split(',')
    sfw_reddits_items = []
    
    _.each sfw_reddits, (item) ->
      sfw_reddits_items.push {label: item, command: 'subreddit ' + item}
    
    @subredditSubmenuModel = {items: sfw_reddits_items}

    @controller.setupWidget('subreddit-submenu', null, @subredditSubmenuModel)
    
    if Mojo.Environment.DeviceInfo.keyboardAvailable or not @allow_back
      @viewMenuModel = {
        visible: true,
        items: [
            {items:[{},
                    { label: '', command: "", width: 60},
                    { label: "Reddit", command: 'new-card', icon: "", width: @controller.window.innerWidth - 120},
                    { label: '', submenu: "subreddit-submenu", icon: "search", width: 60},
                    {}]}
        ]
      }
    else
      @viewMenuModel = {
        visible: true,
        items: [
            {items:[{},
                    {label: $L('Back'), icon:'', command:'back', width:80}
                    { label: "Reddit", command: 'new-card', icon: "", width: @controller.window.innerWidth - 140},
                    { label: '', submenu: "subreddit-submenu", icon: "search", width: 60},
                    {}]}
        ]
      }

    @controller.setupWidget(Mojo.Menu.viewMenu, { menuClass:'palm-dark no-fade' }, @viewMenuModel)
    
    appMenuModel =
      visible: true
      items:
        [
          {label: "Frontpage", command: 'frontpage-cmd'}
          {label: "Preferences", command: 'manage-cmd'}
        ]

    @controller.setupWidget(Mojo.Menu.appMenu, {omitDefaultItems: true}, appMenuModel)

    @thumbs = []

    @activityButtonModel = {label : "Load more"}
    @controller.setupWidget("loadMoreButton", {type:Mojo.Widget.activityButton}, @activityButtonModel)

  activate: (event) ->
    Mojo.Event.listen(@controller.get("gallery"), Mojo.Event.tap, @handleTap)
    Mojo.Event.listen(@controller.get("loadMoreButton"), Mojo.Event.tap, @loadImages)
    
    StageAssistant.defaultWindowOrientation(@, "free")
    @switchSubreddit("pics")

  deactivate: (event) ->
    Mojo.Event.stopListening(@controller.get("gallery"), Mojo.Event.tap, @handleTap)
    Mojo.Event.stopListening(@controller.get("loadMoreButton"), Mojo.Event.tap, @loadImages)

  cleanup: (event) ->
    Request.clear_all(@cardname)

  orientationChanged: (orientation) ->
    @controller.stageController.setWindowOrientation(orientation)

  handleTap: (event) =>
    element_tapped = event.target

    if element_tapped? and element_tapped.alt?     
      image_array = []
      articles = []
      
      _.each @thumbs, (thumb) ->
        image_array.push(thumb.url.url)
        articles.push(thumb)
      
      scene = if @sr in ['gif','gifs','nsfw_gif','nsfw_gifs']
        "gif"
      else
        "image"
        
      AppAssistant.cloneCard(@, {name:scene},{index:parseInt(element_tapped.alt),images:image_array, articles:articles})

  storeThumb: (reddit_article) ->
    url = reddit_article.data.url

    if (url.indexOf('.jpg') >= 0) or
        (url.indexOf('.jpeg') >= 0) or
        (url.indexOf('.png') >= 0) or
        (url.indexOf('.gif') >= 0) or
        (url.indexOf('.bmp') >= 0)

      thumb_url = reddit_article.data.thumbnail

      if thumb_url.indexOf('/static/') isnt -1
        thumb_url = 'http://reddit.com' + thumb_url

      @thumbs.push(reddit_article)
  
      mydiv = @controller.document.createElement('img')
      mydiv.setAttribute('src', thumb_url)
      mydiv.setAttribute('alt', @thumbs.length - 1)
      mydiv.setAttribute('style', 'max-height: 80px;border: solid 1px black; margin: 2px; padding: 2px;')
      mydiv.setAttribute('align', 'middle')

      @controller.get('gallery').appendChild(mydiv)

  displayLoadingButton: ->
    @controller.get('loadMoreButton').mojo.activate()
    @activityButtonModel.label = "Loading"
    @activityButtonModel.disabled = true
    @controller.modelChanged(@activityButtonModel)

  displayLoadMoreButton: ->
    @controller.get('loadMoreButton').mojo.deactivate()
    @activityButtonModel.label = "Load more"
    @activityButtonModel.disabled = false
    @controller.modelChanged(@activityButtonModel)

  handleLoadArticlesResponse: (response) ->
    @fetching_images = false
    @displayLoadMoreButton()
    
    return unless response? and response.responseJSON? and response.responseJSON.data? and response.responseJSON.data.children?
    
    items = response.responseJSON.data.children
    
    _.each items, (item) =>
      reddit_article = new Article().load(item.data)
      @last_article_id = reddit_article.data.name
      @storeThumb(reddit_article) #if reddit_article.hasThumbnail() 
  
  clearImages: ->
    @controller.getSceneScroller().mojo.scrollTo(0,0, true)
    @controller.get('gallery').update('')
    @last_article_id = null
    @thumbs.clear()

  loadImages: =>
    return if @fetching_images

    @fetching_images = true
    @displayLoadingButton()

    parameters = {}
    parameters.limit = 100
    parameters.after = @last_article_id if @last_article_id?
    parameters.sr = @sr if @sr?

    new Article(@).list(parameters)
    
  updateHeading: (text) ->
    text = 'Gallery' unless text?

    @viewMenuModel.items[0].items[2].label = text
    @controller.modelChanged(@viewMenuModel)

  switchSubreddit: (subreddit) ->
    return unless subreddit?
    @fetching_images = false
    
    @updateHeading("#{subreddit}")
    @sr = subreddit
    @clearImages()
    @loadImages()

  handleCommand: (event) ->
    return if event.type isnt Mojo.Event.command
    
    controller = Mojo.Controller.getAppController().getActiveStageController()

    switch event.command
      when 'frontpage-cmd'
        @controller.stageController.popScene({name:"frontpage"})
      when 'manage-cmd'
        @controller.stageController.pushScene({name:"prefs"}, {allow_back: true})
      when 'back'
        @controller.stageController.popScene()
      
    params = event.command.split(' ')

    switch params[0]
      when 'subreddit'
        @switchSubreddit(params[1])
