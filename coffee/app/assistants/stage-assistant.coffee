class StageAssistant
  
  setup: (arg) ->
  
  checkConnection: (callback, fallback) ->
    request = new Mojo.Service.Request('palm://com.palm.connectionmanager', {
      'method': 'getstatus'
      'parameters': {}
      'onSuccess': callback
      'onFailure': fallback
    })

  @cookieValue: (cookieName, default_value) ->
    cookie = new Mojo.Model.Cookie(cookieName)

    if cookie?
      value = cookie.get()
      return default_value unless value?
      return value

    default_value

  @cloneImageCard: (assistant, article) ->
    lowercase_subreddit = article.data.subreddit.toLowerCase()
    article.url = Linky.parse(article.data.url) if article.kind?
  
    if lowercase_subreddit in ['gif','gifs','nsfw_gif','nsfw_gifs'] or article.url.url.endsWith('.gif')
      AppAssistant.cloneCard(assistant, {name:"gif"},{index:0,images:[article.url.url], articles: [article]})
    else
      AppAssistant.cloneCard(assistant, {name:"image"},{index:0,images:[article.url.url], articles: [article]})

  @stages = []
  @current_theme = null

  @switchTheme = (theme) ->
    appController = Mojo.Controller.getAppController()
    
    _.each @stages, (stage) ->
      controller = appController.getStageController(stage)
    
      if controller?
        controller.unloadStylesheet(StageAssistant.current_theme)
        controller.loadStylesheet(theme)
  
    StageAssistant.current_theme = theme

  @setTheme: (assistant) ->
    unless StageAssistant.current_theme?
      StageAssistant.current_theme = StageAssistant.cookieValue("prefs-theme", "stylesheets/themes/dark.css")
  
    Mojo.loadStylesheet(assistant.controller.document, StageAssistant.current_theme)

  @parseUrls: (text) ->
    return null unless text? and (text.indexOf('http') > -1)

    #urls = @data.selftext.match(/https?:\/\/([-\w\.]+)+(:\d+)?(\/([\w-/_\.]*(\?\S+)?)?)?/g)
    #urls = text.match(/([^\[])*https?:\/\/([-\w\.]+)+(:\d+)?(\/([\w-/_\.]*(\?\S+)?)?)?/g)
    urls = text.match(/https?:\/\/([-\w\.]+)+(:\d+)?(\/([\w-/_\.]*(\?\S+)?)?)?/g)

    if urls?
      urls = _.map urls, (url) ->
        url = url.substr(0, url.indexOf(')')) if url.indexOf(')') >= 0
        url = Linky.parse(url.substr(url.indexOf('http'), url.length))

    urls

  @parseImageUrls: (text) ->
    urls = @parseUrls(text)

    return null unless urls?
    
    _.compact _.map urls, (url) -> urls.url if urls.type is 'image'

  @timeFormatter = (time) ->
    newDate = new Date()
    lapsed = newDate.getTime() / 1000 - time
    units = Math.floor(lapsed / 60)

    if units < 60
      return if units is 1 then units.toString() + ' minute ago' else units.toString() + ' minutes ago'

    units = Math.floor(units / 60)

    if units < 24
      return if units is 1 then units.toString() + ' hour ago' else units.toString() + ' hours ago'

    units = Math.floor(units / 24)

    return if units is 1 then units.toString() + ' day ago' else units.toString() + ' days ago'

  @scoreFormatter: (model) ->
    "#{model.data.ups - model.data.downs} points"
    
  @easylinksFormatter: (model) =>
    return '' if model.kind not in ['t1','t3']
    return unless StageAssistant.cookieValue("prefs-show-easylinks", "off") is "on"

    id = model.data.id
    urls = StageAssistant.parseUrls(model.data.body)
    return "" unless urls?

    #urls = urls.unique() // FIX - unique doesnt work

    image_url_html = ""

    _.each urls, (url) ->
      image_url_html += "<a class='reddit_embedded_link' href='#{url.url}'>"
      image_url_html += '<img class="reddit_embedded_link" src="./images/picture.png">' if url.type is 'image'
      image_url_html += '<img class="reddit_embedded_link" src="./images/youtube.png">' if url.type is 'youtube_video'
      image_url_html += '<img class="reddit_embedded_link" src="./images/web.png">' if url.type is 'web'
      image_url_html += "</a>"
    
    image_url_html

  @defaultWindowOrientation: (assistant, orientation) ->
    value = StageAssistant.cookieValue("prefs-lock-orientation", "off")
  
    if value is "on"
      assistant.controller.stageController.setWindowOrientation("up")
    else
      assistant.controller.stageController.setWindowOrientation(orientation)
