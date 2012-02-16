class ReplyAssistant extends BaseAssistant

  constructor: (reply_data) ->
    super
    
    @reply_data = reply_data

  setup: ->
    super
    
    @bodyModel = { items : [] }

    @controller.setupWidget("recipientTextFieldId",
      { focusMode : Mojo.Widget.focusSelectMode, textCase : Mojo.Widget.steModeLowerCase, maxLength : 30 },
      @model = {value: @reply_data.user,disabled: false}
    )

    @controller.setupWidget("bodyTextFieldId",
      { focusMode : Mojo.Widget.focusSelectMode, multiline: true },
      @bodyModel
    )

    @sendButtonModel = {label : "Send"}
    @controller.setupWidget("sendButton", {type:Mojo.Widget.activityButton}, @sendButtonModel)
    
    if not @showBackNavigation()
      @viewMenuModel = {
        visible: true,
        items: [
            {items:[{},
                    { label: $L('Reply'), command: 'top', icon: "", width: @getViewMenuWidth()},
                    {}]}
        ]
      }
    else
      @viewMenuModel = {
        visible: true,
        items: [
            {items:[{},
                    {label: $L('Back'), icon:'', command:'back', width:80}
                    { label: $L('Reply'), command: 'top', icon: "", width: @getViewMenuWidth() - 80},
                    {}]}
        ]
      }

    @controller.setupWidget(Mojo.Menu.commandMenu, { menuClass:'no-fade' }, @viewMenuModel)

  activate: (event) ->
    super
    
    @addListeners(
      [@controller.get("sendButton"), Mojo.Event.tap, @sendMessage]
    )
    
    @controller.get("bodyTextFieldId").mojo.focus()

  handleCommand: (event) ->
    return if event.type isnt Mojo.Event.command

    switch event.command
      when 'top'
        @scrollToTop()
      when 'back'
        @controller.stageController.popScene()

  handleCallback: (params) ->
    return params unless params? and params.success
   
    if params.type is "comment-reply"
      @displayButtonSent()
      Banner.send("Replied to " + @reply_data.user + ".")
      @controller.stageController.popScene({replied: true, comment_id: @reply_data.thing_id})

  sendMessage: =>
    @displayButtonSending()

    params =
      thing_id: @reply_data.thing_id
      text: @bodyModel.value
      uh: @getModHash()
      id: '#commentreply_' + @reply_data.thing_id
      r: @reply_data.subreddit

    new Comment(@).reply(params)
  
  editMessage: ->
    @displayButtonSending()

    params =
      thing_id: @reply_data.thing_id
      text: @bodyModel.value
      uh: @getModHash()
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
