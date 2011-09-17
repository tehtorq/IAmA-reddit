class RecentCommentAssistant extends PowerScrollBase

  constructor: (params) ->
    super
    @params = params
    @commentModel = { items : [] }
    @comments = []

  setup: ->
    StageAssistant.setTheme(@)
    
    @controller.setupWidget("list", {
    itemTemplate : "recent-comment/comment",
    formatters:
      body: @bodyFormatter
      indent: @indentFormatter
      shadowindent: @shadowindentFormatter
    }, @commentModel)

    @itemTappedBind = @itemTapped.bind(@)

    Mojo.Event.listen(@controller.get("list"), Mojo.Event.listTap, @itemTappedBind)

  activate: (event) ->
    super
    StageAssistant.defaultWindowOrientation(@, "free")
    
    @fetchRecentComments() if @commentModel.items.length is 0
    @timerID = @controller.window.setInterval(@tick, 5000)

  deactivate: (event) ->
    super
    @controller.window.clearInterval(@timerID)

  cleanup: (event) ->
    @controller.window.clearInterval(@timerID)
    Request.clear_all()

    Mojo.Event.stopListening(@controller.get("list"), Mojo.Event.listTap, @itemTappedBind)
  
  tick: =>
    current_seconds = (new Date()).getTime() / 1000
    @starting_second = current_seconds unless @starting_second?
    @last_poll_second = current_seconds unless @last_poll_second?
    @fetchRecentComments() if (current_seconds - @last_poll_second) > 5
    @updateList()

  bodyFormatter: (propertyValue, model) =>
    if (model.kind isnt 't1') and (model.kind isnt 't3')
      return "load more comments" if model.kind is 'more'
      return ""
    
    content = ""

    if model.data.selftext?
      content = model.data.selftext
    else
      content = model.data.body

    return "" unless content?
    
    content = content.replace(/\n/gi, "<br/>")
    content = content.replace(/\[([^\]]*)\]\(([^\)]+)\)/gi, "<a class='linky' onClick=\"return false\" href='$2'>$1</a>")
    content
    
  indentFormatter: (propertyValue, model) =>
    return "" if (model.kind isnt 't1') and (model.kind isnt 'more')
    6 + 10 * model.data.indent + ""

  shadowindentFormatter: (propertyValue, model) =>
    return "" if (model.kind isnt 't1') and (model.kind isnt 'more')
    return 12 + 10 * model.data.indent + ""

  handleCommand: (event) ->
    return if event.type isnt Mojo.Event.command
    @scrollToTop() if event.command is 'top'

  scrollToTop: ->
    @controller.getSceneScroller().mojo.scrollTo(0,0, true)

  handleCommentActionSelection: (command) =>
    return unless command?

    params = command.split(' ')

    if params[0] is 'view-cmd'
      #@controller.stageController.popScenesTo("user", {linky:params[1]})
      controller = Mojo.Controller.getAppController().getActiveStageController()
      controller.pushScene({name:"user",transition: Mojo.Transition.crossFade},{user:params[1]})

  populateComments: (object) ->
    _.each object.data.children, (comment) =>  
      comment.data.indent = 0
      @comments.push(comment)
    
    @comments.reverse()
  
  newestTimestamp: ->
    return 0 if @commentModel.items.length is 0
    @commentModel.items[0].data.created_utc
  
  updateList: ->
    return if @comments.length is 0
    
    new_entries = false
    counter = 0
    
    _.each @comments, (comment) =>
      if comment.data.created_utc > @newestTimestamp()
        counter++
        new_entries = true
        @commentModel.items.unshift(comment)
    
    if new_entries
      @controller.get('list').mojo.setLength(@commentModel.items.length)
      @controller.get('list').mojo.noticeUpdatedItems(0, @commentModel.items)

  fetchRecentComments: ->
    new Comment(@).recent({limit: 1})

  handlefetchCommentsResponse: (response) ->
    @populateComments(response.responseJSON)

  handleCallback: (params) ->
    return params unless params? and params.success
    @handlefetchCommentsResponse(params.response) if params.type is "comment-recent"

  itemTapped: (event) ->
    comment = event.item
    element_tapped = event.originalEvent.target
    index = 0
    url = null

    if element_tapped.className is 'linky'
      event.originalEvent.stopPropagation()
      event.stopPropagation()

      linky = Linky.parse(element_tapped.href)

      if linky.type is 'image'
        AppAssistant.cloneCard(@, {name:"image",transition: Mojo.Transition.crossFade},{index: 0,images:[linky.url]})
      else if (linky.type is 'youtube_video') or (linky.type is 'web')
        @controller.serviceRequest("palm://com.palm.applicationManager", {
          method : "open",
          parameters:
            target: linky.url
            onSuccess: ->
            onFailure: ->
        })

      return

    if element_tapped.id.indexOf('image_') isnt -1
      if element_tapped.className is 'reddit_thumbnail'
        AppAssistant.cloneCard(@, {name:"image",transition: Mojo.Transition.crossFade},{index: 0,images:[Linky.parse(comment.data.url).url]})
      else
        index = element_tapped.id.match(/_(\d+)_/g)[0].replace(/_/g,'')
        index = parseInt(index)
        AppAssistant.cloneCard(@, {name:"image",transition: Mojo.Transition.crossFade},{index: index,images: StageAssistant.parseImageUrls(comment.data.body)})
      
      return

    if (element_tapped.id.indexOf('web_') isnt -1) or (element_tapped.id.indexOf('youtube_') isnt -1)
      if element_tapped.className is 'reddit_thumbnail'
        url = Linky.parse(comment.data.url).url
      else
        index = element_tapped.id.match(/_(\d+)_/g)[0].replace(/_/g,'')
        url = StageAssistant.parseUrls(comment.data.body)[index].url

      @controller.serviceRequest("palm://com.palm.applicationManager", {
        method : "open",
        parameters:
          target: url
          onSuccess: ->
          onFailure: ->
      })

      return

    @controller.popupSubmenu({
      onChoose: @handleCommentActionSelection,
      placeNear:element_tapped,
      items: [{label: $L('View Posts'), command: 'view-cmd ' + comment.data.author}]
    })
