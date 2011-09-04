var ImageAssistant;
var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
ImageAssistant = (function() {
  function ImageAssistant(params) {
    this.image_array = params.images;
    this.article_array = params.articles;
    this.current_index = params.index;
    if (params.articles != null) {
      this.article_array = params.articles;
    } else {
      this.article_array = [];
    }
  }
  ImageAssistant.prototype.setup = function() {
    var command_menu_items;
    StageAssistant.setTheme(this);
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
    command_menu_items = null;
    if (this.article_array.length > 0) {
      command_menu_items = [
        {}, {
          label: $L('Back'),
          icon: 'back',
          command: 'back'
        }, {
          label: $L('Article'),
          icon: 'info',
          command: 'article'
        }, {
          label: (this.current_index + 1) + "/" + this.image_array.length,
          command: 'top',
          icon: "",
          width: Mojo.Environment.DeviceInfo.screenWidth - 240
        }, {
          label: $L('Save'),
          icon: 'save',
          command: 'save'
        }, {
          label: $L('Forward'),
          icon: 'forward',
          command: 'forward'
        }, {}
      ];
    } else {
      command_menu_items = [
        {}, {
          label: $L('Back'),
          icon: 'back',
          command: 'back'
        }, {
          label: (this.current_index + 1) + "/" + this.image_array.length,
          command: 'top',
          icon: "",
          width: Mojo.Environment.DeviceInfo.screenWidth - 180
        }, {
          label: $L('Save'),
          icon: 'save',
          command: 'save'
        }, {
          label: $L('Forward'),
          icon: 'forward',
          command: 'forward'
        }, {}
      ];
    }
    this.cmdMenuModel = {
      visible: false,
      items: [
        {
          items: command_menu_items
        }
      ]
    };
    this.controller.setupWidget(Mojo.Menu.commandMenu, {
      menuClass: 'palm-dark'
    }, this.cmdMenuModel);
    this.changedImageBind = this.changedImage.bindAsEventListener(this);
    this.windowResizeBind = this.handleWindowResize.bindAsEventListener(this);
    this.handleTapBind = this.handleTap.bindAsEventListener(this);
    Mojo.Event.listen(this.controller.get('ImageId'), Mojo.Event.imageViewChanged, this.changedImageBind);
    Mojo.Event.listen(this.controller.get('wrappertest'), Mojo.Event.tap, this.handleTapBind);
    return Mojo.Event.listen(this.controller.window, 'resize', this.windowResizeBind, false);
  };
  ImageAssistant.prototype.activate = function(event) {
    this.controller.get('image_title').hide();
    StageAssistant.defaultWindowOrientation(this, "free");
    this.spinSpinner(true);
    return this.updateUrls(0);
  };
  ImageAssistant.prototype.ready = function() {
    return this.controller.get('ImageId').mojo.manualSize(Mojo.Environment.DeviceInfo.screenWidth, Mojo.Environment.DeviceInfo.screenHeight);
  };
  ImageAssistant.prototype.deactivate = function(event) {};
  ImageAssistant.prototype.cleanup = function(event) {
    Mojo.Event.stopListening(this.controller.get('ImageId'), Mojo.Event.imageViewChanged, this.changedImageBind);
    Mojo.Event.stopListening(this.controller.get('wrappertest'), Mojo.Event.tap, this.handleTapBind);
    return Mojo.Event.stopListening(this.controller.window, 'resize', this.windowResizeBind, false);
  };
  ImageAssistant.prototype.changedImage = function() {
    return this.spinSpinner(false);
  };
  ImageAssistant.prototype.spinSpinner = function(bool) {
    if (bool) {
      return this.controller.get('loading').show();
    } else {
      return this.controller.get('loading').hide();
    }
  };
  ImageAssistant.prototype.handleWindowResize = function(event) {
    return this.controller.get('ImageId').mojo.manualSize(this.controller.window.innerWidth, this.controller.window.innerHeight);
  };
  ImageAssistant.prototype.handleCommand = function(event) {
    if (event.type !== Mojo.Event.command) {
      return;
    }
    switch (event.command) {
      case 'save':
        return this.download(this.urlForIndex(this.current_index));
      case 'article':
        return AppAssistant.cloneCard(this, {
          name: "article"
        }, {
          article: {
            kind: 't3',
            data: this.article_array[this.current_index].data
          }
        });
      case 'back':
        this.spinSpinner(true);
        return this.updateUrls(-1);
      case 'forward':
        this.spinSpinner(true);
        return this.updateUrls(1);
    }
  };
  ImageAssistant.prototype.urlForIndex = function(index) {
    if (index < 0) {
      return null;
      index += this.image_array.length;
    } else if (index >= this.image_array.length) {
      return null;
      index -= this.image_array.length;
    }
    return this.image_array[index];
  };
  ImageAssistant.prototype.updateUrls = function(delta) {
    var image, new_index;
    new_index = this.current_index + delta;
    if (new_index < 0 || new_index >= this.image_array.length) {
      return;
    }
    this.current_index = new_index;
    if (this.article_array.length > 0) {
      this.cmdMenuModel.items[0].items[3].label = (this.current_index + 1) + "/" + this.image_array.length;
      this.cmdMenuModel.items[0].items[1].disabled = this.current_index === 0;
      this.cmdMenuModel.items[0].items[5].disabled = this.current_index === (this.image_array.length - 1);
    } else {
      this.cmdMenuModel.items[0].items[2].label = (this.current_index + 1) + "/" + this.image_array.length;
      this.cmdMenuModel.items[0].items[1].disabled = this.current_index === 0;
      this.cmdMenuModel.items[0].items[4].disabled = this.current_index === (this.image_array.length - 1);
    }
    this.controller.modelChanged(this.cmdMenuModel);
    image = this.controller.get('ImageId');
    if ((this.current_index > -1) && (this.current_index < this.image_array.length)) {
      image.mojo.centerUrlProvided(this.urlForIndex(this.current_index));
    }
    if ((this.current_index > 0) && (this.current_index < this.image_array.length)) {
      image.mojo.leftUrlProvided(this.urlForIndex(this.current_index - 1));
    }
    if ((this.current_index > -1) && (this.current_index < (this.image_array.length - 1))) {
      image.mojo.rightUrlProvided(this.urlForIndex(this.current_index + 1));
    }
    return this.controller.get('image_title').update(this.article_array[this.current_index].data.title);
  };
  ImageAssistant.prototype.handleTap = function() {
    this.cmdMenuModel.visible = !this.cmdMenuModel.visible;
    this.controller.modelChanged(this.cmdMenuModel);
    return this.controller.get('image_title').toggle();
  };
  ImageAssistant.prototype.download = function(filename) {
    var name;
    name = filename.substring(filename.lastIndexOf('/') + 1);
    try {
      return this.controller.serviceRequest('palm://com.palm.downloadmanager/', {
        method: 'download',
        parameters: {
          target: filename,
          targetDir: "/media/internal/reddit_downloads/",
          keepFilenameOnRedirect: false,
          subscribe: true
        },
        onSuccess: __bind(function(response) {
          if (response.completed === true) {
            return new Banner("Saved image " + name).send();
          }
        }, this)
      });
    } catch (e) {

    }
  };
  return ImageAssistant;
})();