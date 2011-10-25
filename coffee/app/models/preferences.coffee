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