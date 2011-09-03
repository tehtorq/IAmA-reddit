
MessageAssistant = Class.create({
  initialize: function(action) {
    this.listModel = { items : [] };
  },

  setup: function() {
    StageAssistant.setTheme(this);
    
    this.controller.setupWidget("spinner",
      this.attributes = {},
      this.model = {spinning: true}
    ); 
    
    this.controller.setupWidget('sub-menu', null, {items: [
      {label:$L("all"), command:$L("message inbox")},
      {label:$L("unread"), command:$L("message unread")},
      {label:$L("messages"), command:$L("message messages")},
      {label:$L("comment replies"), command:$L("message comments")},
      {label:$L("post replies"), command:$L("message selfreply")},
      {label:$L("sent"), command:$L("message sent")}
    ]});
    
    this.viewMenuModel = {
      visible: true,
      items: [
          {items:[{},
                  { label: 'inbox', command: 'top', icon: "", width: Mojo.Environment.DeviceInfo.screenWidth - 60},
                  {icon:'search', submenu: "sub-menu", width: 60},
                  {}]}
      ]
    };
    
    this.controller.setupWidget(Mojo.Menu.viewMenu, { menuClass:'no-fade' }, this.viewMenuModel);
    
    this.controller.setupWidget("contentarea", {
    itemTemplate : "message/list-item",
    emptyTemplate : "message/emptylist",
    formatters: {time: this.timeFormatter.bind(this),
                 description: this.descriptionFormatter.bind(this)}
    }, this.listModel);

    /* add event handlers to listen to events from widgets */

    this.controller.listen("contentarea", Mojo.Event.listTap, this.itemTapped.bind(this));  
  },

  activate: function(event) {
    StageAssistant.defaultWindowOrientation(this, "free");

    this.loadMessages('inbox');
  },

  deactivate: function(event) {},

  cleanup: function(event) {},
  
  timeFormatter: function(propertyValue, model) {
    if ((model.kind != 't1') && (model.kind != 't3') && (model.kind != 't4')) {
      return "";
    }
    
    return StageAssistant.timeFormatter(model.data.created_utc);
  },
  
  descriptionFormatter: function(propertyValue, model) {
     if ((model.kind != 't1') && (model.kind != 't3') && (model.kind != 't4')) {
      return "";
    }
    
    var desc = "";
    
    if (model.kind == 't1') {
      desc = "from <b>" + model.data.author + "</b> via " + model.data.subreddit + " sent " + StageAssistant.timeFormatter(model.data.created_utc);
    }
    else {
      desc = "from <b>" + model.data.author + "</b> sent " + StageAssistant.timeFormatter(model.data.created_utc);
    }
    
    return desc;
  },
  
  handleCallback: function(params) {
    if (!params || !params.success) {
      return params;
    }

    if ((params.type == "message-inbox") ||
        (params.type == "message-unread") ||
        (params.type == "message-messages") ||
        (params.type == "message-comments") ||
        (params.type == "message-selfreply") ||
        (params.type == "message-sent")) {
      this.handleMessagesResponse(params.response);
    }
  },
  
  loadMessages: function(type) {
    this.spinSpinner(true);
    this.listModel.items.clear();
    this.controller.modelChanged(this.listModel);
    
    switch (type) {
      case 'inbox':
        new Message(this).inbox({mark: true});
        break;
      case 'unread':
        new Message(this).unread({mark: true});
        break;
      case 'messages':
        new Message(this).messages({});
        break;
      case 'comments':
        new Message(this).comments({});
        break;
      case 'selfreply':
        new Message(this).selfreply({});
        break;
      case 'sent':
        new Message(this).sent({});
        break;
    }  
  },

  handleMessagesResponse: function(response) {
    this.spinSpinner(false);
    Mojo.Log.info("readystate => " + response.readyState);
    if (response.readyState != 4) {
      return;
    }
    Mojo.Log.info("handle response!");
    new Debugger().debug(response.responseJSON.data.children[0].data);
//    var myObj = response.responseJSON;
//    
//    var data = myObj.data;
    var children = response.responseJSON.data.children;

    for (var j = 0; j < children.length; j++) {      
      var child = children[j]
      child.data.body_html = child.data.body_html.unescapeHTML();
      this.listModel.items.push(child);
    }

    this.controller.modelChanged(this.listModel);
  },

  itemTapped: function(event) {
    var item = event.item;
    
    
    //this.controller.stageController.pushScene({name:"user"},{linky:item.item["author"]});
  },
  
  scrollToTop: function() {
    this.controller.getSceneScroller().mojo.scrollTo(0,0, true);
  },
  
  handleCommand: function(event) {
    if (event.type != Mojo.Event.command) {
      return;
    }
    
    var params = event.command.split(' ');
    
    switch (params[0]) {
      case 'top':
        this.scrollToTop();
        break;
      case 'message':
        this.loadMessages(params[1]);
        break;
    }
  },
  
  spinSpinner: function(bool) {
    if (bool) {
      this.controller.get('loading').show();
    }
    else {
      this.controller.get('loading').hide();
    }
  }
  
});
