class ComposeMessageAssistant extends BaseAssistant
  
  constructor: (params) ->
    super
    
    @url = 'http://reddit.com/message/compose/'
    @recipientModel = { value : params.to || '' }
    @subjectModel = { value : '' }
    @bodyModel = { value : '' }
    @captchaModel = { value : '' }

  setup: ->
    super

    @controller.setupWidget("recipientTextFieldId",
      { focusMode : Mojo.Widget.focusSelectMode, textCase : Mojo.Widget.steModeLowerCase, maxLength : 30 },
      @recipientModel
      )

    @controller.setupWidget("subjectTextFieldId",
      { focusMode : Mojo.Widget.focusSelectMode, textCase : Mojo.Widget.steModeLowerCase, maxLength : 30 },
      @subjectModel
      )

    @controller.setupWidget("bodyTextFieldId",
      { focusMode : Mojo.Widget.focusSelectMode, textCase : Mojo.Widget.steModeLowerCase, multiline: true },
      @bodyModel
      )

    @controller.setupWidget("captchaTextFieldId",
      { focusMode : Mojo.Widget.focusSelectMode, textCase : Mojo.Widget.steModeLowerCase, maxLength : 30 },
      @captchaModel
      )

    @controller.setupWidget("sendButton", {}, { label : "Send"})
    
    if not @showBackNavigation()
      @viewMenuModel = {
        visible: true,
        items: [
            {items:[{},
                    { label: $L('Send a message'), command: 'top', icon: "", width: @getViewMenuWidth()},
                    {}]}
        ]
      }
    else
      @viewMenuModel = {
        visible: true,
        items: [
            {items:[{},
                    {label: $L('Back'), icon:'', command:'back', width:80}
                    { label: $L('Send a message'), command: 'top', icon: "", width: @getViewMenuWidth() - 80},
                    {}]}
        ]
      }

    @controller.setupWidget(Mojo.Menu.viewMenu, { menuClass:'no-fade' }, @viewMenuModel)

  activate: (event) ->
    super
    
    @addListeners(
      [@controller.get("sendButton"), Mojo.Event.tap, @sendMessage]
    )
    
    StageAssistant.defaultWindowOrientation(@, "up")
    @displayComposeMessage()

  displayComposeMessage: (object) ->
    @fetchHTMLComposePage()
    
  handleCallback: (params) ->
    return params unless params? and params.success

    if params.type is "message-compose"
      @handleComposeMessageResponse(params.response)
      
  handleComposeMessageResponse: (response) ->
    @controller.get('sendButton').hide()
    json_string = JSON.stringify(response.responseText)
  
    if json_string.indexOf('your message has been delivered') isnt -1
      Banner.send("Message sent to #{@recipientModel.value}")
      return
    else if json_string.indexOf('BAD_CAPTCHA') isnt -1
      Banner.send("Are you human?")
    else if json_string.indexOf('USER_DOESNT_EXIST') isnt -1
      Banner.send("User doesn't exist!")
    else
      Banner.send("Something went wrong!")
        
    @fetchHTMLComposePage()

  sendMessage: =>
    to = @recipientModel.value
    subject = @subjectModel.value
    body = @bodyModel.value
    captcha = @captchaModel.value

    params =
      to: to
      subject: subject
      text: body
      captcha: captcha
      iden: @iden
      uh: @modhash
      
    new Message(@).compose(params)

  fetchHTMLComposePage: ->
    @controller.get('sendButton').hide()
    
    new Ajax.Request(
      @url
      {
        method: "get"
        onSuccess: (inTransport) =>
          responseText = inTransport.responseText
          #Mojo.Log.info(responseText)

          # work out captcha

          start = responseText.indexOf('src="/captcha/') + 14
          end = responseText.indexOf('.png', start)

          if (start is -1) or (end is -1)
            @controller.get('no_captcha_msg').update('No captcha required!')
          
          @iden = responseText.substr(start, end - start)
          
          #Mojo.Log.info("iden #{iden}")

          # work out uh
                    
          startx = responseText.lastIndexOf("modhash: '") + 10
          endx = responseText.indexOf(',', startx)
          
          if (startx is -1) or (endx is -1)
            Banner.send("Are you logged in?")
            return false

          @modhash = responseText.substr(startx, endx - startx - 1)
          
          #Mojo.Log.info("modhash #{@modhash}")

          url = 'http://www.reddit.com/captcha/' + @iden + '.png'
          
          #Mojo.Log.info("url #{url}")

          @controller.get('image_id').src = url
          @controller.get('sendButton').show()
        onFailure: (inTransport) =>
          @controller.get("contentarea").update("Failure")
        onException: (inTransport, inException) =>
          @controller.get("contentarea").update("Exception")
      }
    )
    
  handleCommand: (event) ->
    return if event.type isnt Mojo.Event.command

    params = event.command.split(' ')

    switch params[0]
      when 'top'
        @scrollToTop()
      when 'back'
        @controller.stageController.popScene()
