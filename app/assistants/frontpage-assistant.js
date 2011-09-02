
FrontpageAssistant = Class.create(PowerScrollBase, {

  initialize: function($super, params) {
    Mojo.Log.info("Wtf")
    $super();
    this.articles = { items : [] };
    this.reddit_api = new RedditAPI();
    Mojo.Log.info("Wtf")
    this.params = params;
    
    var default_frontpage = StageAssistant.cookieValue("prefs-frontpage", "frontpage");
        
    this.reddit_api.setSubreddit(default_frontpage);
    Mojo.Log.info("Wtf")

    if (params) {
      if (params.reddit) {
        this.reddit_api.setSubreddit(params.reddit);
        Mojo.Log.info("Wtf")
      }
      else if (params.permalink) {
        this.reddit_api.set_permalink(params.permalink);
        Mojo.Log.info("Wtf")
      }
      else {
        this.search = params;
      }
    }
    Mojo.Log.info("Wtf")
  },

  setup: function() {
    StageAssistant.setTheme(this);
    
    this.controller.setupWidget("spinner",
      this.attributes = {},
      this.model = {spinning: true}
    ); 
    
    this.controller.setupWidget('category-submenu', null, {items: [
      {label:$L("hot"), command:$L("category hot")},
      {label:$L("new"), items: [{label:$L("what's new"), command:$L("category new")},
                                {label:$L("new"), command:$L("category new sort new")},
                                {label:$L("rising"), command:$L("category new sort rising")}]},
      {label:$L("controversial"), items: [{label:$L("today"), command:$L("category controversial t day")},
                                          {label:$L("this hour"), command:$L("category controversial t hour")},
                                          {label:$L("this week"), command:$L("category controversial t week")},
                                          {label:$L("this month"), command:$L("category controversial t month")},
                                          {label:$L("this year"), command:$L("category controversial t year")},
                                          {label:$L("all time"), command:$L("category controversial t all")}]},
      {label:$L("top"), items: [{label:$L("today"), command:$L("category top t day")},
                                {label:$L("this hour"), command:$L("category top t hour")},
                                {label:$L("this week"), command:$L("category top t week")},
                                {label:$L("this month"), command:$L("category top t month")},
                                {label:$L("this year"), command:$L("category top t year")}/*,
                                {label:$L("all time"), command:$L("category top t all")} not working??? */]},
      {label:$L("saved"), command:$L("category saved")}
      ]});
    
    var array = [];
    var i;
    
    if (Subreddit.cached_list.length > 0) {      
      // subscribed reddits
      
      for (i = 0; i < Subreddit.cached_list.length; i++) {
        if (Subreddit.cached_list[i].subscribed == true) {
          array.push({label: Subreddit.cached_list[i].label, command: 'subreddit ' + Subreddit.cached_list[i].label});
        }
      }
      
      // unsubscribed reddits
      
      if (array.length == 0) {
        for (i = 0; i < Subreddit.cached_list.length; i++) {
          if (Subreddit.cached_list[i].subscribed !== true) {
            array.push({label: Subreddit.cached_list[i].label, command: 'subreddit ' + Subreddit.cached_list[i].label});
          }
        }        
      }
      
      array.sort(function(a, b) {
        if ( a.label.toLowerCase() < b.label.toLowerCase() )
          return -1;
        if ( a.label.toLowerCase() > b.label.toLowerCase() )
          return 1;

        return 0;
      });
    
      array.unshift({label: 'random', command: 'subreddit random'});
      array.unshift({label: 'all', command: 'subreddit all'});
      array.unshift({label: 'frontpage', command: 'subreddit frontpage'});
    }
    
    this.subredditSubmenuModel = {items: array};

    this.controller.setupWidget('subreddit-submenu', null, this.subredditSubmenuModel);
    
    var heading = 'Frontpage';
    if (this.reddit_api.subreddit) {
      heading = this.reddit_api.subreddit;
    }

    this.viewMenuModel = {
      visible: true,
      items: [
          {items:[{},
                  { label: '', submenu: "subreddit-submenu", icon: "search", width: 60},
                  { label: heading, command: 'new-card', icon: "", width: Mojo.Environment.DeviceInfo.screenWidth - 120},
                  { label: '', submenu: "category-submenu", width: 60, iconPath: 'images/options.png'},
                  {}]}
      ]
    };

    this.controller.setupWidget(Mojo.Menu.viewMenu, { menuClass:'no-fade' }, this.viewMenuModel);

    this.helpMenuDisabled = false;

    this.controller.setupWidget(Mojo.Menu.appMenu, {omitDefaultItems: true}, StageAssistant.appMenuModel);

    this.controller.setupWidget('filterfield', {delay: 2000});
    this.controller.listen('filterfield', Mojo.Event.filter, this.filter.bind(this));

    this.controller.setupWidget("article-list", {
      itemTemplate : "frontpage/article",
      emptyTemplate : "frontpage/emptylist",
      nullItemTemplate: "list/null_item_template",
      swipeToDelete: true,
      preventDeleteProperty: 'can_unsave',
      lookahead : 25,
      renderLimit : 1000,
      formatters: {tag: this.tagFormatter.bind(this), 
                   thumbnail: this.thumbnailFormatter.bind(this),
                   vote: this.voteFormatter.bind(this)
                  }
      }, this.articles);

    this.activityButtonModel = {label : "Load more"};
    this.controller.setupWidget("loadMoreButton", {type:Mojo.Widget.activityButton}, this.activityButtonModel);
    this.controller.get('loadMoreButton').hide();

    /* add event handlers to listen to events from widgets */

    this.itemTappedBind = this.itemTapped.bind(this);
    this.loadMoreArticlesBind = this.loadMoreArticles.bind(this);
    this.handleDeleteItemBind = this.handleDeleteItem.bind(this);
    this.handleKeyUpBind = this.handleKeyUp.bindAsEventListener(this);
    this.handleKeyDownBind = this.handleKeyDown.bindAsEventListener(this);

    Mojo.Event.listen(this.controller.get("article-list"), Mojo.Event.listTap, this.itemTappedBind);
    Mojo.Event.listen(this.controller.get("article-list"), Mojo.Event.listDelete, this.handleDeleteItemBind);
    Mojo.Event.listen(this.controller.document,Mojo.Event.keyup, this.handleKeyUpBind, true);
    Mojo.Event.listen(this.controller.document,Mojo.Event.keydown, this.handleKeyDownBind, true);
    Mojo.Event.listen(this.controller.get("loadMoreButton"), Mojo.Event.tap, this.loadMoreArticlesBind);
  },

  activate: function($super, event) {
    $super();
    StageAssistant.defaultWindowOrientation(this, "free");
    this.metakey = false;

    if (this.articles.items.length == 0) {
      if (this.search) {
        this.searchReddit(this.search);
      }
      else if (this.reddit_api.subreddit == 'random') {
        this.switchSubreddit(this.reddit_api.subreddit);
      }
      else {
        this.loadArticles();
      }
    }

    this.fetchSubreddits('mine');
  },

  deactivate: function($super, event) {
    $super();
  },

  cleanup: function(event) {
    Request.clear_all();
    
    Mojo.Event.stopListening(this.controller.document,Mojo.Event.keyup, this.handleKeyUpBind);
    Mojo.Event.stopListening(this.controller.document,Mojo.Event.keydown, this.handleKeyDownBind);
    Mojo.Event.stopListening(this.controller.get("article-list"), Mojo.Event.listTap, this.itemTappedBind);
    Mojo.Event.stopListening(this.controller.get("article-list"), Mojo.Event.listDelete, this.handleDeleteItemBind);
    Mojo.Event.stopListening(this.controller.get("loadMoreButton"), Mojo.Event.tap, this.loadMoreArticlesBind);
  },

  tagFormatter: function(propertyValue, model) {
    if (!model.data) {
      return "";
    }
    
    if (this.reddit_api.subreddit == model.data.subreddit) {
      return (model.data.ups - model.data.downs) + " points " + StageAssistant.timeFormatter(model.data.created_utc) + " by " + model.data.author;
    }
    
    return (model.data.ups - model.data.downs) + " points in " + model.data.subreddit + " by " + model.data.author;
  },
  
  thumbnailFormatter: function(propertyValue, model) {
    return Article.thumbnailFormatter(model);
  },
  
  voteFormatter: function(propertyValue, model) {
    if ((model.kind != 't1') && (model.kind != 't3')) {
      return "";
    }
    
    if (model.data.likes == true) {
      return '+1';
    }
    else if (model.data.likes == false) {
      return '-1';
    }

    return '';
  },

  filter: function(filterEvent) {
    if (filterEvent.filterString.length == 0) {
      return;
    }

    this.controller.get('filterfield').mojo.close();
    this.searchReddit(filterEvent.filterString);
  },

  handleKeyUp: function(event) {
    var e = event.originalEvent;

    if (e.metaKey == false) {
      this.metakey = false;
    }
  },

  handleKeyDown: function(event) {

    var e = event.originalEvent;

    if (e.metaKey == true) {
      //new Banner("meta").send();
      this.metakey = true;
    }
  },

  spinSpinner: function(bool) {
    if (bool) {
      this.controller.get('loading').show();
    }
    else {
      this.controller.get('loading').hide();
    }
  },

  handleCategorySwitch: function(params) {
    if (params == undefined) {
      return;
    }
    
    if (params.length == 2) {
      this.reddit_api.setCategory(params[1]);
    }
    else {
      this.reddit_api.setCategory(params[1], {key: params[2], value: params[3]});
    }
    
    this.loadArticles();
  },

  showMessageInbox: function() {
    this.controller.stageController.pushScene({name:"message",transition: Mojo.Transition.crossFade},{action:'inbox'});
  },

  showComposeMessage: function() {
    this.controller.stageController.pushScene({name:"compose-message",transition: Mojo.Transition.crossFade},{action:'compose'});
  },

  handleCallback: function(params) {
    if (!params || !params.success) {
      return params;
    }
    
    this.spinSpinner(false);
    
    var index = -1;
    params.type = params.type.split(' ');

    if (params.type[0] == "article-unsave") {      
      if (params.type[1]) {
        index = this.findArticleIndex(params.type[1]);
        
        if (index > -1) {
          this.articles.items[index].data.saved = false;
          this.controller.get('article-list').mojo.noticeUpdatedItems(index, [this.articles.items[index]]);
        }
      }
      
      new Banner("Unsaved!").send();      
    }
    else if (params.type[0] == "article-save") {
      if (params.type[1]) {
        index = this.findArticleIndex(params.type[1]);
        
        if (index > -1) {
          this.articles.items[index].data.saved = true;
          this.controller.get('article-list').mojo.noticeUpdatedItems(index, [this.articles.items[index]]);
        }
      }
      
      new Banner("Saved!").send();      
    }
    else if (params.type[0] == 'load-articles') {
      this.handleLoadArticlesResponse(params.response);
    }
    else if (params.type == 'random-subreddit') {
      this.handleRandomSubredditResponse(params.response);
    }
    else if (params.type[0] == 'subreddit-load') {
      this.handleFetchSubredditsResponse(params.response);
    }
    else if (params.type[0] == 'subreddit-load-mine') {
      this.handleFetchSubredditsResponse(params.response);
      this.fetchSubreddits();
    }
    else if (params.type[0] == "comment-upvote") {
      index = this.findArticleIndex(params.type[1]);

      if (index > -1) {
        if (this.articles.items[index].data.likes === false) {
          this.articles.items[index].data.downs--;
        }

        this.articles.items[index].data.likes = true;
        this.articles.items[index].data.ups++;
        this.controller.get('article-list').mojo.noticeUpdatedItems(index, [this.articles.items[index]]);
      }
      
      new Banner("Upvoted!").send();
    }
    else if (params.type[0] == "comment-downvote") {
      index = this.findArticleIndex(params.type[1]);
      
      if (index > -1) {
        if (this.articles.items[index].data.likes === true) {
          this.articles.items[index].data.ups--;
        }

        this.articles.items[index].data.likes = false;
        this.articles.items[index].data.downs++;
        this.controller.get('article-list').mojo.noticeUpdatedItems(index, [this.articles.items[index]]);
      }
      
      new Banner("Downvoted!").send();
    }
    else if (params.type[0] == "comment-vote-reset") {
      index = this.findArticleIndex(params.type[1]);
      
      if (index > -1) {
        if (this.articles.items[index].data.likes === true) {
          this.articles.items[index].data.ups--;
        }
        else {
          this.articles.items[index].data.downs--;
        }

        this.articles.items[index].data.likes = null;      
        this.controller.get('article-list').mojo.noticeUpdatedItems(index, [this.articles.items[index]]);
      }
      
      new Banner("Vote reset!").send();
    }
  },

  handleDeleteItem: function(event) {
    this.unsaveArticle(event.item);
    this.articles.items.splice(event.index, 1);
  },
  
  subredditsLoaded: function() {
    return (Subreddit.cached_list.length > 0);
  },

  fetchSubreddits: function(type) {
    if (this.subredditsLoaded()) {
      return;
    }
    
    if (type == 'mine') {
      new Request(this).get('http://www.reddit.com/reddits/mine/.json', {}, 'subreddit-load-mine');
      //new Subreddit(this).mine({});
    }
    else {
      //new Subreddit(this).load({});
      new Request(this).get('http://www.reddit.com/reddits/.json', {}, 'subreddit-load');
    }
  },

  searchReddit: function(searchTerm) {
    this.reddit_api.setSearchTerm(searchTerm);
    this.loadArticles();
  },

  randomSubreddit: function() {
    new Request(this).get('http://www.reddit.com/r/random/', {}, 'random-subreddit');
  },

  switchSubreddit: function(subreddit) {
    if (subreddit == undefined) {
      return;
    }

    if (subreddit == 'random') {
      this.spinSpinner(true);
      this.randomSubreddit();
      return;
    }

    this.reddit_api.setSubreddit(subreddit);
    this.loadArticles();
  },

  updateHeading: function (text) {
    if (text == null) {
      text = '';
    }

    this.viewMenuModel.items[0].items[2].label = text;
    this.controller.modelChanged(this.viewMenuModel);
  },

  loadMoreArticles: function() {
    this.reddit_api.load_next = true;
    this.loadArticles();
  },

  displayLoadingButton: function() {
    this.controller.get('loadMoreButton').mojo.activate();
    this.activityButtonModel.label = "Loading";
    this.activityButtonModel.disabled = true;
    this.controller.modelChanged(this.activityButtonModel);
  },

  loadArticles: function() {
    var parameters = {};
    parameters.limit = this.reddit_api.getArticlesPerPage();
    
    if (this.reddit_api.load_next) {
      parameters.after = this.articles.items[this.articles.items.length - 1].data.name;
      this.displayLoadingButton();
    }
    else {
      var length = this.articles.items.length;
      this.articles.items.clear();
      this.controller.get('loadMoreButton').hide();
      this.spinSpinner(true);
      this.controller.get('article-list').mojo.noticeRemovedItems(0, length);
    }
    
    if (this.reddit_api.subreddit) {
      this.updateHeading(this.reddit_api.subreddit);
    }
    else if (this.reddit_api.domain) {
      this.updateHeading(this.reddit_api.domain);
    }
    else if (this.reddit_api.search != null) {
      this.updateHeading(this.reddit_api.search);
      parameters.q = this.reddit_api.search;
      parameters.restrict_sr = 'off';
      parameters.sort = 'relevance';
    }
    else {
      this.updateHeading(null);
    }

    new Request(this).get(this.reddit_api.getArticlesUrl(), parameters, 'load-articles');
  },

  handleLoadArticlesResponse: function(response) {
    this.reddit_api.load_next = false;
    var json = response.responseJSON;
    
    if (!response.responseJSON) {
      //new Banner("Could not load content").send();
      return;
    }
    
    var data;
    
    if (json.length > 0) {
      data = json[1].data;
    }
    else {
      data = json.data;
    }
    
    this.modhash = data.modhash;
    var items = data.children;
    
    for (var i = 0; i < items.length; i++) {
      items[i].can_unsave = (items[i].data.saved) ? false : true;
      this.articles.items.push(items[i]);      
    }
    
    this.controller.modelChanged(this.articles);
    this.spinSpinner(false);
    this.controller.get('loadMoreButton').mojo.deactivate();
    this.activityButtonModel.label = "Load more";
    this.activityButtonModel.disabled = false;
    this.controller.modelChanged(this.activityButtonModel);

    if (items.length > 0) {
      this.controller.get('loadMoreButton').show();
    }
    else {
      this.controller.get('loadMoreButton').hide();
    }
    
    if (this.articles.items.length == 0) {
      this.controller.get('article-list').mojo.noticeAddedItems(0, [null]);
    }
  },

  handleRandomSubredditResponse: function (response) {
    var headers = response.getAllHeaders();

    var start_offset = headers.indexOf('Location: /r/') + 13;
    var end_offset = headers.indexOf('/', start_offset);
    var subreddit = headers.substring(start_offset, end_offset);

    this.switchSubreddit(subreddit);
  },

  handleFetchSubredditsResponse: function(response) {
    var myObj = response.responseJSON;
    
    if (!myObj.data) {
      return;
    }

    var data = myObj.data;
    var children = data.children;
    var array = [];
    var i = 0;
    
    for (i = 0; i < children.length; i++) {
      Subreddit.cached_list.push({label: children[i].data.display_name, subscribed: (data.modhash && data.modhash != ""), name: children[i].data.name});
    }
    
    for (i = 0; i < Subreddit.cached_list.length; i++) {
      if (Subreddit.cached_list[i].subscribed == true) {
        array.push({label: Subreddit.cached_list[i].label, command: 'subreddit ' + Subreddit.cached_list[i].label});
      }
    }

    // unsubscribed reddits

    if (array.length == 0) {
      for (i = 0; i < Subreddit.cached_list.length; i++) {
        if (Subreddit.cached_list[i].subscribed !== true) {
          array.push({label: Subreddit.cached_list[i].label, command: 'subreddit ' + Subreddit.cached_list[i].label});
        }
      }        
    }

    array.sort(function(a, b) {
      if ( a.label.toLowerCase() < b.label.toLowerCase() )
        return -1;
      if ( a.label.toLowerCase() > b.label.toLowerCase() )
        return 1;
      
      return 0;
    });
    
    array.unshift({label: 'random', command: 'subreddit random'});
    array.unshift({label: 'all', command: 'subreddit all'});
    array.unshift({label: 'frontpage', command: 'subreddit frontpage'});
    
    this.subredditSubmenuModel.items = array;
    this.controller.modelChanged(this.subredditSubmenuModel);
  },

  handleActionSelection: function(command) {
    if (command == undefined) {
      return;
    }
    
    var params = command.split(' ');

    if (params[0] == 'domain-cmd') {
      this.reddit_api.setDomain(params[1]);
      this.loadArticles();
    }
    else if (params[0] == 'comments-cmd') {
      var article = this.articles.items[parseInt(params[1])];
      this.controller.stageController.pushScene({name:"article"}, {article: article});
    }
    else if (params[0] == 'upvote-cmd') {
      this.spinSpinner(true);
      this.voteOnComment('1', params[1], params[2]);
    }
    else if (params[0] == 'downvote-cmd') {
      this.spinSpinner(true);
      this.voteOnComment('-1', params[1], params[2]);
    }
    else if (params[0] == 'reset-vote-cmd') {
      this.spinSpinner(true);
      this.voteOnComment('0', params[1], params[2]);
    }
    else if (params[0] == 'save-cmd') {
      this.spinSpinner(true);
      this.saveArticle(this.articles.items[params[1]]);
    }
    else if (params[0] == 'unsave-cmd') {
      this.spinSpinner(true);
      this.unsaveArticle(this.articles.items[params[1]]);
    }
  },
  
  findArticleIndex: function(article_name) {
    var length = this.articles.items.length;
    var items = this.articles.items;
    
    for (var i = length - 1; i >= 0; i--) {
      if (items[i].data.name == article_name) {
        return i;
      }
    }
    
    return -1;
  },
  
  saveArticle: function(article) {
    var params = {executed: 'saved',
                    id: article.data.name,
                    uh: this.modhash};

    new Article(this).save(params);
  },
  
  unsaveArticle: function(article) {
    var params = {executed: 'unsaved',
                    id: article.data.name,
                    uh: this.modhash};

    new Article(this).unsave(params);
  },
  
  voteOnComment: function(dir, comment_name, subreddit) {
    var params = {dir: dir,
                  id: comment_name,
                  uh: this.modhash,
                  r: subreddit};

    if (dir == 1) {
      new Comment(this).upvote(params);
    }
    else if (dir == -1) {
      new Comment(this).downvote(params);
    }
    else {
      new Comment(this).reset_vote(params);
    }
  },
  
  isLoggedIn: function() {
    return (this.modhash && this.modhash != "");
  },

  itemTapped: function(event) {
    var article = event.item;
    var element_tapped = event.originalEvent.target;

    if (element_tapped.className.indexOf('comment_counter') != -1) {
      AppAssistant.cloneCard(this, {name:"article"}, {article: article});
      return;
    }

    if (element_tapped.id.indexOf('image_') != -1) {
      StageAssistant.cloneImageCard(this, article);
      return;
    }

    if ((element_tapped.id.indexOf('youtube_') != -1) || (element_tapped.id.indexOf('web_') != -1)) {
      this.controller.serviceRequest("palm://com.palm.applicationManager", {
        method : "open",
        parameters : {
          target : Linky.parse(article.data.url).url,
          onSuccess : function() {  },
          onFailure : function() {  }
        }
        });
      return;
    }
    
    if (this.isLoggedIn()) {
      var upvote_icon = (article.data.likes === true) ? 'selected_upvote_icon' : 'upvote_icon';
      var downvote_icon = (article.data.likes === false) ? 'selected_downvote_icon' : 'downvote_icon';
      var upvote_action = (article.data.likes === true) ? 'reset-vote-cmd' : 'upvote-cmd';
      var downvote_action = (article.data.likes === false) ? 'reset-vote-cmd' : 'downvote-cmd';
      var save_action = (article.data.saved === true) ? 'unsave-cmd' : 'save-cmd';
      var save_label = (article.data.saved === true) ? 'Unsave' : 'Save';

      this.controller.popupSubmenu({
       onChoose: this.handleActionSelection.bind(this),
       placeNear:element_tapped,
       items: [                         
         {label: $L('Upvote'), command: upvote_action + ' ' + article.data.name + ' ' + article.data.subreddit, secondaryIcon: upvote_icon},
         {label: $L('Downvote'), command: downvote_action + ' ' + article.data.name + ' ' + article.data.subreddit, secondaryIcon: downvote_icon},
         {label: $L('Comments'), command: 'comments-cmd ' + event.index},
         {label: $L(save_label), command: save_action + ' ' + event.index},
         {label: $L(article.data.domain), command: 'domain-cmd ' + article.data.domain}]
       });
    }
    else {
      this.controller.popupSubmenu({
       onChoose: this.handleActionSelection.bind(this),
       placeNear:element_tapped,
       items: [
         {label: $L('Comments'), command: 'comments-cmd ' + event.index},
         {label: $L(article.data.domain), command: 'domain-cmd ' + article.data.domain}]
       });     
    }

    //this.controller.stageController.pushScene({name:"article"}, {article: {kind: 't3', data: article.data}});
  },

  handleCommand: function(event) {
    if (event.type != Mojo.Event.command) {
      return;
    }

    var params = event.command.split(' ');
    
    if (params[0] == 'category') {
      this.handleCategorySwitch(params);
    }

    switch (params[0]) {
      case 'new-card':
        AppAssistant.cloneCard();
        break;
      case 'subreddit':
        this.switchSubreddit(params[1]);        
        break;
    }
      var controller = Mojo.Controller.getAppController().getActiveStageController();
  var currentScene = controller.activeScene();

  switch(event.type) {
    case Mojo.Event.commandEnable:
        switch (event.command) {
          case Mojo.Menu.prefsCmd:
            if(!currentScene.assistant.prefsMenuDisabled)
                event.stopPropagation();
            break;
          case Mojo.Menu.helpCmd:
            if(!currentScene.assistant.helpMenuDisabled)
                event.stopPropagation();
            break;
        }
        break;
    case Mojo.Event.command:
      switch (event.command) {
        case Mojo.Menu.helpCmd:
          controller.pushScene('support');
          break;

        case Mojo.Menu.prefsCmd:
          AppAssistant.cloneCard(this, {name:"prefs"}, {});
          break;

        case 'login-cmd':
          controller.pushScene({name:"login",transition: Mojo.Transition.crossFade});
          break;
          
        case 'logout-cmd':
          new User(this).logout({});          
          break;

        case 'register-cmd':
          controller.pushScene({name:"register",transition: Mojo.Transition.crossFade});
          break;

        case 'reddits-cmd':
          AppAssistant.cloneCard(this, {name:"reddits"}, {});
          break;

        case 'gallery-cmd':
          AppAssistant.cloneCard(this, {name:"gallery"}, {});
          break;
          
        case 'recent-comments-cmd':
          AppAssistant.cloneCard(this, {name:"recent-comment"}, {});
          break;
          
        case 'messages-cmd':
          AppAssistant.cloneCard(this, {name:"message"}, {});
          break;
      }
    break;
  }
  }

});
