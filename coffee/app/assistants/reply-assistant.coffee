class ReplyAssistant

  constructor: (reply_data) ->
    @reply_data = reply_data

  setup: ->
    StageAssistant.setTheme(@)
    
    @bodyModel = { items : [] }

    @controller.setupWidget("recipientTextFieldId",
      { focusMode : Mojo.Widget.focusSelectMode, textCase : Mojo.Widget.steModeLowerCase, maxLength : 30 },
      @model = {value: @reply_data.user,disabled: false}
    )

    @controller.setupWidget("bodyTextFieldId",
      { focusMode : Mojo.Widget.focusSelectMode, textCase : Mojo.Widget.steModeLowerCase, multiline: true },
      @bodyModel
    )

    @sendButtonModel = {label : "Send"}
    @controller.setupWidget("sendButton", {type:Mojo.Widget.activityButton}, @sendButtonModel)
    Mojo.Event.listen(@controller.get("sendButton"), Mojo.Event.tap, @sendMessage)

  activate: (event) ->
    StageAssistant.defaultWindowOrientation(@, "up")
    @controller.get("bodyTextFieldId").mojo.focus()

  deactivate: (event) ->

  cleanup: (event) ->
    @reply_data = null
    Mojo.Event.stopListening(@controller.get("sendButton"), Mojo.Event.tap, @sendMessage)

  handleCallback: (params) ->
    return params unless params? and params.success
   
    if params.type is "comment-reply"
      @displayButtonSent()
      new Banner("Replied to " + @reply_data.user + ".").send()
      @controller.stageController.popScene({replied: true, comment_id: @reply_data.thing_id})

  sendMessage: =>
    @displayButtonSending()

    params =
      thing_id: @reply_data.thing_id
      text: @bodyModel.value
      uh: @reply_data.modhash
      id: '#commentreply_' + @reply_data.thing_id
      r: @reply_data.subreddit

    new Comment(@).reply(params)
  
  editMessage: ->
    @displayButtonSending()

    params =
      thing_id: @reply_data.thing_id
      text: @bodyModel.value
      uh: @reply_data.modhash
      r: @reply_data.subreddit

    new Comment(@).edit(params)

  displayButtonSend: ->
    @controller.get('sendButton').mojo.deactivate()
    @sendButtonModel.label = "Send"
    @sendButtonModel.disabled = false
    @controller.modelChanged(@sendButtonModel)

  displayButtonSending: ->
    @controller.get('sendButton').mojo.activate()
    @sendButtonModel.label = "Sending"
    @sendButtonModel.disabled = true
    @controller.modelChanged(@sendButtonModel)

  displayButtonSent: ->
    @controller.get('sendButton').mojo.deactivate()
    @sendButtonModel.label = "Sent"
    @sendButtonModel.disabled = false
    @controller.modelChanged(@sendButtonModel)
