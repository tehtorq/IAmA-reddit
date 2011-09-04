var DockAssistant;
var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
DockAssistant = (function() {
  function DockAssistant(params) {
    this.image_array = [];
    this.article_array = [];
    this.current_index = 0;
    this.fetching_images = false;
    this.last_article_id = null;
    this.sr = 'pics';
  }
  DockAssistant.prototype.setup = function() {
    this.controller.enableFullScreenMode(true);
    this.controller.setupWidget("spinner", this.attributes = {}, this.model = {
      spinning: true
    });
    this.controller.setupWidget("ImageId", this.attributes = {
      noExtractFS: true
    }, this.model = {
      onLeftFunction: __bind(function() {
        return this.updateUrls(-1);
      }, this),
      onRightFunction: __bind(function() {
        return this.updateUrls(1);
      }, this)
    });
    return this.loadImagesBind = this.loadImages.bind(this);
  };
  DockAssistant.prototype.activate = function(event) {
    StageAssistant.defaultWindowOrientation(this, "free");
    return this.timerID = this.controller.window.setInterval(this.tick.bind(this), 15000);
  };
  DockAssistant.prototype.ready = function() {
    return this.controller.get('ImageId').mojo.manualSize(Mojo.Environment.DeviceInfo.screenWidth, Mojo.Environment.DeviceInfo.screenHeight);
  };
  DockAssistant.prototype.deactivate = function(event) {
    this.controller.enableFullScreenMode(false);
    return this.controller.window.clearInterval(this.timerID);
  };
  DockAssistant.prototype.cleanup = function(event) {
    return Request.clear_all();
  };
  DockAssistant.prototype.tick = function() {
    this.updateUrls(1);
    if ((this.image_array.length - this.current_index) < 10) {
      return this.loadImages();
    }
  };
  DockAssistant.prototype.orientationChanged = function(orientation) {
    return this.controller.stageController.setWindowOrientation(orientation);
  };
  DockAssistant.prototype.handleLoadArticlesResponse = function(response) {
    var children;
    children = response.responseJSON.data.children;
    _.each(children, __bind(function(child) {
      var d, reddit_article, url;
      d = child.data;
      reddit_article = new Article().load(d);
      this.last_article_id = reddit_article.data.name;
      url = reddit_article.data.url;
      if ((url.indexOf('.jpg') >= 0) || (url.indexOf('.jpeg') >= 0) || (url.indexOf('.png') >= 0) || (url.indexOf('.gif') >= 0) || (url.indexOf('.bmp') >= 0)) {
        this.article_array.push({
          data: reddit_article.data,
          kind: 't3'
        });
        return this.image_array.push(url);
      }
    }, this));
    this.spinSpinner(false);
    return this.fetching_images = false;
  };
  DockAssistant.prototype.spinSpinner = function(bool) {
    if (bool) {
      return this.controller.get('loading').show();
    } else {
      return this.controller.get('loading').hide();
    }
  };
  DockAssistant.prototype.clearImages = function() {
    this.controller.getSceneScroller().mojo.scrollTo(0, 0, true);
    this.controller.get('gallery').update('');
    this.last_article_id = null;
    return this.thumbs.clear();
  };
  DockAssistant.prototype.loadImages = function() {
    var parameters;
    if (this.fetching_images) {
      return;
    }
    this.fetching_images = true;
    this.spinSpinner(true);
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
  DockAssistant.prototype.urlForIndex = function(index) {
    if (index < 0) {
      return null;
      index += this.image_array.length;
    } else if (index >= this.image_array.length) {
      return null;
      index -= this.image_array.length;
    }
    return this.image_array[index];
  };
  DockAssistant.prototype.updateUrls = function(delta) {
    var image, new_index;
    new_index = this.current_index + delta;
    if ((new_index < 0) || (new_index >= this.image_array.length)) {
      return;
    }
    this.current_index = new_index;
    image = this.controller.get('ImageId');
    if ((this.current_index > -1) && (this.current_index < this.image_array.length)) {
      image.mojo.centerUrlProvided(this.urlForIndex(this.current_index));
    }
    if ((this.current_index > 0) && (this.current_index < this.image_array.length)) {
      image.mojo.leftUrlProvided(this.urlForIndex(this.current_index - 1));
    }
    if ((this.current_index > -1) && (this.current_index < (this.image_array.length - 1))) {
      return image.mojo.rightUrlProvided(this.urlForIndex(this.current_index + 1));
    }
  };
  DockAssistant.prototype.handleCallback = function(params) {
    if (!((params != null) && params.success)) {
      return params;
    }
    if (params.type === "article-list") {
      return this.handleLoadArticlesResponse(params.response);
    }
  };
  DockAssistant.prototype.handleWindowResize = function(event) {
    return this.controller.get('ImageId').mojo.manualSize(this.controller.window.innerWidth, this.controller.window.innerHeight);
  };
  return DockAssistant;
})();