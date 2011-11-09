class CommentList
  
  constructor: (article) ->
    @article = article.data if article?
    
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
  
  
  