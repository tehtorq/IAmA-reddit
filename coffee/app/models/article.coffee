class Article

  constructor: (callback) ->
    @callback = callback

  load: (data) ->
    return @ unless data?
    
    @kind = 't3'
    @data = data
    @data.url = @data.url.unescapeHTML()
    @author = @data.author
    @title = @data.title
    @url = @getUrl()
    @id = @data.id
    @name = data.name
    @can_unsave = (@data.saved) ? false : true
    @setEmbeddedURLs()
    @
  
  setEmbeddedURLs: ->
    image_url_html = ""
    urls = @urls()
    @urls = []
    @images = []
    
    hide_thumbnails = StageAssistant.cookieValue("prefs-hide-easylinks", "off")
    
    return if hide_thumbnails is "on"

    return unless urls?
    
    _.each urls, (link_url) ->
      link_icon = ""

      # check if its a link to image

      if link_url.type is 'image'
        @images.push(link_url.url);
        link_icon = './images/picture.png'
        image_url_html += '<img class="reddit_embedded_link" src="'+link_icon+'" alt="Loading" id="image_'+i+'_'+ @id + '">'
      else if link_url.type is 'youtube_video'
        link_icon = './images/youtube.png'
        image_url_html += '<img class="reddit_embedded_link" src="'+link_icon+'" alt="Loading" id="youtube_'+i+'_'+ @id + '">'
      else if link_url.type is 'web'
        link_icon = './images/web.png'
        image_url_html += '<img class="reddit_embedded_link" src="'+link_icon+'" alt="Loading" id="web_'+i+'_'+ @id + '">'

      @urls.push(link_url.url)

    @image_url_html = image_url_html

  getUrl: ->
    return null unless @data.url?
    Linky.parse(@data.url)

  urls: ->
    urls = @data.selftext.match(/https?:\/\/([-\w\.]+)+(:\d+)?(\/([\w-/_\.]*(\?\S+)?)?)?/g)

    if urls?
      _.each urls, (url) ->
        if url.indexOf(')') >= 0
          url = url.substr(0, url.indexOf(')'))

        url = Linky.parse(url)

    urls

  hasThumbnail: ->
    @data.thumbnail and (@data.thumbnail != "")

  save: (params) ->
    new Request(@callback).post('http://www.reddit.com/api/save', params, 'article-save ' + params.id)

  unsave: (params) ->
    new Request(@callback).post('http://www.reddit.com/api/unsave', params, 'article-unsave ' + params.id)

  comments: (params) ->
    url = params.url
    delete params.url
    
    new Request(@callback).get(url, params, 'article-comments')

  list: (params) ->
    url = 'http://www.reddit.com/'

    if params.sr?
      url += 'r/' + params.sr + '/'

    new Request(@callback).get(url + '.json', params, 'article-list')

  mail: (params) ->
  sms: (params) ->

Article.thumbnailFormatter = (article) ->
  return "" if article.items?

  hide_thumbnails = StageAssistant.cookieValue("prefs-hide-thumbnails", "off")

  return "" if hide_thumbnails is "on"
  
  thumbnail_url = ""

  if Article.hasThumbnail(article)
    image_link = article.data.thumbnail

    if image_link.indexOf('/static/') isnt -1
      image_link = 'http://reddit.com' + image_link

  if article.data.url?
    parsed_url = Linky.parse(article.data.url)

    if parsed_url.type is 'image'
      image_link = './images/picture.png' unless image_link?
      thumbnail_url = '<img class="reddit_thumbnail" src="'+image_link+'" alt="Loading" id="image_'+article.data.id+'">'
    else if parsed_url.type is 'youtube_video'
      image_link = './images/youtube.png' unless image_link?
      thumbnail_url = '<img class="reddit_thumbnail" src="'+image_link+'" alt="Loading" id="youtube_'+article.data.id+'">'
    else if parsed_url.type is 'web'
      if parsed_url.url.indexOf('http://www.reddit.com/') isnt -1
        image_link = './images/web.png' unless image_link?
        thumbnail_url = '<img class="reddit_thumbnail" src="'+image_link+'" alt="Loading" id="web_'+article.data.id+'">'    

  thumbnail_url

Article.hasThumbnail = (article) ->
  article.data? and article.data.thumbnail? and (article.data.thumbnail isnt "")
