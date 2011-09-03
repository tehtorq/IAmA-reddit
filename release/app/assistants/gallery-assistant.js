
GalleryAssistant = Class.create({

  initialize: function(params) {
    this.image_limit = 20;
    this.fetching_images = false;
    this.last_article_id = null;
    this.sr = 'pics';
  },

  handleCallback: function(params) {
    if (!params || !params.success) {
      return params;
    }

    if (params.type == "article-list") {
      this.handleLoadArticlesResponse(params.response);
    }
  },

  setup: function() {
    StageAssistant.setTheme(this);
    
    var sfw_reddits = ['1000words','aviation','battlestations','gifs','itookapicture','photocritique','pics','vertical','wallpaper','wallpapers','windowshots'];    
    var sfw_reddits_items = [];
                       
    for (var i = 0; i < sfw_reddits.length; i++) {
      sfw_reddits_items.push({label: sfw_reddits[i], command: 'subreddit ' + sfw_reddits[i]});
    }

    this.subredditSubmenuModel = {items: sfw_reddits_items};

    this.controller.setupWidget('subreddit-submenu', null, this.subredditSubmenuModel);
    
    this.viewMenuModel = {
      visible: true,
      items: [
          {items:[{},
                  { label: '', submenu: "category-submenu", width: 60},
                  { label: "Reddit", command: 'new-card', icon: "", width: Mojo.Environment.DeviceInfo.screenWidth - 120},
                  { label: '', submenu: "subreddit-submenu", icon: "search", width: 60},
                  {}]}
      ]
    };

    this.controller.setupWidget(Mojo.Menu.viewMenu, { menuClass:'palm-dark no-fade' }, this.viewMenuModel);

    this.thumbs = [];

    this.activityButtonModel = {label : "Load more"};
    this.controller.setupWidget("loadMoreButton", {type:Mojo.Widget.activityButton}, this.activityButtonModel);

    /* add event handlers to listen to events from widgets */
    
    this.loadImagesBind = this.loadImages.bind(this);
    this.handleTapBind = this.handleTap.bind(this);

    Mojo.Event.listen(this.controller.get("gallery"), Mojo.Event.tap, this.handleTapBind);
    Mojo.Event.listen(this.controller.get("loadMoreButton"), Mojo.Event.tap, this.loadImagesBind);
  },

  activate: function(event) {
    StageAssistant.defaultWindowOrientation(this, "free");
    this.loadImages();
  },

  deactivate: function(event) {
    
  },

  cleanup: function(event) {
    Request.clear_all();
    
    Mojo.Event.stopListening(this.controller.get("gallery"), Mojo.Event.tap, this.handleTapBind);
    Mojo.Event.stopListening(this.controller.get("loadMoreButton"), Mojo.Event.tap, this.loadImagesBind);
  },

  orientationChanged: function (orientation) {
    this.controller.stageController.setWindowOrientation(orientation);
  },

  handleTap: function(event) {
    var element_tapped = event.target;

    if (element_tapped && element_tapped.alt) {      
      var image_array = [];
      var articles = [];
      
      for (var i = 0; i < this.thumbs.length; i++) {
        image_array.push(this.thumbs[i].url.url);
        articles.push(this.thumbs[i]);
      }
      
      AppAssistant.cloneCard(this, {name:"image",disableSceneScroller:true},{index:parseInt(element_tapped.alt),images:image_array, articles:articles});
    }
  },

  storeThumb: function(reddit_article){
    var url = reddit_article.data.url;

    if ((url.indexOf('.jpg') >= 0) ||
        (url.indexOf('.jpeg') >= 0) ||
        (url.indexOf('.png') >= 0) ||
        (url.indexOf('.gif') >= 0) ||
        (url.indexOf('.bmp') >= 0)) {

      var thumb_url = reddit_article.data.thumbnail;

      if (thumb_url.indexOf('/static/') != -1) {
        thumb_url = 'http://reddit.com' + thumb_url;
      }

      this.thumbs.push(reddit_article);
  
      var mydiv = this.controller.document.createElement('img');
      mydiv.setAttribute('src', thumb_url);
      mydiv.setAttribute('alt', this.thumbs.length - 1);
      mydiv.setAttribute('style', 'max-height: 80px;border: solid 1px black; margin: 2px; padding: 2px;');
      mydiv.setAttribute('align', 'middle');

      this.controller.get('gallery').appendChild(mydiv);
    }
  },

  displayLoadingButton: function() {
    this.controller.get('loadMoreButton').mojo.activate();
    this.activityButtonModel.label = "Loading";
    this.activityButtonModel.disabled = true;
    this.controller.modelChanged(this.activityButtonModel);
  },

  displayLoadMoreButton: function() {
    this.controller.get('loadMoreButton').mojo.deactivate();
    this.activityButtonModel.label = "Load more";
    this.activityButtonModel.disabled = false;
    this.controller.modelChanged(this.activityButtonModel);
  },

  handleLoadArticlesResponse: function(response) {
    this.displayLoadMoreButton();
    var myObj = response.responseJSON;
    var data = myObj.data;
    var items = data.children;  

    for (var i = 0; i < items.length; i++) {
      var d = items[i].data;
      var reddit_article = new Article().load(d);
      this.last_article_id = reddit_article.data.name;

      if (reddit_article.hasThumbnail()) {
        this.storeThumb(reddit_article);
      }
    }

    this.fetching_images = false;
  },
  
  clearImages: function() {
    this.controller.getSceneScroller().mojo.scrollTo(0,0, true);
    this.controller.get('gallery').update('');
    this.last_article_id = null;
    this.thumbs.clear();
  },

  loadImages: function() {
    if (this.fetching_images == true) {
      return;
    }

    this.fetching_images = true;
    this.displayLoadingButton();

    var parameters = {};
    parameters.limit = 100;
    
    if (this.last_article_id) {
      parameters.after = this.last_article_id;
    }

    if (this.sr) {
      parameters.sr = this.sr;
    }

    new Article(this).list(parameters);
  },

  switchSubreddit: function(subreddit) {
    if (subreddit == undefined) {
      return;
    }

    this.sr = subreddit;
    this.clearImages();
    this.loadImages();
  },

  handleCommand: function(event) {
    if (event.type != Mojo.Event.command) {
      return;
    }

    if (event.type == Mojo.Event.command) {
      switch (event.command) {
        case 'login-cmd':
          this.controller.stageController.pushScene({name:"login",transition: Mojo.Transition.crossFade});
          break;

        case 'frontpage-cmd':
          this.controller.stageController.popScene({name:"frontpage",disableSceneScroller:true});
          break;
      }
    }

    var params = event.command.split(' ');

    switch (params[0]) {
      case 'subreddit':
        this.switchSubreddit(params[1]);
        break;
    }
  }

});
