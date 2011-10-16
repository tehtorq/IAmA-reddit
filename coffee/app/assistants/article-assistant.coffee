class ArticleAssistant extends PowerScrollBase

  constructor: (params) ->
    super
    @allow_back = params.allow_back
    @cardname = "card" + Math.floor(Math.random()*10000)
    @params = params
    @url = 'http://reddit.com'

    if params.article?
      @original_article = params.article
      @article = params.article.data      
      @url += @article.permalink
      @params.title = @article.title
    else if params.url?
      @url = params.url
    
    @comments = { items : [] }

  setup: ->
    StageAssistant.setTheme(@)
    
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
                                {label:$L("sms"), command:$L("sms-cmd")}]},
      {label:$L("related"), command:$L("related")},
      {label:$L("other discussions"), command:$L("duplicates")},
      {label:$L("save"), command:$L("save-cmd")},
      ]})
      
    viewmenu_width = _.min([@controller.window.innerWidth, @controller.window.innerHeight])
    
    if Mojo.Environment.DeviceInfo.keyboardAvailable or not @allow_back
      @viewMenuModel = {
        visible: true,
        items: [
            {items:[{},
                    { label: @params.title.substr(0, 40), command: 'top', icon: "", width: viewmenu_width - 60},
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
                    { label: @params.title.substr(0, 40), command: 'top', icon: "", width: viewmenu_width - 140},
                    {submenu: "sub-menu", width: 60, iconPath: 'images/options.png'},
                    {}]}
        ]
      }
    

    @controller.setupWidget(Mojo.Menu.viewMenu, { menuClass:'no-fade' }, @viewMenuModel)
    
    @comments.items.push({kind: 't3', data: @article}) if @article?

    @controller.setupWidget("comment-list", {
    itemTemplate : "article/comment"
    #renderLimit: 501 # scroll to top and reveal next OP is perfect - but hiding/showing comments is slow
    formatters:
      time: @timeFormatter
      body: @bodyFormatter
      score: @scoreFormatter
      vote: @voteFormatter
      easylinks: @easylinksFormatter
      cssclass: @cssclassFormatter
      tagClass: @tagClassFormatter
      indent: @indentFormatter
      thumbnail: @thumbnailFormatter
      shadowindent: @shadowindentFormatter
      hidingComments: @hidingCommentsFormatter
    }, @comments)

    @controller.setupWidget("loadMoreButton", {type:Mojo.Widget.activityButton}, {label : "Loading replies", disabled: true})

    @controller.get("comment-list").observe("click", (event) =>
      element = event.findElement("a")
      
      if element?
        event.preventDefault()
        @handleClickedLink(element)
    )

  activate: (event) ->
    super
    Mojo.Event.listen(@controller.get("comment-list"), Mojo.Event.listTap, @itemTapped)
    Mojo.Event.listen(@controller.get("comment-list"), Mojo.Event.hold, @itemHold)

    StageAssistant.defaultWindowOrientation(@, "free")
    @spinSpinner(false)
    
    if event? and event.replied is true
      item = @comments.items[0]
      @comments.items.clear()
      @comments.items.push(item)
      @jump_to_comment = event.comment_id
    
    if @comments.items.length < 2
      @controller.get('loadMoreButton').mojo.activate()
      @fetchComments({})

  deactivate: (event) ->
    super
    Mojo.Event.stopListening(@controller.get("comment-list"), Mojo.Event.listTap, @itemTapped)
    Mojo.Event.stopListening(@controller.get("comment-list"), Mojo.Event.hold, @itemHold)

  cleanup: (event) ->
    Request.clear_all(@cardname)
    
  findArticleIndex: (article_name) ->
    length = @comments.items.length
    items = @comments.items

    index = -1

    _.each @comments.items, (item, i) ->
      index = i if item.data.name is article_name

    index

  loadComments: (params) ->
    item = @comments.items[0]
    @comments.items.clear()
    @comments.items.push(item)

    @controller.modelChanged(@comments)
    @controller.get('loadMoreButton').mojo.activate()
    @controller.get('loadMoreButton').show()
    @fetchComments(params)

  timeFormatter: (propertyValue, model) =>
    return if model.kind not in ['t1','t3']
    StageAssistant.timeFormatter(model.data.created_utc)

  bodyFormatter: (propertyValue, model) =>
    if model.kind not in ['t1','t3']
      return "load more comments" if model.kind is 'more'
      return ""
    
    content = ""

    if model.data.selftext_html
      content = model.data.selftext_html
    else
      #content = model.data.body
      content = model.data.body_html

    return "" unless content
    
    content = content.unescapeHTML()

    #ontent = content.replace('<a ', '<a class="linky" ')
    #content = content.replace(/\[([^\]]*)\]\(([^\)]+)\)/gi, "<a class='linky' onClick=\"return false\" href='$2'>$1</a>")
    content

  scoreFormatter: (propertyValue, model) =>
    return "" if model.kind not in ['t1','t3']
    (model.data.ups - model.data.downs) + " points"

  voteFormatter: (propertyValue, model) =>
    return '' if model.kind not in ['t1','t3']
    return '+1' if model.data.likes is true
    return '-1' if model.data.likes is false
    ''
  
  tagClassFormatter: (propertyValue, model) =>
    return '' if model.kind not in ['t1','t3']
    if model.data.author is @article.author then 'comment_tag' else 'comment_tag_hidden'

  cssclassFormatter: (propertyValue, model) =>
    if model.kind not in ['t1','t3']
      return "load_more_comment" is model.kind is 'more'
      return ""
    
    'reddit_comment'

  indentFormatter: (propertyValue, model) =>
    return '' if model.kind not in ['t1','more']
    4 + 6 * model.data.indent + ""

  shadowindentFormatter: (propertyValue, model) =>
    return '' if model.kind not in ['t1','more']
    8 + 6 * model.data.indent + ""
    
  hidingCommentsFormatter: (propertyValue, model) =>
    return "hiding #{model.hiding_comments} comment" if model?.hiding_comments is 1
    return "hiding #{model.hiding_comments} comments" if model?.hiding_comments > 0
    ''

  thumbnailFormatter: (propertyValue, model) =>
    return '' if model.kind not in ['t1','t3']
    
    image_link = null

    if (model.data.thumbnail?) and (model.data.thumbnail isnt "")
      image_link = model.data.thumbnail

      if image_link.indexOf('/static/') isnt -1
        image_link = 'http://reddit.com' + image_link

    if model.data.url?
      linky = Linky.parse(model.data.url)

      switch linky.type
        when 'image'
          image_link = './images/picture.png' unless image_link?
          return '<img class="reddit_thumbnail" src="'+image_link+'" alt="Loading" id="image_'+model.data.id+'">'
        when 'youtube_video'
          image_link = './images/youtube.png' unless image_link?
          return '<img class="reddit_thumbnail" src="'+image_link+'" alt="Loading" id="youtube_'+model.data.id+'">'
        when 'web'
          if linky.url.indexOf('http://www.reddit.com/') is -1
            image_link = './images/web.png' unless image_link?
            return '<img class="reddit_thumbnail" src="'+image_link+'" alt="Loading" id="web_'+model.data.id+'">'

    ""

  easylinksFormatter: (propertyValue, model) =>
    return '' if model.kind not in ['t1','t3']
    
    hide_thumbnails = StageAssistant.cookieValue("prefs-hide-easylinks", "off")
    
    return "" if hide_thumbnails is "on"
    
    id = model.data.id
    urls = StageAssistant.parseUrls(model.data.body)

    return "" unless urls?

    #urls = urls.unique() // FIX - unique doesnt work

    image_url_html = ""
    imagecount = 0
    
    _.each urls, (url) ->
      image_link = ""

      # check if its a link to image

      if url.type is 'image'
        image_link = './images/picture.png'
        image_url_html += '<img class="reddit_embedded_link" src="'+image_link+'" alt="Loading" id="image_'+imagecount+'_'+ id + '">'
        imagecount++
      else if url.type is 'youtube_video'
        image_link = './images/youtube.png'
        image_url_html += '<img class="reddit_embedded_link" src="'+image_link+'" alt="Loading" id="youtube_'+i+'_'+ id + '">'
      else if url.type is 'web'
        image_link = './images/web.png'
        image_url_html += '<img class="reddit_embedded_link" src="'+image_link+'" alt="Loading" id="web_'+i+'_'+ id + '">'

    image_url_html

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
      when 'sms-cmd'
        @smsArticle()
      when 'show 200'
        @loadComments({limit: 200})
      when 'show 500'
        @loadComments({limit: 500})
      when 'related','duplicates'
        url = @url.replace(/\/comments\//, '/'+event.command+'/').replace('http://www.reddit.com/', '').replace('http://reddit.com/', '')          
        AppAssistant.cloneCard(@, {name:"frontpage"},{permalink:url})          
      when 'sort hot','sort new','sort controversial','sort top','sort old','sort confidence'
        params = event.command.split(' ')
        @loadComments({sort: params[1]})

  scrollToTop: ->
    @controller.getSceneScroller().mojo.scrollTo(0,0, true)
    
  updateHeading: (text) ->
    text = '' unless text?
    text = text.substr(0, 40)

    if Mojo.Environment.DeviceInfo.keyboardAvailable or not @allow_back
      @viewMenuModel.items[0].items[1].label = text
    else
      @viewMenuModel.items[0].items[2].label = text
      
    @controller.modelChanged(@viewMenuModel)

  handleCommentActionSelection: (command) ->
    return unless command?

    params = command.split(' ')

    switch params[0]
      when 'reply-cmd'
        @controller.stageController.pushScene(
          {name: "reply",transition: Mojo.Transition.crossFade}
          {thing_id:params[1], user: params[2], modhash: @modhash, subreddit: params[4],allow_back:true}
        )
      when 'view-cmd'
        @controller.stageController.pushScene({name:"user"}, {user:params[1]})
      when 'message-cmd'
        @controller.stageController.pushScene({name:"compose-message"}, {to:params[1]})
      when 'upvote-cmd'
        @spinSpinner(true)
        @voteOnComment('1', params[1], params[2])
      when 'downvote-cmd'
        @spinSpinner(true)
        @voteOnComment('-1', params[1], params[2])
      when 'reset-vote-cmd'
        @spinSpinner(true)
        @voteOnComment('0', params[1], params[2])
  
  spinSpinner: (bool) ->
    if bool
      @controller.get('spinner').mojo.start()
      @controller.get('loading').show()
    else
      @controller.get('loading').hide()
      @controller.get('spinner').mojo.stop()

  populateComments: (object) ->
    unless @article?
      @article = object[0].data.children[0].data
      @updateHeading(@article.title)
      @comments.items.push({kind: 't3', data: @article})
      @controller.modelChanged(@comments)
    
    @populateReplies(object[1].data.children, 0, @comments)
    
    @controller.modelChanged(@comments)
    
    #@controller.get('comment-list').mojo.setLengthAndInvalidate(@comments.items.length)

  populateReplies: (replies, indent, array) ->
    _.each replies, (child) =>
      if child.kind isnt 'more'
        child.data.indent = indent
        array.items.push(child)
      
        data = child.data
      
        if data.replies?.data?.children?
          unless child?.hiding_comments > 0 
            @populateReplies(data.replies.data.children, indent + 1, array)

  fetchComments: (params) ->
    params.url = @url + '.json'    
    new Article(@).comments(params)
    
  hideChildren: (index) ->
    return if index is @comments.items.length - 1
    first_candidate = index + 1
    
    indent = parseInt(@comments.items[index].data.indent)
    check = true
    checked_until = index
    remove = false
    
    while check is true and checked_until < @comments.items.length - 1
      if (@comments.items[checked_until+1].kind isnt 't1') or (parseInt(@comments.items[checked_until+1].data.indent) > indent)
        remove = true
        checked_until++
      else
        check = false
    
    if remove is true
      @comments.items[index].hiding_comments = checked_until - index
      @comments.items.splice(first_candidate, checked_until - index)
      @controller.get('comment-list').mojo.invalidateItems(index,1)
      @controller.get('comment-list').mojo.noticeRemovedItems(first_candidate, checked_until - index)
      
  showChildren: (index) ->
    comment = @comments.items[index]
    array = {items: []}
    @populateReplies(comment.data.replies.data.children, comment.data.indent + 1, array)
    
    comment.hiding_comments = 0
    
    if array.items.length > 0
      items = array.items
      @comments.items.splice(index+1,0, items...)
      @controller.get('comment-list').mojo.invalidateItems(index,1)
      @controller.get('comment-list').mojo.noticeAddedItems(index+1, items)
  
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

    if params.type[0] is "comment-upvote"
      index = @findArticleIndex(params.type[1])
      
      if index > -1
        if @comments.items[index].data.likes is false
          @comments.items[index].data.downs--

        @comments.items[index].data.likes = true
        @comments.items[index].data.ups++
        @controller.get('comment-list').mojo.noticeUpdatedItems(index, [@comments.items[index]])
      
      new Banner("Upvoted!").send()
    else if params.type[0] is "comment-downvote"
      index = @findArticleIndex(params.type[1])
      
      if index > -1
        if @comments.items[index].data.likes is true
          @comments.items[index].data.ups--

        @comments.items[index].data.likes = false
        @comments.items[index].data.downs++
        @controller.get('comment-list').mojo.noticeUpdatedItems(index, [@comments.items[index]])
      
      new Banner("Downvoted!").send()
    else if params.type[0] is "comment-vote-reset"
      index = @findArticleIndex(params.type[1])
      
      if index > -1
        if @comments.items[index].data.likes is true
          @comments.items[index].data.ups--
        else
          @comments.items[index].data.downs--

        @comments.items[index].data.likes = null      
        @controller.get('comment-list').mojo.noticeUpdatedItems(index, [@comments.items[index]])
      
      new Banner("Vote reset!").send()
    else if params.type[0] is "article-save"
      new Banner("Saved!").send()
    else if params.type[0] is "article-comments"
      @handlefetchCommentsResponse(params.response)

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
    
  itemTapped: (event) =>
    comment = event.item
    element_tapped = event.originalEvent.target
    index = 0
    url = null
    
    # click on OP tag to jump to next comment by OP
    
    if element_tapped.className is 'comment_tag'
      index = event.index
      author = comment.data.author
      
      while true
        index++
        index = 0 if index is @comments.items.length
        
        if @comments.items[index].data.author and (@comments.items[index].data.author is author)
          @controller.get('comment-list').mojo.revealItem(index, true)
          return
      
      return

    if element_tapped.id.indexOf('image_') isnt -1
      if element_tapped.className is 'reddit_thumbnail'
        StageAssistant.cloneImageCard(@, @original_article)
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
        
        urls = StageAssistant.parseUrls(comment.data.body)
        url = StageAssistant.parseUrls(comment.data.body)[index].url

      @controller.serviceRequest("palm://com.palm.applicationManager", {
        method: "open",
        parameters:
          target: url
          onSuccess: ->
          onFailure: ->
        })

      return
    
    if @isLoggedIn()  
      upvote_icon = if comment.data.likes is true then 'selected_upvote_icon' else 'upvote_icon'
      downvote_icon =  if comment.data.likes is false then 'selected_downvote_icon' else 'downvote_icon'
      upvote_action = if comment.data.likes is true then 'reset-vote-cmd' else 'upvote-cmd'
      downvote_action = if comment.data.likes is false then 'reset-vote-cmd' else 'downvote-cmd'

      @controller.popupSubmenu({
                 onChoose: @handleCommentActionSelection,
                 placeNear:element_tapped,
                 items: [                         
                   {label: $L('Upvote'), command: upvote_action + ' ' + comment.data.name + ' ' + comment.data.subreddit, secondaryIcon: upvote_icon},
                   {label: $L('Downvote'), command: downvote_action + ' ' + comment.data.name + ' ' + comment.data.subreddit, secondaryIcon: downvote_icon},
                   {label: $L('Reply'), command: 'reply-cmd ' + comment.data.name + ' ' + comment.data.author + ' ' + @url + ' ' + comment.data.subreddit},
                   {label: $L(comment.data.author), command: 'view-cmd ' + comment.data.author}
                   {label: $L("Message"), command: 'message-cmd ' + comment.data.author}]
                 })
    else
      @controller.popupSubmenu({
                 onChoose: @handleCommentActionSelection,
                 placeNear:element_tapped,
                 items: [
                   {label: $L(comment.data.author), command: 'view-cmd ' + comment.data.author}]
                 })

  itemHold: (event) =>
    event.preventDefault()
    thing = event.srcElement.up('.thing-container')    
    id = thing.id
    
    index = @findArticleIndex(id)
    
    comment = _.first _.select @comments.items, (item) => item.data.name is id
    
    if comment.hiding_comments > 0
      return @showChildren(index)
    else  
      return @hideChildren(index)
  
  handleClickedLink: (element) ->
    
    Mojo.Log.info("#{element.href} clicked")
    
    # handle gameofthrones links
    
    return element.update(element.title) if element.href in ['file:///s','file:///b','file:///?']
    
    # handle taps on ragefaces
    
    if element.title? and (element.title.length > 0)
      @controller.showAlertDialog({   
        #title: "Title",
        message: element.title,
        choices:[    
          {label: "Ok", value:"", type:'dismiss'}    
        ]
      })
      
      return
      
    # parse type of url
    
    if element.href.indexOf('http://www.reddit.com/') is 0
      if element.href.indexOf('/comments/') isnt -1
        return AppAssistant.cloneCard(@, {name:"article",transition: Mojo.Transition.crossFade},{url:element.href,title: "Link"})
      else if element.href.indexOf('/user/') isnt -1
        user = element.href.replace('http://www.reddit.com/user/', '')
        return AppAssistant.cloneCard(@, {name:"user",transition: Mojo.Transition.crossFade},{user:user})
      else
        return AppAssistant.cloneCard(@, {name:"frontpage",transition: Mojo.Transition.crossFade},{url:element.href})
      
    linky = Linky.parse(element.href)
    
    if linky.type is 'image'
      if linky.url.endsWith('.gif')
        AppAssistant.cloneCard(@, {name:"gif",transition: Mojo.Transition.crossFade},{index: 0,images:[linky.url]})
      else
        AppAssistant.cloneCard(@, {name:"image",transition: Mojo.Transition.crossFade},{index: 0,images:[linky.url]})
    else if (linky.type is 'youtube_video') or (linky.type is 'web')
      @controller.serviceRequest("palm://com.palm.applicationManager", {
        method : "open",
        parameters:
          target: linky.url,
          onSuccess: ->
          onFailure: ->
      })
