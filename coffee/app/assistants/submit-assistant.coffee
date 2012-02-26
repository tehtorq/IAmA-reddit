class SubmitAssistant extends BaseAssistant

  constructor: (params = {}) ->
    super
    
    @titleModel = { value : '' }
    @urlModel = { value : '' }
    @textModel = { value : '' }
    @redditModel = { value : params.sr }

  setup: ->
    super
    
    @controller.setupWidget "submit-title", { 
      focusMode: Mojo.Widget.focusSelectMode
      textCase: Mojo.Widget.steModeLowerCase, maxLength : 30
      hintText: 'Title'
      }
      @titleModel
      
    @controller.setupWidget "submit-url", { 
      focusMode: Mojo.Widget.focusSelectMode
      textCase: Mojo.Widget.steModeLowerCase, maxLength : 30
      hintText: 'Url'
      }
      @urlModel

    @controller.setupWidget "submit-text", { 
      focusMode: Mojo.Widget.focusSelectMode
      textCase: Mojo.Widget.steModeLowerCase
      hintText: 'Text'
      multiline: true
      }
      @textModel
      
    @controller.setupWidget "submit-reddit", { 
      focusMode: Mojo.Widget.focusSelectMode
      textCase: Mojo.Widget.steModeLowerCase, maxLength : 30
      hintText: 'Subreddit'
      }
      @redditModel

    @activityButtonModel = {label : "Submit"}
    @controller.setupWidget("submitButton", {type:Mojo.Widget.activityButton}, @activityButtonModel)
    
    back_button = if @showBackNavigation()
      {label: $L('Back'), icon:'', command:'back', width: 80}
    else
      {}
      
    last_button = if @showBackNavigation()
      {width: 80}
    else
      {}
    
    @viewMenuModel =
      visible: true
      items: [
        back_button
        {}
        {
          toggleCmd: 'link-cmd'
          items: [
            {label: $L('Link'), icon:'', command:'link-cmd'}
            {label: $L('Text'), icon:'', command:'text-cmd'}
          ]
        }
        {}
        last_button
      ]    
  
    @controller.setupWidget(Mojo.Menu.commandMenu, { menuClass:'no-fade' }, @viewMenuModel)

  activate: (event) ->
    super
    
    @selectLink()
    
    @addListeners(
      [@controller.get("submitButton"), Mojo.Event.tap, @submit]
    )

  displayButtonSubmitting: ->
    @controller.get('submitButton').mojo.activate()
    @activityButtonModel.label = "Submitting"
    @activityButtonModel.disabled = true
    @controller.modelChanged(@activityButtonModel)

  displayButton: ->
    @controller.get('submitButton').mojo.deactivate()
    @activityButtonModel.label = "Submit"
    @activityButtonModel.disabled = false
    @controller.modelChanged(@activityButtonModel)

  handleCallback: (params) ->
    return params unless params?

    if params.type is 'article-submit'
      if params.success
        @handleSubmitSuccess(params.response)
      else
        @handleSubmitFailure(params.response)

  submit: =>
    @displayButtonSubmitting()
    
    params =
      title: @titleModel.value
      sr:	@redditModel.value
      kind:	@kind
      uh: @getModHash()
      
    params.url = @urlModel.value if @kind == 'link'
    params.text = @textModel.value if @kind == 'self'
      
    Mojo.Log.info(JSON.stringify(params))

    new Article(@).submit(params)
    
  selectLink: ->
    @kind = 'link'
    @controller.get('submit-url-row').show()
    @controller.get('submit-text-row').hide()
    
  selectText: ->
    @kind = 'self'
    @controller.get('submit-url-row').hide()
    @controller.get('submit-text-row').show()
    
  handleCommand: (event) ->
    return unless event.type is Mojo.Event.command

    switch event.command
      when 'link-cmd'
        @selectLink()
      when 'text-cmd'
        @selectText()
      when 'back'
        @controller.stageController.popScene()
  
  handleSubmitSuccess: (response) ->
    json_string = JSON.stringify(response.responseText)
    Mojo.Log.info(json_string)
    @displayButton()
    
    if json_string.indexOf('USER_REQUIRED') isnt -1
      Banner.send("please login to do that")
      return
    else if json_string.indexOf('RATELIMIT') isnt -1
      Banner.send("you are doing that too much")
      return
    else if json_string.indexOf('SUBREDDIT_REQUIRED') isnt -1
      Banner.send("you must specify a subreddit")
      return
    else if json_string.indexOf('SUBREDDIT_NOEXIST') isnt -1
      Banner.send("that reddit doesn't exist")
      return
    else if json_string.indexOf('SUBREDDIT_NOTALLOWED') isnt -1
      Banner.send("you aren't allowed to post there")
      return
    else if json_string.indexOf('NO_TEXT') isnt -1
      Banner.send("we need a title")
      return
    else if json_string.indexOf('NO_URL') isnt -1
      Banner.send("a url is required")
      return
    else if json_string.indexOf('/comments/') isnt -1
      @controller.get('submitButton').hide()
      Banner.send("Article submitted!")
      return
    
    Banner.send("im not sure what happened")

  handleSubmitFailure: (response) ->
    @displayButton()
    Banner.send("something went wrong")
