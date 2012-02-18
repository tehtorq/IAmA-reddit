class PrefsAssistant extends BaseAssistant
  
  constructor: (params) ->
    super

  setup: ->
    super
    
    value1 = @cookieValue("prefs-hide-thumbnails", "off")
    value3 = @cookieValue("prefs-show-easylinks", "off")
    value4 = @cookieValue("prefs-samecard", "off")
    value5 = @cookieValue("prefs-articles-per-page", "25")
    value6 = @cookieValue("prefs-lock-orientation", "off")
    value7 = Preferences.getTheme()
    value8 = @cookieValue("prefs-frontpage", "all")
    value9 = @cookieValue('prefs-galleries','1000words,aviation,battlestations,gifs,itookapicture,photocritique,pics,vertical,wallpaper,wallpapers,windowshots')
    value10 = @cookieValue("prefs-message-notifications", "off")
    value11 = @cookieValue("prefs-karma-notifications", "off")
    value12 = @cookieValue("prefs-notification-interval", "30")
    
    value13 = @cookieValue("prefs-readitlater-enabled", "off")
    value14 = @cookieValue("prefs-readitlater-username", "")
    value15 = @cookieValue("prefs-readitlater-password", "")
    value16 = @cookieValue("prefs-readitlater-apikey", "c25d9l36T62f6bf58fA47fvD3cg0Pr91")
    
    @galleriesModel = { value : value9 }

    @controller.setupWidget("galleriesTextFieldId", { 
        focusMode: Mojo.Widget.focusAppendMode
        textCase: Mojo.Widget.steModeLowerCase
        multiline: true
        enterSubmits: true
        autoFocus: false
      }
      @galleriesModel
    )
    
    @controller.setupWidget("hide_thumbnail_toggle_button",
      { trueValue : "on", falseValue : "off"}
      {value: value1, disabled: false}
    )

    @controller.setupWidget("hide_easylinks_toggle_button",
      { trueValue : "on", falseValue : "off"}
      {value: value3, disabled: false}
    )

    @controller.setupWidget("samecard_toggle_button",
      { trueValue : "on", falseValue : "off"}
      {value: value4, disabled: false}
    )

    @controller.setupWidget("lock_orientation_toggle_button",
      { trueValue : "on", falseValue : "off"}
      {value: value6, disabled: false}
    )
    
    @controller.setupWidget("message_notifications_toggle_button",
      { trueValue : "on", falseValue : "off"}
      {value: value10, disabled: false}
    )

    @controller.setupWidget("karma_notifications_toggle_button",
      { trueValue : "on", falseValue : "off"}
      {value: value11, disabled: false}
    )
    
    @controller.setupWidget("articles_per_page_radio_button",
      { 
        label: $L('Articles per page'),
        labelPlacement: Mojo.Widget.labelPlacementLeft,
        choices : [
                    { label : "10", value : "10" },
                    { label : "25", value : "25" },
                    { label : "50", value : "50" },
                    { label : "100", value : "100" }
                  ] },
      {value: value5}
    )
    
    theme_choices = _.map Preferences.themes, (theme) -> { label : theme, value : theme }
                                                        
    @controller.setupWidget("theme_radio_button", {
      label: $L('Theme'),
      labelPlacement: Mojo.Widget.labelPlacementLeft,
      choices: theme_choices
      }
      {value: value7}
    )
    
    reddits = []
    
    _.each Subreddit.cached_list, (item) ->
      reddits.push {label: item.label, value: item.label}

    reddits.unshift({label: 'random', value: 'random'})
    reddits.unshift({label: 'all', value: 'all'})
    reddits.unshift({label: 'frontpage', value: 'frontpage'})
    
    @controller.setupWidget("frontpage_button",
      label: $L('Default Frontpage'),
      labelPlacement: Mojo.Widget.labelPlacementLeft,
      { choices : reddits },
      {value: value8}
    )
    
    @controller.setupWidget("notification_interval",
      {
        label: 'Minutes Interval',
        labelPlacement: Mojo.Widget.labelPlacementLeft,
        modelProperty: 'value',
        min: 1,
        max: 59,
        padNumbers: true
      },
      { value: value12}
    )
    
    @controller.setupWidget("readitlater_toggle_button",
      { trueValue : "on", falseValue : "off"}
      {value: value13, disabled: false}
    )
    
    @controller.setupWidget "readitlaterUsernameTextFieldId", { 
      focusMode: Mojo.Widget.focusSelectMode
      textCase: Mojo.Widget.steModeLowerCase, maxLength : 30
      }
      {value: value14}

    @controller.setupWidget "readitlaterPasswordTextFieldId", {
      focusMode : Mojo.Widget.focusSelectMode
      textCase : Mojo.Widget.steModeLowerCase, maxLength : 30
      },
      {value: value15}
      
    @controller.setupWidget "readitlaterAPIkeyTextFieldId", {
      focusMode: Mojo.Widget.focusSelectMode
      textCase: Mojo.Widget.steModeLowerCase, maxLength : 30
      }
      {value: value16}
    
    if @showBackNavigation()
      @viewMenuModel =
        {
          visible: true,
          items: [{items:[{label: $L('Back'), icon:'', command:'back', width:80}]}]
        }
    
      @controller.setupWidget(Mojo.Menu.commandMenu, { menuClass:'no-fade' }, @viewMenuModel)

  activate: (event) ->
    super
    
    @addListeners(
      [@controller.get("hide_thumbnail_toggle_button"), Mojo.Event.propertyChange, @handleUpdate1]
      [@controller.get("hide_easylinks_toggle_button"), Mojo.Event.propertyChange, @handleUpdate3]
      [@controller.get("samecard_toggle_button"), Mojo.Event.propertyChange, @handleUpdate4]
      [@controller.get("articles_per_page_radio_button"), Mojo.Event.propertyChange, @handleUpdate5]
      [@controller.get("lock_orientation_toggle_button"), Mojo.Event.propertyChange, @handleUpdate6]
      [@controller.get("theme_radio_button"), Mojo.Event.propertyChange, @handleUpdate7]
      [@controller.get("frontpage_button"), Mojo.Event.propertyChange, @handleUpdate8]
      [@controller.get("galleriesTextFieldId"), Mojo.Event.propertyChange, @handleUpdate9]
      [@controller.get("message_notifications_toggle_button"), Mojo.Event.propertyChange, @handleUpdate10]
      [@controller.get("karma_notifications_toggle_button"), Mojo.Event.propertyChange, @handleUpdate11]
      [@controller.get("notification_interval"), Mojo.Event.propertyChange, @handleUpdate12]
      [@controller.get("readitlater_toggle_button"), Mojo.Event.propertyChange, @handleUpdate13]
      [@controller.get("readitlaterUsernameTextFieldId"), Mojo.Event.propertyChange, @handleUpdate14]
      [@controller.get("readitlaterPasswordTextFieldId"), Mojo.Event.propertyChange, @handleUpdate15]
      [@controller.get("readitlaterAPIkeyTextFieldId"), Mojo.Event.propertyChange, @handleUpdate16]
    )
  
  ready: ->
    @controller.setInitialFocusedElement(null)
  
  handleUpdate1: (event) =>
    cookie = new Mojo.Model.Cookie("prefs-hide-thumbnails")  
    cookie.put(event.value)

  handleUpdate3: (event) =>
    cookie = new Mojo.Model.Cookie("prefs-show-easylinks")
    cookie.put(event.value)

  handleUpdate4: (event) =>
    cookie = new Mojo.Model.Cookie("prefs-samecard")
    cookie.put(event.value)

  handleUpdate5: (event) =>
    cookie = new Mojo.Model.Cookie("prefs-articles-per-page")
    cookie.put(event.value)

  handleUpdate6: (event) =>
    cookie = new Mojo.Model.Cookie("prefs-lock-orientation")
    cookie.put(event.value)

  handleUpdate7: (event) =>
    Preferences.setTheme(event.value)

  handleUpdate8: (event) =>
    cookie = new Mojo.Model.Cookie("prefs-frontpage")
    cookie.put(event.value)
    
  handleUpdate9: (event) =>
    cookie = new Mojo.Model.Cookie("prefs-galleries")
    cookie.put(event.value)
    
  handleUpdate10: (event) =>
    new Mojo.Model.Cookie("prefs-message-notifications").put(event.value)
    Preferences.updateNotifications()
    
  handleUpdate11: (event) =>
    new Mojo.Model.Cookie("prefs-karma-notifications").put(event.value)
    Preferences.updateNotifications()
    
  handleUpdate12: (event) =>
    new Mojo.Model.Cookie("prefs-notification-interval").put(event.value)
    Preferences.updateNotifications()

  handleUpdate13: (event) =>
    cookie = new Mojo.Model.Cookie("prefs-readitlater-enabled")
    cookie.put(event.value)

  handleUpdate14: (event) =>
    cookie = new Mojo.Model.Cookie("prefs-readitlater-username")
    cookie.put(event.value)

  handleUpdate15: (event) =>
    cookie = new Mojo.Model.Cookie("prefs-readitlater-password")
    cookie.put(event.value)

  handleUpdate16: (event) =>
    cookie = new Mojo.Model.Cookie("prefs-readitlater-apikey")
    cookie.put(event.value)

  cookieValue: (cookieName, default_value) ->
    cookie = new Mojo.Model.Cookie(cookieName)
    return cookie.get() if cookie? and cookie.get()?
      
    default_value
    
  handleCommand: (event) ->
    return unless event.type is Mojo.Event.command

    switch event.command
      when 'back'
        @controller.stageController.popScene()
          