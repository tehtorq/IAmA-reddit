class RegisterAssistant

  constructor: ->
    @usernameModel: { }
    @passwordModel: { }
    @captchaModel: { }

  setup: ->
    StageAssistant.setTheme(@)
    
    @controller.setupWidget("textFieldId",
      { focusMode : Mojo.Widget.focusSelectMode, textCase : Mojo.Widget.steModeLowerCase, maxLength : 30 },
      @usernameModel
    )

    @controller.setupWidget("passwordFieldId",
      { focusMode : Mojo.Widget.focusSelectMode, textCase : Mojo.Widget.steModeLowerCase, maxLength : 30 },
      @passwordModel
    )

    @controller.setupWidget("captchaTextFieldId",
      { focusMode : Mojo.Widget.focusSelectMode, textCase : Mojo.Widget.steModeLowerCase, maxLength : 30 },
      @captchaModel
    )

    @activityButtonModel = {label : "create account"}
    @controller.setupWidget("registerButton", {type:Mojo.Widget.activityButton}, @activityButtonModel)
    @registerBind = @register.bind(@)

    Mojo.Event.listen(@controller.get("registerButton"), Mojo.Event.tap, @registerBind)

  activate: (event) ->
    StageAssistant.defaultWindowOrientation(@, "up")
    @usernameModel.value = null
    @passwordModel.value = null
    @captchaModel.value = null
    @iden = null
    
    @fetchCaptcha()

  deactivate: (event) ->

  cleanup: (event) ->
    Mojo.Event.stopListening(@controller.get("registerButton"), Mojo.Event.tap, @registerBind)

  displayButtonRegistering: ->
    @controller.get('registerButton').mojo.activate()
    @activityButtonModel.label = "creating account"
    @activityButtonModel.disabled = true
    @controller.modelChanged(@activityButtonModel)

  displayButtonRegister: ->
    @controller.get('registerButton').mojo.deactivate()
    @activityButtonModel.label = "create account"
    @activityButtonModel.disabled = false
    @controller.modelChanged(@activityButtonModel)

  handleCallback: (params) ->
    return params unless params?

    if params.type is 'user-create'
      if params.success
        @handleRegisterResponse(params.response)
      else
        @displayButtonRegister()
    else if params.type is 'load-captcha'
      @handleCaptchaResponse(params.response)

  register: ->
    @displayButtonRegistering()
    
    params:
      captcha: @captchaModel.value
      email: ''
      id:	'#login_reg'
      iden:	@iden
      op:	'reg'
      passwd:	@passwordModel.value
      passwd2:	@passwordModel.value
      reason: ''
      renderstyle:	'html'
      user:	@usernameModel.value
      api_type: 'json'

    new User(@).create(params)

  handleRegisterResponse: (response) ->
    json = response.responseJSON.json
    @displayButtonRegister()

    if json.data?
      @registerSuccess(json)
    else
      @registerFailure(json)

  registerSuccess: (response) ->
    cookie = response.data.cookie
    modhash = response.data.modhash

    new Mojo.Model.Cookie("reddit_session").put(cookie)
    new Banner("Created " + @usernameModel.value).send()
    @menu()

  registerFailure: (response) ->
    @fetchCaptcha()
    new Banner(response.errors[0][1]).send()

  fetchCaptcha: ->
    new Request(@).post('http://www.reddit.com/api/new_captcha', {uh: ''}, 'load-captcha')

  handleCaptchaResponse: (response) ->
    # eg:  FkSCAzeJOD3NJBLBJavGHhyxbCU3gEoU

    matches = response.responseText.match(/[0-9A-Za-z]{32}/)
    @iden = matches[0]

    url = 'http://www.reddit.com/captcha/' + @iden + '.png'
    @controller.get('image_id').src = url

  menu: ->
    @controller.stageController.swapScene({name:"frontpage",transition: Mojo.Transition.crossFade})