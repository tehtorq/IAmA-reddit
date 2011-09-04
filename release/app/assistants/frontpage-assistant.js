var FrontpageAssistant;
var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
  for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
  function ctor() { this.constructor = child; }
  ctor.prototype = parent.prototype;
  child.prototype = new ctor;
  child.__super__ = parent.prototype;
  return child;
};
FrontpageAssistant = (function() {
  __extends(FrontpageAssistant, PowerScrollBase);
  function FrontpageAssistant(params) {
    this.itemTapped = __bind(this.itemTapped, this);
    this.loadMoreArticles = __bind(this.loadMoreArticles, this);
    this.handleDeleteItem = __bind(this.handleDeleteItem, this);
    this.handleKeyDown = __bind(this.handleKeyDown, this);
    this.handleKeyUp = __bind(this.handleKeyUp, this);
    var default_frontpage;
    FrontpageAssistant.__super__.constructor.apply(this, arguments);
    this.articles = {
      items: []
    };
    this.reddit_api = new RedditAPI();
    this.params = params;
    this.waka = 'waka';
    default_frontpage = StageAssistant.cookieValue("prefs-frontpage", "frontpage");
    this.reddit_api.setSubreddit(default_frontpage);
    if (params != null) {
      if (params.reddit != null) {
        this.reddit_api.setSubreddit(params.reddit);
      } else if (params.permalink != null) {
        this.reddit_api.set_permalink(params.permalink);
      } else {
        this.search = params;
      }
    }
  }
  FrontpageAssistant.prototype.setup = function() {
    var array, controversial_items, heading, new_items, top_items;
    StageAssistant.setTheme(this);
    this.controller.setupWidget("spinner", this.attributes = {}, this.model = {
      spinning: true
    });
    new_items = [
      {
        label: $L("what's new"),
        command: $L("category new")
      }, {
        label: $L("new"),
        command: $L("category new sort new")
      }, {
        label: $L("rising"),
        command: $L("category new sort rising")
      }
    ];
    controversial_items = [
      {
        label: $L("today"),
        command: $L("category controversial t day")
      }, {
        label: $L("this hour"),
        command: $L("category controversial t hour")
      }, {
        label: $L("this week"),
        command: $L("category controversial t week")
      }, {
        label: $L("this month"),
        command: $L("category controversial t month")
      }, {
        label: $L("this year"),
        command: $L("category controversial t year")
      }, {
        label: $L("all time"),
        command: $L("category controversial t all")
      }
    ];
    top_items = [
      {
        label: $L("today"),
        command: $L("category top t day")
      }, {
        label: $L("this hour"),
        command: $L("category top t hour")
      }, {
        label: $L("this week"),
        command: $L("category top t week")
      }, {
        label: $L("this month"),
        command: $L("category top t month")
      }, {
        label: $L("this year"),
        command: $L("category top t year")
      }
    ];
    this.controller.setupWidget('category-submenu', null, {
      items: [
        {
          label: $L("hot"),
          command: $L("category hot")
        }, {
          label: $L("new"),
          items: new_items
        }, {
          label: $L("controversial"),
          items: controversial_items
        }, {
          label: $L("top"),
          items: top_items
        }, {
          label: $L("saved"),
          command: $L("category saved")
        }
      ]
    });
    array = [];
    if (Subreddit.cached_list.length > 0) {
      _.each(Subreddit.cached_list, function(item) {
        if (item.subscribed === true) {
          return array.push({
            label: item.label,
            command: 'subreddit ' + item.label
          });
        }
      });
      if (array.length === 0) {
        _.each(Subreddit.cached_list, function(item) {
          if (item.subscribed !== true) {
            return array.push({
              label: item.label,
              command: 'subreddit ' + item.label
            });
          }
        });
      }
      array.sort(function(a, b) {
        if (a.label.toLowerCase() < b.label.toLowerCase()) {
          return -1;
        }
        if (a.label.toLowerCase() > b.label.toLowerCase()) {
          return 1;
        }
        return 0;
      });
      array.unshift({
        label: 'random',
        command: 'subreddit random'
      });
      array.unshift({
        label: 'all',
        command: 'subreddit all'
      });
      array.unshift({
        label: 'frontpage',
        command: 'subreddit frontpage'
      });
    }
    this.subredditSubmenuModel = {
      items: array
    };
    this.controller.setupWidget('subreddit-submenu', null, this.subredditSubmenuModel);
    heading = this.reddit_api.subreddit != null ? this.reddit_api.subreddit : 'Frontpage';
    this.viewMenuModel = {
      visible: true,
      items: [
        {
          items: [
            {}, {
              label: '',
              submenu: "subreddit-submenu",
              icon: "search",
              width: 60
            }, {
              label: heading,
              command: 'new-card',
              icon: "",
              width: Mojo.Environment.DeviceInfo.screenWidth - 120
            }, {
              label: '',
              submenu: "category-submenu",
              width: 60,
              iconPath: 'images/options.png'
            }, {}
          ]
        }
      ]
    };
    this.controller.setupWidget(Mojo.Menu.viewMenu, {
      menuClass: 'no-fade'
    }, this.viewMenuModel);
    this.helpMenuDisabled = false;
    this.controller.setupWidget(Mojo.Menu.appMenu, {
      omitDefaultItems: true
    }, StageAssistant.appMenuModel);
    this.controller.setupWidget('filterfield', {
      delay: 2000
    });
    this.controller.listen('filterfield', Mojo.Event.filter, this.filter.bind(this));
    this.controller.setupWidget("article-list", {
      itemTemplate: "frontpage/article",
      emptyTemplate: "frontpage/emptylist",
      nullItemTemplate: "list/null_item_template",
      swipeToDelete: true,
      preventDeleteProperty: 'can_unsave',
      lookahead: 25,
      renderLimit: 1000,
      formatters: {
        tag: this.tagFormatter.bind(this),
        thumbnail: this.thumbnailFormatter.bind(this),
        vote: this.voteFormatter.bind(this)
      }
    }, this.articles);
    this.activityButtonModel = {
      label: "Load more"
    };
    this.controller.setupWidget("loadMoreButton", {
      type: Mojo.Widget.activityButton
    }, this.activityButtonModel);
    this.controller.get('loadMoreButton').hide();
    Mojo.Event.listen(this.controller.get("article-list"), Mojo.Event.listTap, this.itemTapped);
    Mojo.Event.listen(this.controller.get("article-list"), Mojo.Event.listDelete, this.handleDeleteItem);
    Mojo.Event.listen(this.controller.document, Mojo.Event.keyup, this.handleKeyUp, true);
    Mojo.Event.listen(this.controller.document, Mojo.Event.keydown, this.handleKeyDown, true);
    return Mojo.Event.listen(this.controller.get("loadMoreButton"), Mojo.Event.tap, this.loadMoreArticles);
  };
  FrontpageAssistant.prototype.activate = function(event) {
    FrontpageAssistant.__super__.activate.apply(this, arguments);
    StageAssistant.defaultWindowOrientation(this, "free");
    this.metakey = false;
    if (this.articles.items.length === 0) {
      if (this.search != null) {
        this.searchReddit(this.search);
      } else if (this.reddit_api.subreddit === 'random') {
        this.switchSubreddit(this.reddit_api.subreddit);
      } else {
        this.loadArticles();
      }
    }
    return this.fetchSubreddits('mine');
  };
  FrontpageAssistant.prototype.deactivate = function(event) {
    return FrontpageAssistant.__super__.deactivate.apply(this, arguments);
  };
  FrontpageAssistant.prototype.cleanup = function(event) {
    Request.clear_all();
    Mojo.Event.stopListening(this.controller.document, Mojo.Event.keyup, this.handleKeyUp);
    Mojo.Event.stopListening(this.controller.document, Mojo.Event.keydown, this.handleKeyDown);
    Mojo.Event.stopListening(this.controller.get("article-list"), Mojo.Event.listTap, this.itemTapped);
    Mojo.Event.stopListening(this.controller.get("article-list"), Mojo.Event.listDelete, this.handleDeleteItem);
    return Mojo.Event.stopListening(this.controller.get("loadMoreButton"), Mojo.Event.tap, this.loadMoreArticles);
  };
  FrontpageAssistant.prototype.tagFormatter = function(propertyValue, model) {
    if (model.data == null) {
      return "";
    }
    if (this.reddit_api.subreddit === model.data.subreddit) {
      return (model.data.ups - model.data.downs) + " points " + StageAssistant.timeFormatter(model.data.created_utc) + " by " + model.data.author;
    }
    return (model.data.ups - model.data.downs) + " points in " + model.data.subreddit + " by " + model.data.author;
  };
  FrontpageAssistant.prototype.thumbnailFormatter = function(propertyValue, model) {
    return Article.thumbnailFormatter(model);
  };
  FrontpageAssistant.prototype.voteFormatter = function(propertyValue, model) {
    if ((model.kind !== 't1') && (model.kind !== 't3')) {
      return '';
    }
    if (model.data.likes === true) {
      return '+1';
    }
    if (model.data.likes === false) {
      return '-1';
    }
    return '';
  };
  FrontpageAssistant.prototype.filter = function(filterEvent) {
    if (filterEvent.filterString.length === 0) {
      return;
    }
    this.controller.get('filterfield').mojo.close();
    return this.searchReddit(filterEvent.filterString);
  };
  FrontpageAssistant.prototype.handleKeyUp = function(event) {
    var e;
    e = event.originalEvent;
    if (e.metaKey === false) {
      return this.metakey = false;
    }
  };
  FrontpageAssistant.prototype.handleKeyDown = function(event) {
    var e;
    e = event.originalEvent;
    if (e.metaKey === true) {
      return this.metakey = true;
    }
  };
  FrontpageAssistant.prototype.spinSpinner = function(bool) {
    if (bool) {
      return this.controller.get('loading').show();
    } else {
      return this.controller.get('loading').hide();
    }
  };
  FrontpageAssistant.prototype.handleCategorySwitch = function(params) {
    if (params == null) {
      return;
    }
    if (params.length === 2) {
      this.reddit_api.setCategory(params[1]);
    } else {
      this.reddit_api.setCategory(params[1], {
        key: params[2],
        value: params[3]
      });
    }
    return this.loadArticles();
  };
  FrontpageAssistant.prototype.showMessageInbox = function() {
    return this.controller.stageController.pushScene({
      name: "message",
      transition: Mojo.Transition.crossFade
    }, {
      action: 'inbox'
    });
  };
  FrontpageAssistant.prototype.showComposeMessage = function() {
    return this.controller.stageController.pushScene({
      name: "compose-message",
      transition: Mojo.Transition.crossFade
    }, {
      action: 'compose'
    });
  };
  FrontpageAssistant.prototype.handleCallback = function(params) {
    var index;
    if (!((params != null) && params.success)) {
      return params;
    }
    this.spinSpinner(false);
    index = -1;
    params.type = params.type.split(' ');
    switch (params.type[0]) {
      case "article-unsave":
        if (params.type[1] != null) {
          index = this.findArticleIndex(params.type[1]);
          if (index > -1) {
            this.articles.items[index].data.saved = false;
            this.controller.get('article-list').mojo.noticeUpdatedItems(index, [this.articles.items[index]]);
          }
        }
        return new Banner("Unsaved!").send();
      case "article-save":
        if (params.type[1] != null) {
          index = this.findArticleIndex(params.type[1]);
          if (index > -1) {
            this.articles.items[index].data.saved = true;
            this.controller.get('article-list').mojo.noticeUpdatedItems(index, [this.articles.items[index]]);
          }
        }
        return new Banner("Saved!").send();
      case 'load-articles':
        return this.handleLoadArticlesResponse(params.response);
      case 'random-subreddit':
        return this.handleRandomSubredditResponse(params.response);
      case 'subreddit-load':
        return this.handleFetchSubredditsResponse(params.response);
      case 'subreddit-load-mine':
        this.handleFetchSubredditsResponse(params.response);
        return this.fetchSubreddits();
      case "comment-upvote":
        index = this.findArticleIndex(params.type[1]);
        if (index > -1) {
          if (!this.articles.items[index].data.likes === false) {
            this.articles.items[index].data.downs--;
          }
          this.articles.items[index].data.likes = true;
          this.articles.items[index].data.ups++;
          this.controller.get('article-list').mojo.noticeUpdatedItems(index, [this.articles.items[index]]);
        }
        return new Banner("Upvoted!").send();
      case "comment-downvote":
        index = this.findArticleIndex(params.type[1]);
        if (index > -1) {
          if (this.articles.items[index].data.likes === true) {
            this.articles.items[index].data.ups--;
          }
          this.articles.items[index].data.likes = false;
          this.articles.items[index].data.downs++;
          this.controller.get('article-list').mojo.noticeUpdatedItems(index, [this.articles.items[index]]);
        }
        return new Banner("Downvoted!").send();
      case "comment-vote-reset":
        index = this.findArticleIndex(params.type[1]);
        if (index > -1) {
          if (this.articles.items[index].data.likes === true) {
            this.articles.items[index].data.ups--;
          } else {
            this.articles.items[index].data.downs--;
          }
          this.articles.items[index].data.likes = null;
          this.controller.get('article-list').mojo.noticeUpdatedItems(index, [this.articles.items[index]]);
        }
        return new Banner("Vote reset!").send();
    }
  };
  FrontpageAssistant.prototype.handleDeleteItem = function(event) {
    this.unsaveArticle(event.item);
    return this.articles.items.splice(event.index, 1);
  };
  FrontpageAssistant.prototype.subredditsLoaded = function() {
    return Subreddit.cached_list.length > 0;
  };
  FrontpageAssistant.prototype.fetchSubreddits = function(type) {
    if (this.subredditsLoaded()) {
      return;
    }
    if (type === 'mine') {
      return new Request(this).get('http://www.reddit.com/reddits/mine/.json', {}, 'subreddit-load-mine');
    } else {
      return new Request(this).get('http://www.reddit.com/reddits/.json', {}, 'subreddit-load');
    }
  };
  FrontpageAssistant.prototype.searchReddit = function(searchTerm) {
    this.reddit_api.setSearchTerm(searchTerm);
    return this.loadArticles();
  };
  FrontpageAssistant.prototype.randomSubreddit = function() {
    return new Request(this).get('http://www.reddit.com/r/random/', {}, 'random-subreddit');
  };
  FrontpageAssistant.prototype.switchSubreddit = function(subreddit) {
    if (subreddit == null) {
      return;
    }
    if (subreddit === 'random') {
      this.spinSpinner(true);
      this.randomSubreddit();
      return;
    }
    this.reddit_api.setSubreddit(subreddit);
    return this.loadArticles();
  };
  FrontpageAssistant.prototype.updateHeading = function(text) {
    if (text == null) {
      text = '';
    }
    this.viewMenuModel.items[0].items[2].label = text;
    return this.controller.modelChanged(this.viewMenuModel);
  };
  FrontpageAssistant.prototype.loadMoreArticles = function() {
    this.reddit_api.load_next = true;
    return this.loadArticles();
  };
  FrontpageAssistant.prototype.displayLoadingButton = function() {
    this.controller.get('loadMoreButton').mojo.activate();
    this.activityButtonModel.label = "Loading";
    this.activityButtonModel.disabled = true;
    return this.controller.modelChanged(this.activityButtonModel);
  };
  FrontpageAssistant.prototype.loadArticles = function() {
    var length, parameters;
    parameters = {};
    parameters.limit = this.reddit_api.getArticlesPerPage();
    if (this.reddit_api.load_next) {
      parameters.after = this.articles.items[this.articles.items.length - 1].data.name;
      this.displayLoadingButton();
    } else {
      length = this.articles.items.length;
      this.articles.items.clear();
      this.controller.get('loadMoreButton').hide();
      this.spinSpinner(true);
      this.controller.get('article-list').mojo.noticeRemovedItems(0, length);
    }
    if (this.reddit_api.subreddit != null) {
      this.updateHeading(this.reddit_api.subreddit);
    } else if (this.reddit_api.domain != null) {
      this.updateHeading(this.reddit_api.domain);
    } else if (this.reddit_api.search != null) {
      this.updateHeading(this.reddit_api.search);
      parameters.q = this.reddit_api.search;
      parameters.restrict_sr = 'off';
      parameters.sort = 'relevance';
    } else {
      this.updateHeading(null);
    }
    return new Request(this).get(this.reddit_api.getArticlesUrl(), parameters, 'load-articles');
  };
  FrontpageAssistant.prototype.handleLoadArticlesResponse = function(response) {
    var data, items, json;
    this.reddit_api.load_next = false;
    json = response.responseJSON;
    if (response.responseJSON == null) {
      return;
    }
    data = json.length > 0 ? json[1].data : json.data;
    this.modhash = data.modhash;
    items = data.children;
    _.each(items, __bind(function(item) {
      item.can_unsave = item.data.saved ? false : true;
      return this.articles.items.push(item);
    }, this));
    this.controller.modelChanged(this.articles);
    this.spinSpinner(false);
    this.controller.get('loadMoreButton').mojo.deactivate();
    this.activityButtonModel.label = "Load more";
    this.activityButtonModel.disabled = false;
    this.controller.modelChanged(this.activityButtonModel);
    if (items.length > 0) {
      this.controller.get('loadMoreButton').show();
    } else {
      this.controller.get('loadMoreButton').hide();
    }
    if (this.articles.items.length === 0) {
      return this.controller.get('article-list').mojo.noticeAddedItems(0, [null]);
    }
  };
  FrontpageAssistant.prototype.handleRandomSubredditResponse = function(response) {
    var end_offset, headers, start_offset, subreddit;
    headers = response.getAllHeaders();
    start_offset = headers.indexOf('Location: /r/') + 13;
    end_offset = headers.indexOf('/', start_offset);
    subreddit = headers.substring(start_offset, end_offset);
    return this.switchSubreddit(subreddit);
  };
  FrontpageAssistant.prototype.handleFetchSubredditsResponse = function(response) {
    var array, children, data, i;
    if (!((response != null) && (response.responseJSON != null) && (response.responseJSON.data != null))) {
      return;
    }
    data = response.responseJSON.data;
    children = data.children;
    array = [];
    i = 0;
    _.each(children, function(child) {
      return Subreddit.cached_list.push({
        label: child.data.display_name,
        subscribed: (data.modhash != null) && (data.modhash !== ""),
        name: child.data.name
      });
    });
    _.each(Subreddit.cached_list, function(item) {
      if (item.subscribed === true) {
        return array.push({
          label: item.label,
          command: 'subreddit ' + item.label
        });
      }
    });
    if (array.length === 0) {
      _.each(Subreddit.cached_list, function(item) {
        if (item.subscribed !== true) {
          return array.push({
            label: item.label,
            command: 'subreddit ' + item.label
          });
        }
      });
    }
    array.sort(function(a, b) {
      if (a.label.toLowerCase() < b.label.toLowerCase()) {
        return -1;
      }
      if (a.label.toLowerCase() > b.label.toLowerCase()) {
        return 1;
      }
      return 0;
    });
    array.unshift({
      label: 'random',
      command: 'subreddit random'
    });
    array.unshift({
      label: 'all',
      command: 'subreddit all'
    });
    array.unshift({
      label: 'frontpage',
      command: 'subreddit frontpage'
    });
    this.subredditSubmenuModel.items = array;
    return this.controller.modelChanged(this.subredditSubmenuModel);
  };
  FrontpageAssistant.prototype.handleActionSelection = function(command) {
    var article, params;
    if (command == null) {
      return;
    }
    params = command.split(' ');
    switch (params[0]) {
      case 'domain-cmd':
        this.reddit_api.setDomain(params[1]);
        return this.loadArticles();
      case 'comments-cmd':
        article = this.articles.items[parseInt(params[1])];
        return this.controller.stageController.pushScene({
          name: "article"
        }, {
          article: article
        });
      case 'upvote-cmd':
        this.spinSpinner(true);
        return this.voteOnComment('1', params[1], params[2]);
      case 'downvote-cmd':
        this.spinSpinner(true);
        return this.voteOnComment('-1', params[1], params[2]);
      case 'reset-vote-cmd':
        this.spinSpinner(true);
        return this.voteOnComment('0', params[1], params[2]);
      case 'save-cmd':
        this.spinSpinner(true);
        return this.saveArticle(this.articles.items[params[1]]);
      case 'unsave-cmd':
        this.spinSpinner(true);
        return this.unsaveArticle(this.articles.items[params[1]]);
    }
  };
  FrontpageAssistant.prototype.findArticleIndex = function(article_name) {
    var index;
    index = -1;
    _.each(this.articles.items, function(item, i) {
      if (item.data.name === article_name) {
        return index = i;
      }
    });
    return index;
  };
  FrontpageAssistant.prototype.saveArticle = function(article) {
    ({
      params: {
        executed: 'saved',
        id: article.data.name,
        uh: this.modhash
      }
    });
    return new Article(this).save(params);
  };
  FrontpageAssistant.prototype.unsaveArticle = function(article) {
    ({
      params: {
        executed: 'unsaved',
        id: article.data.name,
        uh: this.modhash
      }
    });
    return new Article(this).unsave(params);
  };
  FrontpageAssistant.prototype.voteOnComment = function(dir, comment_name, subreddit) {
    ({
      params: {
        dir: dir,
        id: comment_name,
        uh: this.modhash,
        r: subreddit
      }
    });
    if (dir === 1) {
      return new Comment(this).upvote(params);
    } else if (dir === -1) {
      return new Comment(this).downvote(params);
    } else {
      return new Comment(this).reset_vote(params);
    }
  };
  FrontpageAssistant.prototype.isLoggedIn = function() {
    return this.modhash && (this.modhash !== "");
  };
  FrontpageAssistant.prototype.itemTapped = function(event) {
    var article, downvote_action, downvote_icon, element_tapped, save_action, save_label, upvote_action, upvote_icon;
    article = event.item;
    element_tapped = event.originalEvent.target;
    if (element_tapped.className.indexOf('comment_counter') !== -1) {
      AppAssistant.cloneCard(this, {
        name: "article"
      }, {
        article: article
      });
      return;
    }
    if (element_tapped.id.indexOf('image_') !== -1) {
      StageAssistant.cloneImageCard(this, article);
      return;
    }
    if (element_tapped.id.indexOf('youtube_') !== -1 || element_tapped.id.indexOf('web_') !== -1) {
      this.controller.serviceRequest("palm://com.palm.applicationManager", {
        method: "open",
        parameters: {
          target: Linky.parse(article.data.url).url,
          onSuccess: function() {},
          onFailure: function() {}
        }
      });
      return;
    }
    if (this.isLoggedIn()) {
      upvote_icon = article.data.likes === true ? 'selected_upvote_icon' : 'upvote_icon';
      downvote_icon = article.data.likes === false ? 'selected_downvote_icon' : 'downvote_icon';
      upvote_action = article.data.likes === true ? 'reset-vote-cmd' : 'upvote-cmd';
      downvote_action = article.data.likes === false ? 'reset-vote-cmd' : 'downvote-cmd';
      save_action = article.data.saved === true ? 'unsave-cmd' : 'save-cmd';
      save_label = article.data.saved === true ? 'Unsave' : 'Save';
      return this.controller.popupSubmenu({
        onChoose: this.handleActionSelection.bind(this),
        placeNear: element_tapped,
        items: [
          {
            label: $L('Upvote'),
            command: upvote_action + ' ' + article.data.name + ' ' + article.data.subreddit,
            secondaryIcon: upvote_icon
          }, {
            label: $L('Downvote'),
            command: downvote_action + ' ' + article.data.name + ' ' + article.data.subreddit,
            secondaryIcon: downvote_icon
          }, {
            label: $L('Comments'),
            command: 'comments-cmd ' + event.index
          }, {
            label: $L(save_label),
            command: save_action + ' ' + event.index
          }, {
            label: $L(article.data.domain),
            command: 'domain-cmd ' + article.data.domain
          }
        ]
      });
    } else {
      return this.controller.popupSubmenu({
        onChoose: this.handleActionSelection.bind(this),
        placeNear: element_tapped,
        items: [
          {
            label: $L('Comments'),
            command: 'comments-cmd ' + event.index
          }, {
            label: $L(article.data.domain),
            command: 'domain-cmd ' + article.data.domain
          }
        ]
      });
    }
  };
  FrontpageAssistant.prototype.handleCommand = function(event) {
    var controller, currentScene, params, _ref;
    if (event.type !== Mojo.Event.command) {
      return;
    }
    params = event.command.split(' ');
    (this.handleCategorySwitch(params) === (_ref = params[0]) && _ref === 'category');
    switch (params[0]) {
      case 'new-card':
        AppAssistant.cloneCard();
        break;
      case 'subreddit':
        this.switchSubreddit(params[1]);
    }
    controller = Mojo.Controller.getAppController().getActiveStageController();
    currentScene = controller.activeScene();
    switch (event.type) {
      case Mojo.Event.commandEnable:
        switch (event.command) {
          case Mojo.Menu.prefsCmd:
            if (!currentScene.assistant.prefsMenuDisabled) {
              return event.stopPropagation();
            }
            break;
          case Mojo.Menu.helpCmd:
            if (!currentScene.assistant.helpMenuDisabled) {
              return event.stopPropagation();
            }
        }
        break;
      case Mojo.Event.command:
        switch (event.command) {
          case Mojo.Menu.helpCmd:
            return controller.pushScene('support');
          case Mojo.Menu.prefsCmd:
            return AppAssistant.cloneCard(this, {
              name: "prefs"
            }, {});
          case 'login-cmd':
            return controller.pushScene({
              name: "login",
              transition: Mojo.Transition.crossFade
            });
          case 'logout-cmd':
            return new User(this).logout({});
          case 'register-cmd':
            return controller.pushScene({
              name: "register",
              transition: Mojo.Transition.crossFade
            });
          case 'reddits-cmd':
            return AppAssistant.cloneCard(this, {
              name: "reddits"
            }, {});
          case 'gallery-cmd':
            return AppAssistant.cloneCard(this, {
              name: "gallery"
            }, {});
          case 'recent-comments-cmd':
            return AppAssistant.cloneCard(this, {
              name: "recent-comment"
            }, {});
          case 'messages-cmd':
            return AppAssistant.cloneCard(this, {
              name: "message"
            }, {});
        }
    }
  };
  return FrontpageAssistant;
})();