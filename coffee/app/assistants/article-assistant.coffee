class ArticleAssistant extends PowerScrollBase

  constructor: (params) ->
    super
    @params = params
    @url = 'http://reddit.com'

    if params.article?
      @original_article = params.article
      @article = params.article.data      
      @url += @article.permalink
      @params.title = @article.title
    else
      @url += params.url
    
    @comments = { items : [] }

  setup: ->
    StageAssistant.setTheme(@)
    
    @controller.setupWidget("spinner",
      @attributes = {},
      @model = {spinning: true}
    ) 
      
    @spinSpinner(false)
    
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

    @viewMenuModel = {
      visible: true,
      items: [
          {items:[{},
                  { label: @params.title.substr(0, 40), command: 'top', icon: "", width: Mojo.Environment.DeviceInfo.screenWidth - 60},
                  {submenu: "sub-menu", width: 60, iconPath: 'images/options.png'},
                  {}]}
      ]
    }

    @controller.setupWidget(Mojo.Menu.viewMenu, { menuClass:'no-fade' }, @viewMenuModel)
    
    @comments.items.push({kind: 't3', data: @article}) if @article?

    @controller.setupWidget("comment-list", {
    itemTemplate : "article/comment",
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
    }, @comments)

    @controller.setupWidget("loadMoreButton", {type:Mojo.Widget.activityButton}, {label : "Loading replies", disabled: true})

    @itemTappedBind = @itemTapped.bind(@)

    Mojo.Event.listen(@controller.get("comment-list"), Mojo.Event.listTap, @itemTappedBind)

  activate: (event) ->
    super
    StageAssistant.defaultWindowOrientation(@, "free")
    
    if event?
      if event.replied is true
        item = @comments.items[0]
        @comments.items.clear()
        @comments.items.push(item)
        @jump_to_comment = event.comment_id
    
    if @comments.items.length < 2
      @controller.get('loadMoreButton').mojo.activate()
      @fetchComments({})
  
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

  deactivate: (event) ->
    super

  cleanup: (event) ->
    Request.clear_all()

    Mojo.Event.stopListening(@controller.get("comment-list"), Mojo.Event.listTap, @itemTappedBind)

  timeFormatter: (propertyValue, model) =>
    return if (model.kind isnt 't1') and (model.kind isnt 't3')
    StageAssistant.timeFormatter(model.data.created_utc)

  bodyFormatter: (propertyValue, model) =>
    if (model.kind isnt 't1') and (model.kind isnt 't3')
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
    return "" if (model.kind isnt 't1') and (model.kind isnt 't3')
    (model.data.ups - model.data.downs) + " points"

  voteFormatter: (propertyValue, model) =>
    return '' if (model.kind isnt 't1') and (model.kind isnt 't3')
    return '+1' if model.data.likes is true
    return '-1' if model.data.likes is false
    ''
  
  tagClassFormatter: (propertyValue, model) =>
    return '' if (model.kind isnt 't1') and (model.kind isnt 't3')
    if model.data.author is @article.author then 'comment_tag' else 'comment_tag_hidden'

  cssclassFormatter: (propertyValue, model) =>
    if (model.kind isnt 't1') and (model.kind isnt 't3')
      return "load_more_comment" is model.kind is 'more'
      return ""
    
    'reddit_comment'

  indentFormatter: (propertyValue, model) =>
    return '' if (model.kind isnt 't1') and (model.kind isnt 'more')
    return 4 + 6 * model.data.indent + ""

  shadowindentFormatter: (propertyValue, model) =>
    return '' if (model.kind isnt 't1') and (model.kind isnt 'more')
    return 8 + 6 * model.data.indent + ""

  thumbnailFormatter: (propertyValue, model) =>
    return '' if (model.kind isnt 't1') and (model.kind isnt 't3')
    
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
    return '' if (model.kind isnt 't1') and (model.kind isnt 't3')
    
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
      when 'sort hot','sort new','sort controversial','sort top','sort old','sort best'
        params = event.command.split(' ')
        @loadComments({sort: params[1]})

  scrollToTop: ->
    @controller.getSceneScroller().mojo.scrollTo(0,0, true)

  handleCommentActionSelection: (command) ->
    return unless command?

    params = command.split(' ')

    switch params[0]
      when 'reply-cmd'
        @controller.stageController.pushScene(
          {name: "reply",transition: Mojo.Transition.crossFade}
          {thing_id:params[1], user: params[2], modhash: @modhash, subreddit: params[4]}
        )
      when 'view-cmd'
        @controller.stageController.pushScene(
          {name:"user",transition: Mojo.Transition.crossFade},{linky:params[1]}
        )
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
      @controller.get('loading').show()
    else
      @controller.get('loading').hide()

  populateComments: (object) ->
    unless @article?
      @article = object[0].data.children[0].data
      @comments.items.push({kind: 't3', data: object[0].data.children[0].data})
      @controller.modelChanged(@comments)
    
    @populateReplies(object[1].data.children, 0)
    
    @controller.get('comment-list').mojo.setLength(@comments.items.length)
    @controller.get('comment-list').mojo.noticeUpdatedItems(0, @comments.items)

  populateReplies: (replies, indent) ->
    _.each replies, (child) =>
      if child.kind isnt 'more'
        child.data.indent = indent
        @comments.items.push(child)
      
        data = child.data
      
        if (data.replies?) and (data.replies isnt "")
          if data.replies.data? and data.replies.data.children?
            @populateReplies(data.replies.data.children, indent + 1)

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
            text: 'http://reddit.com' + @article.data.permalink,
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
            messageText: @article.title + "\n\n" + 'http://reddit.com' + @article.data.permalink
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

  itemTapped: (event) ->
    comment = event.item
    element_tapped = event.originalEvent.target
    index = 0
    url = null
    
    # handle links & spoilers
    
    if element_tapped.tagName is 'A'
      if (element_tapped.href is 'file:///s') or (element_tapped.href is 'file:///b') or (element_tapped.href is 'file:///?')
        element_tapped.update(element_tapped.title)
      else
        if element_tapped.title? and (element_tapped.title.length > 0)
          @controller.showAlertDialog({   
            #title: "Title",
            message: element_tapped.title,
            choices:[    
              {label: "Ok", value:"", type:'dismiss'}    
            ]
          })
      
      return
    
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

    if element_tapped.className is 'linky'
      #event.originalEvent.stopPropagation()
      #event.stopPropagation()

      linky = Linky.parse(element_tapped.href)

      if linky.type is 'image'
        AppAssistant.cloneCard(@, {name:"image",transition: Mojo.Transition.crossFade},{index: 0,images:[linky.url]})
      else if ((linky.type is 'youtube_video') or (linky.type is 'web'))
        @controller.serviceRequest("palm://com.palm.applicationManager", {
          method : "open",
          parameters:
            target: linky.url,
            onSuccess: ->
            onFailure: ->
        })

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
                 onChoose: @handleCommentActionSelection.bind(@),
                 placeNear:element_tapped,
                 items: [                         
                   {label: $L('Upvote'), command: upvote_action + ' ' + comment.data.name + ' ' + comment.data.subreddit, secondaryIcon: upvote_icon},
                   {label: $L('Downvote'), command: downvote_action + ' ' + comment.data.name + ' ' + comment.data.subreddit, secondaryIcon: downvote_icon},
                   {label: $L('Reply'), command: 'reply-cmd ' + comment.data.name + ' ' + comment.data.author + ' ' + @url + ' ' + comment.data.subreddit},
                   {label: $L(comment.data.author), command: 'view-cmd ' + comment.data.author}]
                 })
    else
      @controller.popupSubmenu({
                 onChoose: @handleCommentActionSelection.bind(@),
                 placeNear:element_tapped,
                 items: [
                   {label: $L(comment.data.author), command: 'view-cmd ' + comment.data.author}]
                 })
