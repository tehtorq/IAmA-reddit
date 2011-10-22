class DockAssistant extends BaseAssistant

  constructor: (params) ->
    super
    @image_array = []
    @article_array = []
    @current_index = 0
    
    @fetching_images = false
    @last_article_id = null
    @sr = 'pics'

  setup: ->
    super
    @controller.enableFullScreenMode(true)
    
    @controller.setupWidget "spinner", @attributes = {}, @model = {spinning: true}
    
    @controller.setupWidget("ImageId",
      @attributes = {
        noExtractFS: true
      },
      @model = {
        onLeftFunction: =>
          @updateUrls(-1)
        onRightFunction: =>
          @updateUrls(1)
      }
    )

  activate: (event) ->
    super
    
    StageAssistant.defaultWindowOrientation(@, "free")
    @timerID = @controller.window.setInterval(@tick.bind(@),15000)
  
  ready: ->
    @controller.get('ImageId').mojo.manualSize(@controller.window.innerWidth,@controller.window.innerHeight)

  deactivate: (event) ->
    @controller.enableFullScreenMode(false)
    @controller.window.clearInterval(@timerID)

  cleanup: (event) ->
    super
  
  tick: ->
    @updateUrls(1)
    
    if (@image_array.length - @current_index) < 10
      @loadImages()

  orientationChanged: (orientation) ->
    @controller.stageController.setWindowOrientation(orientation)

  handleLoadArticlesResponse: (response) ->
    children = response.responseJSON.data.children
    
    _.each children, (child) =>
      d = child.data
      reddit_article = new Article().load(d)
      @last_article_id = reddit_article.data.name

      url = reddit_article.data.url

      if ((url.indexOf('.jpg') >= 0) or (url.indexOf('.jpeg') >= 0) or (url.indexOf('.png') >= 0) or (url.indexOf('.gif') >= 0) or (url.indexOf('.bmp') >= 0))
        @article_array.push({data: reddit_article.data, kind: 't3'})
        @image_array.push(url)
    
    @spinSpinner(false)
    @fetching_images = false
  
  clearImages: ->
    @controller.getSceneScroller().mojo.scrollTo(0,0, true)
    @controller.get('gallery').update('')
    @last_article_id = null
    @thumbs.clear()

  loadImages: =>
    return if @fetching_images
    
    @fetching_images = true
    @spinSpinner(true)

    parameters = {}
    parameters.limit = 100
    parameters.after = @last_article_id if @last_article_id?
    parameters.sr = @sr if @sr?

    new Article(@).list(parameters)
  
  urlForIndex: (index) ->
    if index < 0
      return null
      index += @image_array.length
    else if index >= @image_array.length
      return null
      index -= @image_array.length

    @image_array[index]

  updateUrls: (delta) ->
    new_index = @current_index + delta

    return if (new_index < 0) or (new_index >= @image_array.length)

    @current_index = new_index

    image = @controller.get('ImageId')

    if (@current_index > -1) and (@current_index < @image_array.length)
      image.mojo.centerUrlProvided(@urlForIndex(@current_index))

    if (@current_index > 0) and (@current_index < @image_array.length)
      image.mojo.leftUrlProvided(@urlForIndex(@current_index - 1))

    if (@current_index > -1) and (@current_index < (@image_array.length - 1))
      image.mojo.rightUrlProvided(@urlForIndex(@current_index + 1))
  
  handleCallback: (params) ->
    return params unless params? and params.success
    @handleLoadArticlesResponse(params.response) if params.type is "article-list"
  
  handleWindowResize: (event) ->
    @controller.get('ImageId').mojo.manualSize(@controller.window.innerWidth, @controller.window.innerHeight)
