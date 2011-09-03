
UserAssistant = Class.create({

  initialize: function(url) {
    this.user = url.linky;
    this.url = 'http://reddit.com/user/' + this.user + '.json';
  },

  listModel: { items : [] },

  setup: function() {
    StageAssistant.setTheme(this);
    
    this.viewMenuModel = {
      visible: true,
      items: [
          {items:[{},
                  { label: "overview for " + this.user, command: 'top', icon: "", width: Mojo.Environment.DeviceInfo.screenWidth},
                  {}]}
      ]
    };

    this.controller.setupWidget(Mojo.Menu.viewMenu, { menuClass:'no-fade' }, this.viewMenuModel);

    this.controller.setupWidget("list", {
    itemTemplate : "user/list-item",
    formatters: {title: this.titleFormatter.bind(this),
                 content: this.contentFormatter.bind(this),
                 description: this.descriptionFormatter.bind(this)}
    }, this.listModel);

    /* add event handlers to listen to events from widgets */

    this.itemTappedBind = this.itemTapped.bind(this);
    Mojo.Event.listen(this.controller.get("list"), Mojo.Event.listTap, this.itemTappedBind);

  },

  activate: function(event) {
    StageAssistant.defaultWindowOrientation(this, "free");
    this.listModel.items.clear();
    this.controller.modelChanged(this.listModel);

    this.about();
    this.fetchComments();
  },

  deactivate: function(event) {},

  cleanup: function(event) {
    Mojo.Event.stopListening(this.controller.get("list"), Mojo.Event.listTap, this.itemTappedBind);
  },

  titleFormatter: function(propertyValue, model) {
    //return Object.toJSON(model);
    if (model.kind == 't1') {
      return model.data.link_title;
    }
    else if (model.kind == 't3') {
      return model.data.title;
    }

    return "";
  },

  contentFormatter: function(propertyValue, model) {
    if (model.kind == 't1') {
      return model.data.body;
    }
    else if (model.kind == 't3') {
      return model.data.selftext;
    }

    return "";
  },

  descriptionFormatter: function(propertyValue, model) {
    if (model.kind == 't1') {
      return StageAssistant.scoreFormatter(model) + " " + StageAssistant.timeFormatter(model.data.created_utc);
    }
    else if (model.kind == 't3') {
      return "submitted " + StageAssistant.timeFormatter(model.data.created_utc) + " to " + model.data.subreddit;
    }

    return "";
  },

  handleCommand: function(event) {
    if (event.type == Mojo.Event.command) {
      switch (event.command) {
        case 'top':
          this.scrollToTop();
          break;
      }
    }
  },

  scrollToTop: function() {
    this.controller.getSceneScroller().mojo.scrollTo(0,0, true);
  },

  handleCallback: function(params) {
    if (!params || !params.success) {
      return params;
    }

    if (params.type == "user-comments") {
      this.handleUserCommentsResponse(params.response);
    }
    else if (params.type == "user-about") {
      this.handleUserAboutResponse(params.response);
    }
  },

  fetchComments: function() {
    var params = {user: this.user};

    new User(this).comments(params);
  },

  about: function() {
    var params = {user: this.user};

    new User(this).about(params);
  },

  handleUserCommentsResponse: function(response) {
    var myObj = response.responseJSON;

    var children = myObj.data.children;

    for (var j = 0; j < children.length; j++) {
      this.listModel.items.push(children[j]);
    }

    this.controller.modelChanged(this.listModel);
  },

  handleUserAboutResponse: function(response) {
    var userinfo = response.responseJSON;

    this.controller.get('created_field').update(StageAssistant.timeFormatter(userinfo.data.created_utc));
    this.controller.get('comment_karma_field').update(userinfo.data.comment_karma);
    this.controller.get('link_karma_field').update(userinfo.data.link_karma);
  },

  itemTapped: function(event) {
    var article = event.item;
    var thread_id;
    var thread_title;

    if (article.kind == 't3') { // post
      thread_id = article.data.name;
      thread_title = article.data.title;
    }
    else if (article.kind == 't1') { // comment
      thread_id = article.data.link_id;
      thread_title = article.data.link_title;
    }

    var hash = {
      url : '/comments/' + thread_id.substr(3),
      title : thread_title
    };

    this.controller.stageController.pushScene({name:"article",transition: Mojo.Transition.crossFade}, hash);
  }
});
