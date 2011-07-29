
DockAssistant = Class.create({

  initialize: function(params) {
    this.image_array = [];
    this.article_array = [];
    this.current_index = 0;
    
    this.fetching_images = false;
    this.last_article_id = null;
    this.sr = 'pics';
  },

  setup: function() {
    this.controller.enableFullScreenMode(true);
    
    this.controller.setupWidget("spinner",
      this.attributes = {},
      this.model = {spinning: true}
    ); 
    
    this.controller.setupWidget("ImageId",
        this.attributes = {
            noExtractFS: true
            /*highResolutionLoadTimeout: 3*/
        },
        this.model = {
            onLeftFunction: function(){this.updateUrls(-1);}.bind(this),
            onRightFunction: function(){this.updateUrls(1);}.bind(this)
        }
    );

    /* add event handlers to listen to events from widgets */
    
    this.loadImagesBind = this.loadImages.bind(this);
  },

  activate: function(event) {
    StageAssistant.defaultWindowOrientation(this, "free");
    //this.loadImages();
    this.timerID = this.controller.window.setInterval(this.tick.bind(this),15000);
  },
  
  ready: function() {
    this.controller.get('ImageId').mojo.manualSize(Mojo.Environment.DeviceInfo.screenWidth,Mojo.Environment.DeviceInfo.screenHeight);
  },

  deactivate: function(event) {
    this.controller.enableFullScreenMode(false);
    this.controller.window.clearInterval(this.timerID);
  },

  cleanup: function(event) {
    Request.clear_all();
  },
  
  tick: function() {
    this.updateUrls(1);
    
    if ((this.image_array.length - this.current_index) < 10) {
      this.loadImages();
    }
    
//    var current_seconds = (new Date()).getTime() / 1000;
//    
//    if (this.last_poll_second == undefined) {
//      this.last_poll_second = current_seconds;
//    }
//    
//    if ((current_seconds - this.last_poll_second) > 5) {
//      this.fetchRecentComments();
//    }
//    
//    this.updateList();
  },

  orientationChanged: function (orientation) {
    this.controller.stageController.setWindowOrientation(orientation);
  },

  handleLoadArticlesResponse: function(response) {
    Mojo.Log.info(Object.toJSON(response.responseJSON));
    var myObj = response.responseJSON;
    var data = myObj.data;
    var items = data.children;  

    for (var i = 0; i < items.length; i++) {
      var d = items[i].data;
      var reddit_article = new Article().load(d);
      this.last_article_id = reddit_article.data.name;

      var url = reddit_article.data.url;

      if ((url.indexOf('.jpg') >= 0) ||
        (url.indexOf('.jpeg') >= 0) ||
        (url.indexOf('.png') >= 0) ||
        (url.indexOf('.gif') >= 0) ||
        (url.indexOf('.bmp') >= 0)) {
        
        this.article_array.push({data: reddit_article.data, kind: 't3'});
        this.image_array.push(url);
      }
    }
    
    this.spinSpinner(false);

    //this.updateUrls(0);
    this.fetching_images = false;
  },
  
  spinSpinner: function(bool) {
    if (bool) {
      this.controller.get('loading').show();
    }
    else {
      this.controller.get('loading').hide();
    }
  },
  
  clearImages: function() {
    this.controller.getSceneScroller().mojo.scrollTo(0,0, true);
    this.controller.get('gallery').update('');
    this.last_article_id = null;
    this.thumbs.clear();
  },

  loadImages: function() {
    if (this.fetching_images) {
      return;
    }
    
    this.spinSpinner(true);

    this.fetching_images = true;

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
  
  urlForIndex: function(index) {
    if (index < 0) {
      return null;
      index += this.image_array.length;
    }
    else if (index >= this.image_array.length) {
      return null;
      index -= this.image_array.length;
    }

    return this.image_array[index];
  },

  updateUrls: function(delta) {
    var new_index = this.current_index + delta;

    if ((new_index < 0) || (new_index >= this.image_array.length)) {
      return;
    }

    this.current_index = new_index;

    var image = this.controller.get('ImageId');

    if ((this.current_index > -1) && (this.current_index < this.image_array.length)) {
      image.mojo.centerUrlProvided(this.urlForIndex(this.current_index));
    }

    if ((this.current_index > 0) && (this.current_index < this.image_array.length)) {
      image.mojo.leftUrlProvided(this.urlForIndex(this.current_index-1));
    }

    if ((this.current_index > -1) && (this.current_index < (this.image_array.length-1))) {
      image.mojo.rightUrlProvided(this.urlForIndex(this.current_index+1));
    }
  },
  
  handleCallback: function(params) {
    if (!params || !params.success) {
      return params;
    }

    if (params.type == "article-list") {
      this.handleLoadArticlesResponse(params.response);
    }
  },
  
  handleWindowResize: function(event){
    this.controller.get('ImageId').mojo.manualSize(this.controller.window.innerWidth, this.controller.window.innerHeight);
  }

  
  

});
