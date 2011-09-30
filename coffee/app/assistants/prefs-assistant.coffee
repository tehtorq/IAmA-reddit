class PrefsAssistant
  
  constructor: ->

  setup: ->
    @cardname = "card" + Math.floor(Math.random()*10000)
    StageAssistant.setTheme(@)
    
    value1 = @cookieValue("prefs-hide-thumbnails", "off")
    value3 = @cookieValue("prefs-hide-easylinks", "off")
    value4 = @cookieValue("prefs-samecard", "off")
    value5 = @cookieValue("prefs-articles-per-page", "25")
    value6 = @cookieValue("prefs-lock-orientation", "off")
    value7 = @cookieValue("prefs-theme", "stylesheets/reddit-dark.css")
    value8 = @cookieValue("prefs-frontpage", "all")
    value9 = @cookieValue('prefs-galleries','1000words,aviation,battlestations,gifs,itookapicture,photocritique,pics,vertical,wallpaper,wallpapers,windowshots')
    
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
    
    @controller.setupWidget("articles_per_page_radio_button",
      { 
        label: $L('Articles per page'),
        choices : [
                    { label : "10", value : "10" },
                    { label : "25", value : "25" },
                    { label : "50", value : "50" },
                    { label : "100", value : "100" }
                  ] },
      {value: value5}
    )
                                                        
    @controller.setupWidget("theme_radio_button", {
      label: $L('Theme'), 
      choices: 
        [
          { label : "light", value : "stylesheets/reddit-light.css" }
          { label : "dark", value : "stylesheets/reddit-dark.css" }
          { label : "custom", value : "stylesheets/reddit-custom.css" }
          #{ label : "custom-dark", value : "stylesheets/reddit-custom-dark.css" }
          { label : "kuler", value : "stylesheets/reddit-kuler.css" }
          #{ label : "lcd", value : "stylesheets/lcd-theme.css" }
        ]
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
      { choices : reddits },
      {value: value8}
    )

  activate: (event) ->
    Mojo.Event.listen(@controller.get("hide_thumbnail_toggle_button"), Mojo.Event.propertyChange, @handleUpdate1)
    Mojo.Event.listen(@controller.get("hide_easylinks_toggle_button"), Mojo.Event.propertyChange, @handleUpdate3)
    Mojo.Event.listen(@controller.get("samecard_toggle_button"), Mojo.Event.propertyChange, @handleUpdate4)
    Mojo.Event.listen(@controller.get("articles_per_page_radio_button"), Mojo.Event.propertyChange, @handleUpdate5)
    Mojo.Event.listen(@controller.get("lock_orientation_toggle_button"), Mojo.Event.propertyChange, @handleUpdate6)
    Mojo.Event.listen(@controller.get("theme_radio_button"), Mojo.Event.propertyChange, @handleUpdate7)
    Mojo.Event.listen(@controller.get("frontpage_button"), Mojo.Event.propertyChange, @handleUpdate8)
    Mojo.Event.listen(@controller.get("galleriesTextFieldId"), Mojo.Event.propertyChange, @handleUpdate9)
    StageAssistant.defaultWindowOrientation(@, "free")

  deactivate: (event) ->
    Mojo.Event.stopListening(@controller.get("hide_thumbnail_toggle_button"), Mojo.Event.propertyChange, @handleUpdate1)
    Mojo.Event.stopListening(@controller.get("hide_easylinks_toggle_button"), Mojo.Event.propertyChange, @handleUpdate3)
    Mojo.Event.stopListening(@controller.get("samecard_toggle_button"), Mojo.Event.propertyChange, @handleUpdate4)
    Mojo.Event.stopListening(@controller.get("articles_per_page_radio_button"), Mojo.Event.propertyChange, @handleUpdate5)
    Mojo.Event.stopListening(@controller.get("lock_orientation_toggle_button"), Mojo.Event.propertyChange, @handleUpdate6)
    Mojo.Event.stopListening(@controller.get("theme_radio_button"), Mojo.Event.propertyChange, @handleUpdate7)
    Mojo.Event.stopListening(@controller.get("frontpage_button"), Mojo.Event.propertyChange, @handleUpdate8)
    Mojo.Event.stopListening(@controller.get("galleriesTextFieldId"), Mojo.Event.propertyChange, @handleUpdate9)
    
  cleanup: (event) ->
    Request.clear_all(@cardname)

  handleUpdate1: (event) =>
    cookie = new Mojo.Model.Cookie("prefs-hide-thumbnails")  
    cookie.put(event.value)

  handleUpdate3: (event) =>
    cookie = new Mojo.Model.Cookie("prefs-hide-easylinks")
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
    cookie = new Mojo.Model.Cookie("prefs-theme")
    cookie.put(event.value)
    StageAssistant.switchTheme(event.value)

  handleUpdate8: (event) =>
    cookie = new Mojo.Model.Cookie("prefs-frontpage")
    cookie.put(event.value)
    
  handleUpdate9: (event) =>
    cookie = new Mojo.Model.Cookie("prefs-galleries")
    cookie.put(event.value)

  cookieValue: (cookieName, default_value) ->
    cookie = new Mojo.Model.Cookie(cookieName)
    return cookie.get() if cookie? and cookie.get()?
      
    default_value