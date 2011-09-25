class ComposeMessageAssistant
  
  constructor: (params) ->
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
    Mojo.Event.stopListening(@controller.get("sendButton"), Mojo.Event.tap, @sendMessage)

  displayComposeMessage: (object) ->
    @fetchHTMLComposePage()

  sendMessage: =>
    to = @recipientModel.value
    subject = @subjectModel.value
    body = @bodyModel.value
    captcha = @captchaModel.value

    postdata =
      to: to
      subject: subject
      text: body
      captcha: captcha
      iden: @iden
      uh: @modhash
      
    Mojo.Log.info(JSON.stringify(postdata))

    new Ajax.Request(   
      'http://www.reddit.com/api/compose'
      {
        method: "post"   
        parameters: postdata
        # parameters:
        #   customHttpHeaders: [
        #     'Referer: http://www.reddit.com/message/compose/'
        #     'x-reddit-version: 1.1'
        #   ]
        #Referer: 'http://www.reddit.com/message/compose?to=' + to
        onSuccess: (inTransport) =>
          Mojo.Log.info('success')
          responseText = inTransport.responseJSON
          json_string = Object.toJSON(responseText)
          
          Mojo.Log.info(JSON.stringify(responseText))
        
          if json_string.indexOf('your message has been delivered') isnt -1
            @debug('Success!')
          else
            @debug('Failure!')                 
                    
        onFailure: (inTransport) ->
          Mojo.Log.info('failure')
        onException: (inTransport, inException) ->
          Mojo.Log.info('exception')
      }
    )

  fetchHTMLComposePage: ->
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
        onFailure: (inTransport) =>
          $("contentarea").update("Failure")
        onException: (inTransport, inException) =>
          $("contentarea").update("Exception")
      }
    )
