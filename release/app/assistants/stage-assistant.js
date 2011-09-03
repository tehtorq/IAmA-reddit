function StageAssistant() {
	/* this is the creator function for your stage assistant object */
}



StageAssistant.prototype.setup = function(arg) {
	/* this function is for setup tasks that have to happen when the stage is first created */
	
	/* for a simple application, the stage assistant's only task is to push the scene, making it
	   visible */

	//this.controller.pushScene({name:"frontpage",disableSceneScroller:false,transition: Mojo.Transition.crossFade});
};

StageAssistant.prototype.checkConnection = function(callback, fallback) {
  var request = new Mojo.Service.Request('palm://com.palm.connectionmanager', {
      'method': 'getstatus',
      'parameters': {},
      'onSuccess': callback,
      'onFailure': fallback
  });
};

StageAssistant.appMenuModel = {
  visible: true,
  items: [
      {label: "Manage User", items: [{label: "Login", command: 'login-cmd'},
                                     {label: "Register", command: 'register-cmd'}/*,
                                     {label: "Logout", command: 'logout-cmd'}*/]},
      {label: "Reddits", command: 'reddits-cmd'},
      {label: "Gallery", command: 'gallery-cmd'},
      {label: "Recent Comments", command: 'recent-comments-cmd'},
      {label: "Messages", command: 'messages-cmd'},
      {label: "Preferences", command: Mojo.Menu.prefsCmd}
  ]
};

StageAssistant.cookieValue = function(cookieName, default_value) {
	var cookie = new Mojo.Model.Cookie(cookieName);

  if (cookie) {
    var value = cookie.get();
    
    if (value == undefined) {
      return default_value;
    }
    
    return value;
  }

  return default_value;
}

StageAssistant.cloneImageCard = function(assistant, article){
  var lowercase_subreddit = article.data.subreddit.toLowerCase();
  
  if (article.kind) {
    article.url = Linky.parse(article.data.url);
  }
  
  if ((lowercase_subreddit == 'gif') || (lowercase_subreddit == 'gifs') || (lowercase_subreddit == 'nsfw_gif') || (lowercase_subreddit == 'nsfw_gifs')) {
    AppAssistant.cloneCard(assistant, {name:"gif",disableSceneScroller:true},{index:0,images:[article.url.url]});
  }
  else {
    AppAssistant.cloneCard(assistant, {name:"image",disableSceneScroller:true},{index:0,images:[article.url.url], articles: [article]});
  }
}

StageAssistant.stages = [];
StageAssistant.current_theme = null;

StageAssistant.switchTheme = function(theme) {
  var appController = Mojo.Controller.getAppController();
  
  for (var i = 0; i < StageAssistant.stages.length; i++) {
    var controller = appController.getStageController(StageAssistant.stages[i]);
    
    if (controller) {
      controller.unloadStylesheet(StageAssistant.current_theme);
      controller.loadStylesheet(theme);
    }
  }
  
  StageAssistant.current_theme = theme;
}

StageAssistant.setTheme = function(assistant) {
  if (StageAssistant.current_theme == undefined) {
    StageAssistant.current_theme = StageAssistant.cookieValue("prefs-theme", "stylesheets/reddit-dark.css");
  }
  
  Mojo.loadStylesheet(assistant.controller.document, StageAssistant.current_theme);
}

StageAssistant.parseUrls = function(text){
  if ((!text) || (text.indexOf('http') < 0)) {
    return null;
  }

  var urls = text.match(/([^\[])*https?:\/\/([-\w\.]+)+(:\d+)?(\/([\w-/_\.]*(\?\S+)?)?)?/g);

  if (urls) {
    for (var i = 0; i < urls.length; i++) {
      if (urls[i].indexOf(')') >= 0) {
        urls[i] = urls[i].substr(0, urls[i].indexOf(')'));
      }

      urls[i] = Linky.parse(urls[i].substr(urls[i].indexOf('http'), urls[i].length));
    }
    
  }

  return urls;
}

StageAssistant.parseImageUrls = function(text){
  var urls = StageAssistant.parseUrls(text);

  if (urls == null) {
    return null;
  }

  var images = [];
  
  for (var j = 0; j < urls.length; j++) {
    if (urls[j].type == 'image') {
      images.push(urls[j].url);
    }
  }

  return images;
}

StageAssistant.timeFormatter = function(time) {  
  var newDate = new Date();

  var lapsed = newDate.getTime() / 1000 - time;
  var units = Math.floor(lapsed / 60);

  if (units < 60) {
    return (units == 1) ? units.toString() + ' minute ago' : units.toString() + ' minutes ago';
  }

  units = Math.floor(units / 60);

  if (units < 24) {
    return (units == 1) ? units.toString() + ' hour ago' : units.toString() + ' hours ago';
  }

  units = Math.floor(units / 24);

  return (units == 1) ? units.toString() + ' day ago' : units.toString() + ' days ago';
}

StageAssistant.scoreFormatter = function(model) {
  return (model.data.ups - model.data.downs) + " points";
}

StageAssistant.defaultWindowOrientation = function(assistant, orientation) {
  var value = StageAssistant.cookieValue("prefs-lock-orientation", "off");
  
  if (value == "on") {
    assistant.controller.stageController.setWindowOrientation("up");
  }
  else {
    assistant.controller.stageController.setWindowOrientation(orientation);
  }
}
