class Preferences
  
  @themes = ['dark','kuler','light','wood','custom']
  
  @setTheme: (theme) ->
    old_theme_path = @getThemePath()
    theme = 'dark' unless theme in @themes
    @theme = theme
    
    new Mojo.Model.Cookie("prefs-theme").put(@theme)
    StageAssistant.switchTheme(@getThemePath(), old_theme_path)
  
  @getTheme: ->
    @theme = StageAssistant.cookieValue("prefs-theme", "dark") unless @theme?
    @theme = 'dark' unless @theme in @themes
    @theme
    
  @getThemePath: ->
    "stylesheets/themes/#{@getTheme()}.css"
    
  @updateNotifications: ->
    if StageAssistant.cookieValue("prefs-message-notifications", "off") is "on" or StageAssistant.cookieValue("prefs-karma-notifications", "off") is "on"
      @enableNotificationsTimer(StageAssistant.cookieValue("prefs-notification-interval", "30"))
    else
      @disableNotificationsTimer()
    
  @enableNotificationsTimer: (interval) ->
    Mojo.Log.info("Enabling notifications timer: #{interval} minute interval")
    
    new Mojo.Service.Request("palm://com.palm.power/timeout", {
      method: "set",
      parameters: {
        "wakeup" : true,
        "key" : "reddit_check_messages",
        "uri": "palm://com.palm.applicationManager/open",
        "in" : "00:#{interval}:00",
        "params" : "{'id': '#{Mojo.appInfo.id}','params': {'action': 'checkMessages'}}"
      }
      onSuccess: (response) ->
        Mojo.Log.info("Message notification timer set successfully")
      onFailure: (response) ->
        Mojo.Log.info("Message notification timer failure", response.returnValue, response.errorText)
    })
    
  @disableNotificationsTimer: ->
    Mojo.Log.info("Disable notifications timer")
    
    new Mojo.Service.Request('palm://com.palm.power/timeout', {
        method: "clear",
        parameters: {"key" : "reddit_check_messages"}
    })
    
