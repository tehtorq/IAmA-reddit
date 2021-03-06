class CommentList
  
  constructor: (article, assistant) ->
    @assistant = assistant
    @controller = assistant.controller
    
    @article = article.data if article?
    @comments = { items : [] }
    @comments.items.push({kind: 't3', data: @article}) if @article?
    @setup()
    
  setup: ->
    @controller.setupWidget("comment-list", {
    itemTemplate : "article/comment"
    #renderLimit: 501 # scroll to top and reveal next OP is perfect - but hiding/showing comments is slow
    formatters:
      time: @timeFormatter
      body: @bodyFormatter
      score: @scoreFormatter
      vote: @voteFormatter
      cssclass: @cssclassFormatter
      tagClass: @tagClassFormatter
      indent: @indentFormatter
      thumbnail: @thumbnailFormatter
      shadowindent: @shadowindentFormatter
      hidingComments: @hidingCommentsFormatter
    }, @comments)

    @controller.get("comment-list").observe("click", (event) =>
      event.preventDefault() if event.findElement("a")?
    )
    
  setArticle: (article) ->
    @article = article.data
  
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
        
      if image_link in ['self','nsfw','default']
        image_link = "./images/#{image_link}-thumbnail.png"

    if model.data.url?
      linky = Linky.parse(model.data.url)
      
      switch linky.type
        when 'image'
          image_link = './images/picture.png' unless image_link?
          return '<img class="reddit_thumbnail" src="'+image_link+'" id="image_'+model.data.id+'">'
        when 'youtube_video'
          image_link = './images/youtube.png' unless image_link?
          return '<img class="reddit_thumbnail" src="'+image_link+'" id="youtube_'+model.data.id+'">'
        when 'web'
          image_link = './images/web.png' unless image_link?
          return '<img class="reddit_thumbnail" src="'+image_link+'" id="web_'+model.data.id+'">'

    ""
    
  findArticleIndex: (article_name) ->
    length = @comments.items.length
    items = @comments.items

    index = -1

    _.each @comments.items, (item, i) ->
      index = i if item.data.name is article_name

    index
  
  populateReplies: (replies, indent, array) ->
    _.each replies, (child) =>
      if child.kind isnt 'more'

        child.data.indent = indent
        child.easyLinksHTML = StageAssistant.easylinksFormatter(child)

        array.items.push(child)

        data = child.data

        if data.replies?.data?.children?
          unless child?.hiding_comments > 0 
            @populateReplies(data.replies.data.children, indent + 1, array)
  
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
      
  itemTapped: (event) =>

    # if a link was tapped then...
    element = event.originalEvent.findElement("a")

    if element?
      event.originalEvent.preventDefault()
      event.preventDefault()
      @handleClickedLink(element)
      return

    # else handle list item tap
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
        StageAssistant.cloneImageCard(@, {kind: 't3', data: @article})
      else
        index = element_tapped.id.match(/_(\d+)_/g)[0].replace(/_/g,'')
        index = parseInt(index)
        AppAssistant.cloneCard(@controller, {name:"image",transition: Mojo.Transition.crossFade},{index: index,images: StageAssistant.parseImageUrls(comment.data.body)})

      return

    if (element_tapped.id.indexOf('web_') isnt -1) or (element_tapped.id.indexOf('youtube_') isnt -1)
      if element_tapped.className is 'reddit_thumbnail'
        url = Linky.parse(comment.data.url).url
      else
        index = element_tapped.id.match(/_(\d+)_/g)[0].replace(/_/g,'')

        urls = StageAssistant.parseUrls(comment.data.body)
        url = StageAssistant.parseUrls(comment.data.body)[index].url

      AppAssistant.open(url)
      return

    if @assistant.isLoggedIn()  
      upvote_icon = if comment.data.likes is true then 'selected_upvote_icon' else 'upvote_icon'
      downvote_icon =  if comment.data.likes is false then 'selected_downvote_icon' else 'downvote_icon'
      upvote_action = if comment.data.likes is true then 'reset-vote-cmd' else 'upvote-cmd'
      downvote_action = if comment.data.likes is false then 'reset-vote-cmd' else 'downvote-cmd'

      @controller.popupSubmenu({
                 onChoose: @handleCommentActionSelection,
                 #placeNear:element_tapped,
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
                 #placeNear:element_tapped,
                 items: [
                   {label: $L(comment.data.author), command: 'view-cmd ' + comment.data.author}]
                 })

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
        return AppAssistant.cloneCard(@controller, {name:"article",transition: Mojo.Transition.crossFade},{url:element.href,title: "Link"})
      else if element.href.indexOf('/user/') isnt -1
        user = element.href.replace('http://www.reddit.com/user/', '')
        return AppAssistant.cloneCard(@controller, {name:"user",transition: Mojo.Transition.crossFade},{user:user})
      else
        return AppAssistant.openFrontpage("clone", {url:element.href}, @controller)

    linky = Linky.parse(element.href)

    if linky.type is 'image'
      if linky.url.endsWith('.gif')
        AppAssistant.cloneCard(@controller, {name:"gif",transition: Mojo.Transition.crossFade},{index: 0,images:[linky.url]})
      else
        AppAssistant.cloneCard(@controller, {name:"image",transition: Mojo.Transition.crossFade},{index: 0,images:[linky.url]})
    else if (linky.type is 'youtube_video') or (linky.type is 'web')
      AppAssistant.open(linky.url)
      
  handleCommentActionSelection: (command) =>
    return unless command?

    params = command.split(' ')

    switch params[0]
      when 'reply-cmd'
        @controller.stageController.pushScene(
          {name: "reply",transition: Mojo.Transition.crossFade}
          {thing_id:params[1], user: params[2], modhash: @assistant.getModHash(), subreddit: params[4]}
        )
      when 'view-cmd'
        @controller.stageController.pushScene({name:"user"}, {user:params[1]})
      when 'message-cmd'
        @controller.stageController.pushScene({name:"compose-message"}, {to:params[1]})
      when 'upvote-cmd'
        @assistant.spinSpinner(true)
        @voteOnComment('1', params[1], params[2])
      when 'downvote-cmd'
        @assistant.spinSpinner(true)
        @voteOnComment('-1', params[1], params[2])
      when 'reset-vote-cmd'
        @assistant.spinSpinner(true)
        @voteOnComment('0', params[1], params[2])      
  
  voteOnComment: (dir, comment_name, subreddit) ->
    params =
      dir: dir
      id: comment_name
      uh: @assistant.getModHash()
      r: subreddit

    if dir is '1'
      new Comment(@).upvote(params)
    else if dir is '-1'
      new Comment(@).downvote(params)
    else
      new Comment(@).reset_vote(params)

  handleCallback: (params) ->
    return params unless params? and params.success

    @assistant.spinSpinner(false)

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

      Banner.send("Upvoted!")
    else if params.type[0] is "comment-downvote"
      index = @findArticleIndex(params.type[1])

      if index > -1
        if @comments.items[index].data.likes is true
          @comments.items[index].data.ups--

        @comments.items[index].data.likes = false
        @comments.items[index].data.downs++
        @controller.get('comment-list').mojo.noticeUpdatedItems(index, [@comments.items[index]])

      Banner.send("Downvoted!")
    else if params.type[0] is "comment-vote-reset"
      index = @findArticleIndex(params.type[1])

      if index > -1
        if @comments.items[index].data.likes is true
          @comments.items[index].data.ups--
        else
          @comments.items[index].data.downs--

        @comments.items[index].data.likes = null      
        @controller.get('comment-list').mojo.noticeUpdatedItems(index, [@comments.items[index]])

      Banner.send("Vote reset!")
