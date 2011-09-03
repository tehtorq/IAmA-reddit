
ImageAssistant = Class.create({

  initialize: function(params) {
    this.image_array = params.images;
    this.article_array = params.articles;
    this.current_index = params.index;
    
    if (params.articles == undefined) {
      this.article_array = [];
    }
    else {
      this.article_array = params.articles;
    }
  },

  setup: function() {
    StageAssistant.setTheme(this);
    
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
      
    var command_menu_items;
    
    if (this.article_array.length > 0) {
      command_menu_items = [{},
        {label: $L('Back'), icon:'back', command:'back'},
        {label: $L('Article'), icon:'info', command:'article'},
        { label: (this.current_index + 1) + "/" + this.image_array.length, command: 'top', icon: "", width: Mojo.Environment.DeviceInfo.screenWidth - 240},
        {label: $L('Save'), icon:'save', command:'save'},
        {label: $L('Forward'), icon:'forward', command:'forward'},
        {}];     
    }
    else {
      command_menu_items = [{},
        {label: $L('Back'), icon:'back', command:'back'},
        { label: (this.current_index + 1) + "/" + this.image_array.length, command: 'top', icon: "", width: Mojo.Environment.DeviceInfo.screenWidth - 180},
        {label: $L('Save'), icon:'save', command:'save'},
        {label: $L('Forward'), icon:'forward', command:'forward'},
        {}];
    }

    this.cmdMenuModel = {
      visible: false,
      items: [{items: command_menu_items}]
    };

    this.controller.setupWidget(Mojo.Menu.commandMenu, { menuClass:'palm-dark' }, this.cmdMenuModel);

    this.changedImageBind = this.changedImage.bindAsEventListener(this);
    this.windowResizeBind = this.handleWindowResize.bindAsEventListener(this);
    this.handleTapBind = this.handleTap.bindAsEventListener(this);

    Mojo.Event.listen(this.controller.get('ImageId'), Mojo.Event.imageViewChanged, this.changedImageBind);
    Mojo.Event.listen(this.controller.get('wrappertest'), Mojo.Event.tap, this.handleTapBind);
    Mojo.Event.listen(this.controller.window, 'resize', this.windowResizeBind, false);
  },

  activate: function(event) {
    this.controller.get('image_title').hide();
    StageAssistant.defaultWindowOrientation(this, "free");
    this.spinSpinner(true);
    this.updateUrls(0);
  },

  ready: function() {
    this.controller.get('ImageId').mojo.manualSize(Mojo.Environment.DeviceInfo.screenWidth,Mojo.Environment.DeviceInfo.screenHeight);
  },

  deactivate: function(event) {
    
  },

  cleanup: function(event) {
    Mojo.Event.stopListening(this.controller.get('ImageId'), Mojo.Event.imageViewChanged, this.changedImageBind);
    Mojo.Event.stopListening(this.controller.get('wrappertest'), Mojo.Event.tap, this.handleTapBind);
    Mojo.Event.stopListening(this.controller.window, 'resize', this.windowResizeBind, false);
  },

  changedImage: function(){
    this.spinSpinner(false);
  },
  
  spinSpinner: function(bool) {
    if (bool) {
      this.controller.get('loading').show();
    }
    else {
      this.controller.get('loading').hide();
    }
  },

  handleWindowResize: function(event){
    this.controller.get('ImageId').mojo.manualSize(this.controller.window.innerWidth, this.controller.window.innerHeight);
  },

  handleCommand: function(event) {
    if (event.type == Mojo.Event.command) {
      switch (event.command) {
        case 'save':
          this.download(this.urlForIndex(this.current_index));
          break;
        case 'article':
          AppAssistant.cloneCard(this, {name:"article"}, {article: {kind: 't3', data: this.article_array[this.current_index].data}});
          break;
        case 'back':
          this.spinSpinner(true);
          this.updateUrls(-1);
          break;
        case 'forward':
          this.spinSpinner(true);
          this.updateUrls(1);
          break;
      }
    }
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

    if (this.article_array.length > 0) {
      this.cmdMenuModel.items[0].items[3].label = (this.current_index + 1) + "/" + this.image_array.length;
      this.cmdMenuModel.items[0].items[1].disabled = (this.current_index == 0);
      this.cmdMenuModel.items[0].items[5].disabled = (this.current_index == (this.image_array.length - 1));      
    }
    else {
      this.cmdMenuModel.items[0].items[2].label = (this.current_index + 1) + "/" + this.image_array.length;
      this.cmdMenuModel.items[0].items[1].disabled = (this.current_index == 0);
      this.cmdMenuModel.items[0].items[4].disabled = (this.current_index == (this.image_array.length - 1));
    }
    
    this.controller.modelChanged(this.cmdMenuModel);

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
    
    this.controller.get('image_title').update(this.article_array[this.current_index].data.title);
  },

  handleTap: function() {
    this.cmdMenuModel.visible = !this.cmdMenuModel.visible;
    this.controller.modelChanged(this.cmdMenuModel);
    this.controller.get('image_title').toggle();
  },

  download: function(filename) {
    var name = filename.substring(filename.lastIndexOf('/') + 1);

    try {
      this.controller.serviceRequest('palm://com.palm.downloadmanager/', {
        method: 'download',
        parameters:
        {
          target: filename,
          targetDir : "/media/internal/reddit_downloads/",
          keepFilenameOnRedirect: false,
          subscribe: true
        },
        onSuccess : function (response){
          if (response.completed == true) {
            new Banner("Saved image " + name).send();
          }
        }.bind(this)
      });
    }
    catch (e) {

    }
  }

});


