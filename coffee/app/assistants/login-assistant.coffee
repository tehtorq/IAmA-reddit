class LoginAssistant

  constructor: ->
    @usernameModel = {}
    @passwordModel = {}

  setup: ->
    StageAssistant.setTheme(@)
    
    @controller.setupWidget "textFieldId", { 
      focusMode: Mojo.Widget.focusSelectMode
      textCase: Mojo.Widget.steModeLowerCase, maxLength : 30
      }
      @usernameModel

    @controller.setupWidget("passwordFieldId",
      { focusMode : Mojo.Widget.focusSelectMode, textCase : Mojo.Widget.steModeLowerCase, maxLength : 30 },
      @passwordModel
      )

    @activityButtonModel = {label : "Login"}
    @controller.setupWidget("loginButton", {type:Mojo.Widget.activityButton}, @activityButtonModel)

    Mojo.Event.listen(@controller.get("loginButton"), Mojo.Event.tap, @login)

  activate: (event) ->
    StageAssistant.defaultWindowOrientation(@, "up")

  deactivate: (event) ->

  cleanup: (event) ->
    Mojo.Event.stopListening(@controller.get("loginButton"), Mojo.Event.tap, @login)

  displayButtonLoggingIn: ->
    @controller.get('loginButton').mojo.activate()
    @activityButtonModel.label = "Logging in"
    @activityButtonModel.disabled = true
    @controller.modelChanged(@activityButtonModel)

  displayButtonLogin: ->
    @controller.get('loginButton').mojo.deactivate()
    @activityButtonModel.label = "Login"
    @activityButtonModel.disabled = false
    @controller.modelChanged(@activityButtonModel)

  handleCallback: (params) ->
    return params unless params?

    if params.type is 'user-login'
      if params.success
        @handleLoginResponse(params.response)
      else
        @displayButtonLogin()

  login: =>
    @displayButtonLoggingIn()
    
    params =
      user: @usernameModel.value
      passwd: @passwordModel.value
      api_type: 'json'

    new User(@).login(params)

  handleLoginResponse: (response) ->
    return if response.readyState isnt 4
    
    @displayButtonLogin()
    @passwordModel.value = ''
    
    if response.responseJSON?
      json = response.responseJSON.json

      if json.data?
        @loginSuccess(json)
      else
        @loginFailure(json)
    else
      new Banner("Login failure").send()

  loginSuccess: (response) ->
    cookie = response.data.cookie
    modhash = response.data.modhash

    new Mojo.Model.Cookie("reddit_session").put(cookie)
    new Banner("Logged in as " + @usernameModel.value).send()
    @menu()

  loginFailure: (response) ->
    new Banner(response.errors[0][1]).send()

  menu: ->
    @controller.stageController.swapScene({name:"frontpage",transition: Mojo.Transition.crossFade})
