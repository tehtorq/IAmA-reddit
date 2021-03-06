class LoginAssistant extends BaseAssistant

  constructor: (params) ->
    super
    
    @usernameModel = {}
    @passwordModel = {}

  setup: ->
    super
    
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
    
    if not @showBackNavigation()
      @viewMenuModel = {
        visible: true,
        items: [
            {items:[{},
                    { label: $L('Login'), command: 'top', icon: "", width: @getViewMenuWidth()},
                    {}]}
        ]
      }
    else
      @viewMenuModel = {
        visible: true,
        items: [
            {items:[{},
                    {label: $L('Back'), icon:'', command:'back', width:80}
                    { label: $L('Login'), command: 'top', icon: "", width: @getViewMenuWidth() - 80},
                    {}]}
        ]
      }

    @controller.setupWidget(Mojo.Menu.viewMenu, { menuClass:'no-fade' }, @viewMenuModel)

  activate: (event) ->
    super
    
    @addListeners(
      [@controller.get("loginButton"), Mojo.Event.tap, @login]
    )

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
    
  handleCommand: (event) ->
    return unless event.type is Mojo.Event.command

    switch event.command
      when 'back'
        @controller.stageController.popScene()

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
      Banner.send("Login failure")

  loginSuccess: (response) ->
    cookie = response.data.cookie
    modhash = response.data.modhash

    new Mojo.Model.Cookie("reddit_session").put(cookie)
    Banner.send("Logged in as " + @usernameModel.value)
    @menu()

  loginFailure: (response) ->
    Banner.send(response.errors[0][1])

  menu: ->
    AppAssistant.openFrontpage("swap", {}, @controller)
