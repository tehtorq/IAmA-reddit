
GifAssistant = Class.create({

  initialize: function(params) {
    this.image_array = params.images;
    this.current_index = params.index;
  },

  setup: function() {
    StageAssistant.setTheme(this);
    
    this.cmdMenuModel = {
      visible: false,
      items: [
          {items:[{},
                  { label: (this.current_index + 1) + "/" + this.image_array.length, command: 'top', icon: "", width: Mojo.Environment.DeviceInfo.screenWidth - 180},
                  {label: $L('Save'), icon:'save', command:'save'},                  
                  {}]}
      ]
    };

    this.controller.setupWidget(Mojo.Menu.commandMenu, { menuClass:'palm-dark' }, this.cmdMenuModel);
    this.handleTapBind = this.handleTap.bind(this);

    /* add event handlers to listen to events from widgets */

    Mojo.Event.listen(this.controller.get('wrappertest'), Mojo.Event.tap, this.handleTapBind);
  },

  activate: function(event) {
    StageAssistant.defaultWindowOrientation(this, "up");
    
    var mydiv = this.controller.document.createElement('img');
    mydiv.setAttribute('src', this.image_array[0]);
    mydiv.setAttribute('alt', this.image_array[0]);
    mydiv.setAttribute('style', 'max-width: 320px;');
    //mydiv.setAttribute('align', 'middle');

    this.controller.get('centered').appendChild(mydiv);
  },

  ready: function() {},

  deactivate: function(event) {},

  cleanup: function(event) {
    Mojo.Event.stopListening(this.controller.get('wrappertest'), Mojo.Event.tap, this.handleTapBind);
  },

  handleCommand: function(event) {
    if (event.type == Mojo.Event.command) {
      switch (event.command) {
        case 'save':
          this.download(this.urlForIndex(this.current_index));
          break;
      }
    }
  },

  handleTap: function() {
    this.cmdMenuModel.visible = !this.cmdMenuModel.visible;
    this.controller.modelChanged(this.cmdMenuModel);
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


