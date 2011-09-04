var UserAssistant;
var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
UserAssistant = (function() {
  function UserAssistant(url) {
    this.descriptionFormatter = __bind(this.descriptionFormatter, this);
    this.contentFormatter = __bind(this.contentFormatter, this);
    this.titleFormatter = __bind(this.titleFormatter, this);    this.user = url.linky;
    this.url = 'http://reddit.com/user/' + this.user + '.json';
    ({
      this.listModel: {
        items: []
      }
    });
  }
  UserAssistant.prototype.setup = function() {
    StageAssistant.setTheme(this);
    this.viewMenuModel({
      visible: true,
      items: [
        {
          items: [
            {}, {
              label: "overview for " + this.user,
              command: 'top',
              icon: "",
              width: Mojo.Environment.DeviceInfo.screenWidth
            }, {}
          ]
        }
      ]
    });
    this.controller.setupWidget(Mojo.Menu.viewMenu, {
      menuClass: 'no-fade'
    }, this.viewMenuModel);
    this.controller.setupWidget("list", {
      itemTemplate: "user/list-item",
      formatters: {
        title: this.titleFormatter,
        content: this.contentFormatter,
        description: this.descriptionFormatter
      }
    }, this.listModel);
    this.itemTappedBind = this.itemTapped.bind(this);
    return Mojo.Event.listen(this.controller.get("list"), Mojo.Event.listTap, this.itemTappedBind);
  };
  UserAssistant.prototype.activate = function(event) {
    StageAssistant.defaultWindowOrientation(this, "free");
    this.listModel.items.clear();
    this.controller.modelChanged(this.listModel);
    this.about();
    return this.fetchComments();
  };
  UserAssistant.prototype.deactivate = function(event) {};
  UserAssistant.prototype.cleanup = function(event) {
    return Mojo.Event.stopListening(this.controller.get("list"), Mojo.Event.listTap, this.itemTappedBind);
  };
  UserAssistant.prototype.titleFormatter = function(propertyValue, model) {
    if (model.kind === 't1') {
      return model.data.link_title;
    }
    if (model.kind === 't3') {
      return model.data.title;
    }
    return "";
  };
  UserAssistant.prototype.contentFormatter = function(propertyValue, model) {
    if (model.kind === 't1') {
      return model.data.body;
    }
    if (model.kind === 't3') {
      return model.data.selftext;
    }
    return "";
  };
  UserAssistant.prototype.descriptionFormatter = function(propertyValue, model) {
    if (model.kind === 't1') {
      return StageAssistant.scoreFormatter(model) + " " + StageAssistant.timeFormatter(model.data.created_utc);
    } else if (model.kind === 't3') {
      return "submitted " + StageAssistant.timeFormatter(model.data.created_utc) + " to " + model.data.subreddit;
    }
    return "";
  };
  UserAssistant.prototype.handleCommand = function(event) {
    if (event.type !== Mojo.Event.command) {
      return;
    }
    switch (event.command) {
      case 'top':
        return this.scrollToTop();
    }
  };
  UserAssistant.prototype.scrollToTop = function() {
    return this.controller.getSceneScroller().mojo.scrollTo(0, 0, true);
  };
  UserAssistant.prototype.handleCallback = function(params) {
    if (!((params != null) && params.success)) {
      return params;
    }
    if (params.type === "user-comments") {
      return this.handleUserCommentsResponse(params.response);
    } else if (params.type === "user-about") {
      return this.handleUserAboutResponse(params.response);
    }
  };
  UserAssistant.prototype.fetchComments = function() {
    var params;
    params = {
      user: this.user
    };
    return new User(this).comments(params);
  };
  UserAssistant.prototype.about = function() {
    var params;
    params = {
      user: this.user
    };
    return new User(this).about(params);
  };
  UserAssistant.prototype.handleUserCommentsResponse = function(response) {
    var children;
    children = response.responseJSON.data.children;
    _.each(children, __bind(function(child) {
      return this.listModel.items.push(child);
    }, this));
    return this.controller.modelChanged(this.listModel);
  };
  UserAssistant.prototype.handleUserAboutResponse = function(response) {
    var userinfo;
    userinfo = response.responseJSON;
    this.controller.get('created_field').update(StageAssistant.timeFormatter(userinfo.data.created_utc));
    this.controller.get('comment_karma_field').update(userinfo.data.comment_karma);
    return this.controller.get('link_karma_field').update(userinfo.data.link_karma);
  };
  UserAssistant.prototype.itemTapped = function(event) {
    var article, thread_id, thread_title;
    article = event.item;
    thread_id = null;
    thread_title = null;
    if (article.kind === 't3') {
      thread_id = article.data.name;
      thread_title = article.data.title;
    } else if (article.kind === 't1') {
      thread_id = article.data.link_id;
      thread_title = article.data.link_title;
    }
    hash({
      url: '/comments/' + thread_id.substr(3),
      title: thread_title
    });
    return this.controller.stageController.pushScene({
      name: "article",
      transition: Mojo.Transition.crossFade
    }, hash);
  };
  return UserAssistant;
})();