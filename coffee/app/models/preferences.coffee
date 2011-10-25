class Preferences
  
  @themes = ['dark','kuler','light','wood','custom']
  
  @setTheme: (theme) ->
    theme = 'dark' unless theme in @themes
    @theme = theme
    
    new Mojo.Model.Cookie("prefs-theme").put(@theme)
    StageAssistant.switchTheme()
  
  @getTheme: ->
    @theme = StageAssistant.cookieValue("prefs-theme", "dark") unless @theme?
    @theme = 'dark' unless @theme in @themes
    @theme
    
  @themePath: ->
    "stylesheets/themes/#{@getTheme()}.css"