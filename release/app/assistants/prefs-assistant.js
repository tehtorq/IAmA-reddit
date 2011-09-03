function PrefsAssistant() {
	/* this is the creator function for your scene assistant object. It will be passed all the
	   additional parameters (after the scene name) that were passed to pushScene. The reference
	   to the scene controller (this.controller) has not be established yet, so any initialization
	   that needs the scene controller should be done in the setup function below. */
}

PrefsAssistant.prototype.setup = function() {
  StageAssistant.setTheme(this);
  
	/* this function is for setup tasks that have to happen when the scene is first created */

  var value1 = this.cookieValue("prefs-hide-thumbnails", "off");
  var value3 = this.cookieValue("prefs-hide-easylinks", "off");
  var value4 = this.cookieValue("prefs-samecard", "off");
  var value5 = this.cookieValue("prefs-articles-per-page", "25");
  var value6 = this.cookieValue("prefs-lock-orientation", "off");
  var value7 = this.cookieValue("prefs-theme", "stylesheets/reddit-dark.css");
  var value8 = this.cookieValue("prefs-frontpage", "all");

	/* use Mojo.View.render to render view templates and add them to the scene, if needed */

	/* setup widgets here */

	this.controller.setupWidget("hide_thumbnail_toggle_button",
		{ trueValue : "on", falseValue : "off"},
		{value: value1, disabled: false}
	);

  this.controller.setupWidget("hide_easylinks_toggle_button",
		{ trueValue : "on", falseValue : "off"},
		{value: value3, disabled: false}
	);
    
  this.controller.setupWidget("samecard_toggle_button",
		{ trueValue : "on", falseValue : "off"},
		{value: value4, disabled: false}
	);

  this.controller.setupWidget("lock_orientation_toggle_button",
		{ trueValue : "on", falseValue : "off"},
		{value: value6, disabled: false}
	);

  this.controller.setupWidget("articles_per_page_radio_button",
                          { choices : [
                                        { label : "10", value : "10" },
                                        { label : "25", value : "25" },
                                        { label : "50", value : "50" },
                                        { label : "100", value : "100" }
                                      ] },
                          {value: value5}
                          );
                                                        
  this.controller.setupWidget("theme_radio_button",
    { choices : [
                  { label : "light", value : "stylesheets/reddit-light.css" },
                  { label : "dark", value : "stylesheets/reddit-dark.css" },
                  { label : "custom", value : "stylesheets/reddit-custom.css" },
                  /*{ label : "custom-dark", value : "stylesheets/reddit-custom-dark.css" },*/
                  { label : "kuler", value : "stylesheets/reddit-kuler.css" }
                ] },
    {value: value7}
  );
    
  var reddits = [];
  
  for (var i = 0; i < Subreddit.cached_list.length; i++) {
    reddits.push({label: Subreddit.cached_list[i].label, value: Subreddit.cached_list[i].label});
  }

  reddits.unshift({label: 'random', value: 'random'});
  reddits.unshift({label: 'all', value: 'all'});
  reddits.unshift({label: 'frontpage', value: 'frontpage'});
    
  this.controller.setupWidget("frontpage_button",
    { choices : reddits },
    {value: value8}
  );
                            
	/* add event handlers to listen to events from widgets */

  Mojo.Event.listen(this.controller.get("hide_thumbnail_toggle_button"), Mojo.Event.propertyChange, this.handleUpdate1.bind(this));
  Mojo.Event.listen(this.controller.get("hide_easylinks_toggle_button"), Mojo.Event.propertyChange, this.handleUpdate3.bind(this));
  Mojo.Event.listen(this.controller.get("samecard_toggle_button"), Mojo.Event.propertyChange, this.handleUpdate4.bind(this));
  Mojo.Event.listen(this.controller.get("articles_per_page_radio_button"), Mojo.Event.propertyChange, this.handleUpdate5.bind(this));
  Mojo.Event.listen(this.controller.get("lock_orientation_toggle_button"), Mojo.Event.propertyChange, this.handleUpdate6.bind(this));
  Mojo.Event.listen(this.controller.get("theme_radio_button"), Mojo.Event.propertyChange, this.handleUpdate7.bind(this));
  Mojo.Event.listen(this.controller.get("frontpage_button"), Mojo.Event.propertyChange, this.handleUpdate8.bind(this));
};

PrefsAssistant.prototype.activate = function(event) {
  StageAssistant.defaultWindowOrientation(this, "free");
};

PrefsAssistant.prototype.deactivate = function(event) {
	/* remove any event handlers you added in activate and do any other cleanup that should happen before
	   this scene is popped or another scene is pushed on top */
};

PrefsAssistant.prototype.cleanup = function(event) {
	/* this function should do any cleanup needed before the scene is destroyed as
	   a result of being popped off the scene stack */

  //Mojo.Event.listen(this.controller.get("thumbnail_toggle_button"), Mojo.Event.propertyChange, this.handleUpdate1.bind(this));  
  //Mojo.Event.listen(this.controller.get("easylinks_toggle_button"), Mojo.Event.propertyChange, this.handleUpdate3.bind(this));
  //Mojo.Event.listen(this.controller.get("newcard_toggle_button"), Mojo.Event.propertyChange, this.handleUpdate4.bind(this));
};

PrefsAssistant.prototype.handleUpdate1 = function(event) {
  var cookie = new Mojo.Model.Cookie("prefs-hide-thumbnails");  
  cookie.put(event.value);
}

PrefsAssistant.prototype.handleUpdate3 = function(event) {
  var cookie = new Mojo.Model.Cookie("prefs-hide-easylinks");
  cookie.put(event.value);
}

PrefsAssistant.prototype.handleUpdate4 = function(event) {
  var cookie = new Mojo.Model.Cookie("prefs-samecard");
  cookie.put(event.value);
}

PrefsAssistant.prototype.handleUpdate5 = function(event) {
  var cookie = new Mojo.Model.Cookie("prefs-articles-per-page");
  cookie.put(event.value);
}

PrefsAssistant.prototype.handleUpdate6 = function(event) {
  var cookie = new Mojo.Model.Cookie("prefs-lock-orientation");
  cookie.put(event.value);
}

PrefsAssistant.prototype.handleUpdate7 = function(event) {
  var cookie = new Mojo.Model.Cookie("prefs-theme");
  cookie.put(event.value);
  
  StageAssistant.switchTheme(event.value);
}

PrefsAssistant.prototype.handleUpdate8 = function(event) {
  var cookie = new Mojo.Model.Cookie("prefs-frontpage");
  cookie.put(event.value);
}

PrefsAssistant.prototype.cookieValue = function(cookieName, default_value) {
	var cookie = new Mojo.Model.Cookie(cookieName);

  if (cookie) {
    var value = cookie.get();    
    return value;
  }

  return default_value;
}