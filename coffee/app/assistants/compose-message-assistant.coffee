class ComposeMessageAssistant
  
  constructor: (params) ->
    @cardname = "card" + Math.floor(Math.random()*10000)
    @url = 'http://reddit.com' + '/message/compose/'
    @recipientModel = { value : params.to || '' }
    @subjectModel = { value : '' }
    @bodyModel = { value : '' }
    @captchaModel = { value : '' }

  setup: ->
    StageAssistant.setTheme(@)

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

    Mojo.Event.listen(@controller.get("sendButton"), Mojo.Event.tap, @sendMessage)

  activate: (event) ->
    StageAssistant.defaultWindowOrientation(@, "up")
    @displayComposeMessage()

  deactivate: (event) ->
  cleanup: (event) ->
    Request.clear_all(@cardname)
    Mojo.Event.stopListening(@controller.get("sendButton"), Mojo.Event.tap, @sendMessage)

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
      new Banner("Message sent to #{@recipientModel.value}").send()
      return
    else if json_string.indexOf('BAD_CAPTCHA') isnt -1
      new Banner("Are you human?").send()
    else if json_string.indexOf('USER_DOESNT_EXIST') isnt -1
      new Banner("User doesn't exist!").send()
    else
      new Banner("Something went wrong!").send()
        
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

          # work out captcha

          start = responseText.indexOf('src="/captcha/') + 14
          end = responseText.indexOf('.png', start)

          return false if (start is -1) or (end is -1)
          
          @iden = responseText.substr(start, end - start)

          # work out uh
                    
          startx = responseText.lastIndexOf("modhash: '") + 10
          endx = responseText.indexOf(',', startx)
          
          return false if (startx is -1) or (endx is -1)

          @modhash = responseText.substr(startx, endx - startx - 1)

          url = 'http://www.reddit.com/captcha/' + @iden + '.png'

          @controller.get('image_id').src = url
          @controller.get('sendButton').show()
        onFailure: (inTransport) =>
          $("contentarea").update("Failure")
        onException: (inTransport, inException) =>
          $("contentarea").update("Exception")
      }
    )
