var GalleryAssistant;
var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
GalleryAssistant = (function() {
  function GalleryAssistant(params) {
    this.image_limit = 20;
    this.fetching_images = false;
    this.last_article_id = null;
    this.sr = 'pics';
  }
  GalleryAssistant.prototype.handleCallback = function(params) {
    if (!((params != null) && params.success)) {
      return params;
    }
    if (params.type === "article-list") {
      return this.handleLoadArticlesResponse(params.response);
    }
  };
  GalleryAssistant.prototype.setup = function() {
    var sfw_reddits, sfw_reddits_items;
    StageAssistant.setTheme(this);
    sfw_reddits = ['1000words', 'aviation', 'battlestations', 'gifs', 'itookapicture', 'photocritique', 'pics', 'vertical', 'wallpaper', 'wallpapers', 'windowshots'];
    sfw_reddits_items = [];
    _.each(sfw_reddits, function(item) {
      return sfw_reddits_items.push({
        label: item,
        command: 'subreddit ' + item
      });
    });
    this.subredditSubmenuModel = {
      items: sfw_reddits_items
    };
    this.controller.setupWidget('subreddit-submenu', null, this.subredditSubmenuModel);
    this.viewMenuModel = {
      visible: true,
      items: [
        {
          items: [
            {}, {
              label: '',
              submenu: "category-submenu",
              width: 60
            }, {
              label: "Reddit",
              command: 'new-card',
              icon: "",
              width: Mojo.Environment.DeviceInfo.screenWidth - 120
            }, {
              label: '',
              submenu: "subreddit-submenu",
              icon: "search",
              width: 60
            }, {}
          ]
        }
      ]
    };
    this.controller.setupWidget(Mojo.Menu.viewMenu, {
      menuClass: 'palm-dark no-fade'
    }, this.viewMenuModel);
    this.thumbs = [];
    this.activityButtonModel = {
      label: "Load more"
    };
    this.controller.setupWidget("loadMoreButton", {
      type: Mojo.Widget.activityButton
    }, this.activityButtonModel);
    this.loadImagesBind = this.loadImages.bind(this);
    this.handleTapBind = this.handleTap.bind(this);
    Mojo.Event.listen(this.controller.get("gallery"), Mojo.Event.tap, this.handleTapBind);
    return Mojo.Event.listen(this.controller.get("loadMoreButton"), Mojo.Event.tap, this.loadImagesBind);
  };
  GalleryAssistant.prototype.activate = function(event) {
    StageAssistant.defaultWindowOrientation(this, "free");
    return this.loadImages();
  };
  GalleryAssistant.prototype.deactivate = function(event) {};
  GalleryAssistant.prototype.cleanup = function(event) {
    Request.clear_all();
    Mojo.Event.stopListening(this.controller.get("gallery"), Mojo.Event.tap, this.handleTapBind);
    return Mojo.Event.stopListening(this.controller.get("loadMoreButton"), Mojo.Event.tap, this.loadImagesBind);
  };
  GalleryAssistant.prototype.orientationChanged = function(orientation) {
    return this.controller.stageController.setWindowOrientation(orientation);
  };
  GalleryAssistant.prototype.handleTap = function(event) {
    var articles, element_tapped, image_array;
    element_tapped = event.target;
    if ((element_tapped != null) && (element_tapped.alt != null)) {
      image_array = [];
      articles = [];
      _.each(this.thumbs, function(thumb) {
        image_array.push(thumb.url.url);
        return articles.push(thumb);
      });
      return AppAssistant.cloneCard(this, {
        name: "image",
        disableSceneScroller: true
      }, {
        index: parseInt(element_tapped.alt),
        images: image_array,
        articles: articles
      });
    }
  };
  GalleryAssistant.prototype.storeThumb = function(reddit_article) {
    var mydiv, thumb_url, url;
    url = reddit_article.data.url;
    if ((url.indexOf('.jpg') >= 0) || (url.indexOf('.jpeg') >= 0) || (url.indexOf('.png') >= 0) || (url.indexOf('.gif') >= 0) || (url.indexOf('.bmp') >= 0)) {
      thumb_url = reddit_article.data.thumbnail;
      if (thumb_url.indexOf('/static/') !== -1) {
        thumb_url = 'http://reddit.com' + thumb_url;
      }
      this.thumbs.push(reddit_article);
      mydiv = this.controller.document.createElement('img');
      mydiv.setAttribute('src', thumb_url);
      mydiv.setAttribute('alt', this.thumbs.length - 1);
      mydiv.setAttribute('style', 'max-height: 80px;border: solid 1px black; margin: 2px; padding: 2px;');
      mydiv.setAttribute('align', 'middle');
      return this.controller.get('gallery').appendChild(mydiv);
    }
  };
  GalleryAssistant.prototype.displayLoadingButton = function() {
    this.controller.get('loadMoreButton').mojo.activate();
    this.activityButtonModel.label = "Loading";
    this.activityButtonModel.disabled = true;
    return this.controller.modelChanged(this.activityButtonModel);
  };
  GalleryAssistant.prototype.displayLoadMoreButton = function() {
    this.controller.get('loadMoreButton').mojo.deactivate();
    this.activityButtonModel.label = "Load more";
    this.activityButtonModel.disabled = false;
    return this.controller.modelChanged(this.activityButtonModel);
  };
  GalleryAssistant.prototype.handleLoadArticlesResponse = function(response) {
    var data, items, myObj;
    this.displayLoadMoreButton();
    myObj = response.responseJSON;
    data = myObj.data;
    items = data.children;
    _.each(items, __bind(function(item) {
      var d, reddit_article;
      d = item.data;
      reddit_article = new Article().load(d);
      this.last_article_id = reddit_article.data.name;
      if (reddit_article.hasThumbnail()) {
        return this.storeThumb(reddit_article);
      }
    }, this));
    return this.fetching_images = false;
  };
  GalleryAssistant.prototype.clearImages = function() {
    this.controller.getSceneScroller().mojo.scrollTo(0, 0, true);
    this.controller.get('gallery').update('');
    this.last_article_id = null;
    return this.thumbs.clear();
  };
  GalleryAssistant.prototype.loadImages = function() {
    var parameters;
    if (this.fetching_images) {
      return;
    }
    this.fetching_images = true;
    this.displayLoadingButton();
    parameters = {};
    parameters.limit = 100;
    if (this.last_article_id != null) {
      parameters.after = this.last_article_id;
    }
    if (this.sr != null) {
      parameters.sr = this.sr;
    }
    return new Article(this).list(parameters);
  };
  GalleryAssistant.prototype.switchSubreddit = function(subreddit) {
    if (subreddit == null) {
      return;
    }
    this.sr = subreddit;
    this.clearImages();
    return this.loadImages();
  };
  GalleryAssistant.prototype.handleCommand = function(event) {
    var params;
    if (event.type !== Mojo.Event.command) {
      return;
    }
    switch (event.command) {
      case 'login-cmd':
        this.controller.stageController.pushScene({
          name: "login",
          transition: Mojo.Transition.crossFade
        });
        break;
      case 'frontpage-cmd':
        this.controller.stageController.popScene({
          name: "frontpage",
          disableSceneScroller: true
        });
    }
    params = event.command.split(' ');
    switch (params[0]) {
      case 'subreddit':
        return this.switchSubreddit(params[1]);
    }
  };
  return GalleryAssistant;
})();