
RedditsAssistant = Class.create({

  initialize: function() {
    this.reddit_api = new RedditAPI();
    this.redditsModel = { items : [] };
  },

  handleCommand: function(event) {
    if (event.type == Mojo.Event.command) {
      switch (event.command) {
        case 'login-cmd':
          this.controller.stageController.pushScene({name:"login",transition: Mojo.Transition.crossFade});
          break;

        case 'frontpage-cmd':
          this.controller.stageController.popScene({name:"frontpage",disableSceneScroller:true});
          break;

        case 'gallery-cmd':
          this.controller.stageController.swapScene({name:"gallery",disableSceneScroller:true,transition: Mojo.Transition.crossFade}, {subreddit:this.reddit_api.subreddit});
          break;

        case 'popular-cmd':
          this.handleCategorySwitch('popular');
          break;

        case 'new-cmd':
          this.handleCategorySwitch('new');
          break;

        case 'mine-cmd':
          this.handleCategorySwitch('mine');
          break;
      }
    }
  },

  setup: function() {
    StageAssistant.setTheme(this);
    
    this.controller.setupWidget("spinner",
      this.attributes = {},
      this.model = {spinning: true}
    ); 
    
    this.controller.setupWidget(Mojo.Menu.commandMenu, { menuClass:'no-fade' },
                                          {items : [
      { toggleCmd : "popular-cmd",
        items : [
          {},
          { label : "Popular", command : "popular-cmd" },
          { label : "New", command : "new-cmd" },
          { label : "Mine", command : "mine-cmd" },
          {}
        ]
      }
    ]});

    this.spinnerModel = {spinning: false};
  this.controller.setupWidget("progressSpinner",
     this.attributes = {
              spinnerSize: 'large',
              superClass: 'palm-activity-indicator-large',
              fps: 60,
              startLastFrame: 0,
              mainFrameCount: 12,
              frameHeight: 128
       },
       this.spinnerModel);

    this.controller.setupWidget(Mojo.Menu.appMenu, {}, {
      visible: true,
      items: [
          {label: "Login", command: 'login-cmd'},
          {label: "Frontpage", command: 'frontpage-cmd'},
          {label: "Gallery", command: 'gallery-cmd'}
      ]
    });

    this.controller.setupWidget("reddit-list", {
      itemTemplate : "reddits/reddit",
      emptyTemplate : "reddits/emptylist",
      nullItemTemplate: "list/null_item_template",
      swipeToDelete: true,
      //reorderable: true,
      preventDeleteProperty: 'prevent_delete',
      lookahead : 25,
      renderLimit : 1000
    }, this.redditsModel);

    this.activityButtonModel = {label : "Load more"};
    this.controller.setupWidget("loadMoreButton", {type:Mojo.Widget.activityButton}, this.activityButtonModel);
    this.controller.get('loadMoreButton').hide();

    this.controller.setupWidget('filterfield', {delay: 2000});

    this.controller.listen('filterfield', Mojo.Event.filter, this.filter.bind(this));

    /* add event handlers to listen to events from widgets */

    this.itemTappedBind = this.itemTapped.bind(this);
    this.loadMoreRedditsBind = this.loadMoreReddits.bind(this);
    this.handleDeleteItemBind = this.handleDeleteItem.bind(this);
    //this.handleCategorySwitchBind = this.handleCategorySwitch.bind(this);

    //Mojo.Event.listen(this.controller.get('category-list'),Mojo.Event.listTap, this.handleCategorySwitchBind);
    Mojo.Event.listen(this.controller.get("reddit-list"), Mojo.Event.listTap, this.itemTappedBind);
    Mojo.Event.listen(this.controller.get("loadMoreButton"), Mojo.Event.tap, this.loadMoreRedditsBind);
    Mojo.Event.listen(this.controller.get("reddit-list"), Mojo.Event.listDelete, this.handleDeleteItemBind);
  },

  handleCategorySwitch: function(category) {
    this.reddit_api.setRedditsCategory(category);
    this.loadReddits();
  },

  activate: function(event) {
    StageAssistant.defaultWindowOrientation(this, "free");

    if (this.redditsModel.items.length == 0) {
      this.loadReddits();
    }
  },

  deactivate: function(event) {},

  cleanup: function(event) {
    Request.clear_all();

    Mojo.Event.stopListening(this.controller.get("reddit-list"), Mojo.Event.listTap, this.itemTappedBind);
    Mojo.Event.stopListening(this.controller.get("reddit-list"), Mojo.Event.listDelete, this.handleDeleteItemBind);
    Mojo.Event.stopListening(this.controller.get("loadMoreButton"), Mojo.Event.tap, this.loadMoreRedditsBind);
  },

  filter: function(filterEvent) {
    if (filterEvent.filterString.length == 0) {
      return;
    }

    this.controller.get('filterfield').mojo.close();
    this.searchReddits(filterEvent.filterString);
  },

  searchReddits: function(searchTerm) {
    this.reddit_api.setRedditsSearchTerm(searchTerm);
    //this.updateHeading(searchTerm);
    this.loadReddits();
  },
  
  spinSpinner: function(bool) {
    if (bool) {
      this.controller.get('loading').show();
    }
    else {
      this.controller.get('loading').hide();
    }
  },

  handleCallback: function(params) {
    if (!params || !params.success) {
      return params;
    }
    
    params.type = params.type.split(' ');

    if (params.type[0] == "subreddit-subscribe") {
      if (params.type[1]) {
        for (var i = 0; i < Subreddit.cached_list.length; i++) {
          if (Subreddit.cached_list[i].name == params.type[1]) {
            Subreddit.cached_list[i].subscribed = true;                  
          }
        }        
      }
      
      new Banner("Subscribed!").send();
    }
    else if (params.type[0] == "subreddit-unsubscribe") {
      if (params.type[1]) {
        for (var i = 0; i < Subreddit.cached_list.length; i++) {
          if (Subreddit.cached_list[i].name == params.type[1]) {
            Subreddit.cached_list[i].subscribed = false;                  
          }
        }        
      }
      
      new Banner("Unsubscribed!").send();
    }
    else if (params.type[0] == "subreddit-load") {
      this.handleLoadRedditsResponse(params.response);
    }
  },

  subscribe: function(subreddit_name) {
    var params = {action: 'sub',
                  sr: subreddit_name,
                  uh: this.modhash};

    new Subreddit(this).subscribe(params);
  },

  unsubscribe: function(subreddit_name) {
    var params = {action: 'unsub',
                  sr: subreddit_name,
                  uh: this.modhash};

    new Subreddit(this).unsubscribe(params);
  },

  handleDeleteItem: function(event) {
    this.unsubscribe(event.item.name);
  },

  loadMoreReddits: function() {
    this.loadReddits();
  },

  loadReddits: function() {
    var parameters = {};
    parameters.limit = 25;
    
    if (this.reddit_api.last_reddit) {
      parameters.after = this.reddit_api.last_reddit;
      this.displayButtonLoading();
    }
    else {
      this.controller.get('loadMoreButton').hide();
      this.spinSpinner(true);
      this.controller.get('reddit-list').mojo.noticeRemovedItems(0, this.controller.get('reddit-list').mojo.getLength());
    }
    
    if (this.reddit_api.search != null) {
      parameters.q = this.reddit_api.search;
      parameters.restrict_sr = 'off';
      parameters.sort = 'relevance';
    }
    
    parameters.url = this.reddit_api.getRedditsUrl();
    
    new Subreddit(this).fetch(parameters);
  },

  handleLoadRedditsResponse: function(response) {
    this.modhash = response.responseJSON.data.modhash;
    var items = response.responseJSON.data.children;
    var new_items = [];
    new_items.length = 0;
    var length = this.controller.get('reddit-list').mojo.getLength();

    for (var i = 0; i < items.length; i++) {
      
      if (length > 0) { // ugly hack for possible bug in reddits/mine
        if (items[i].data.name === this.last_name) {
          continue;
        }
      }
      
      if (items[i].data.description) {
        items[i].data.description = items[i].data.description.replace(/\n/gi, "<br/>");
        items[i].data.description = items[i].data.description.replace(/\[([^\]]*)\]\(([^\)]+)\)/gi, "<a class='linky' onClick=\"return false;\" href='$2'>$1</a>");
      }

      items[i].data.prevent_delete = (this.reddit_api.reddits_category != 'mine');
      new_items.push(items[i].data);
      this.last_name = items[i].data.name;
    }

    this.controller.get('reddit-list').mojo.noticeAddedItems(length, new_items);
    
    this.spinSpinner(false);
    this.displayButtonLoadMore();
    
    this.reddit_api.last_reddit = response.responseJSON.data.after;

    if (this.reddit_api.last_reddit != null) {
      this.controller.get('loadMoreButton').show();
    }
    else {
      this.controller.get('loadMoreButton').hide();
    }
    
    if (this.controller.get('reddit-list').mojo.getLength() == 0) {
      this.controller.get('reddit-list').mojo.noticeAddedItems(0, [null]);
    }
  },

  displayButtonLoadMore: function() {
    this.controller.get('loadMoreButton').mojo.deactivate();
    this.activityButtonModel.label = "Load more";
    this.activityButtonModel.disabled = false;
    this.controller.modelChanged(this.activityButtonModel);
  },

  displayButtonLoading: function() {
    this.controller.get('loadMoreButton').mojo.activate();
    this.activityButtonModel.label = "Loading";
    this.activityButtonModel.disabled = true;
    this.controller.modelChanged(this.activityButtonModel);
  },

  itemTapped: function(event) {
    var item = event.item;
    var element_tapped = event.originalEvent.target;

    if (element_tapped.className == 'linky') {
      var linky = Linky.parse(element_tapped.href);

      if (linky.subtype == 'reddit') {
        this.controller.stageController.swapScene({name:"frontpage",transition: Mojo.Transition.crossFade},{reddit:linky.reddit});
        return;
      }

      return;
    }

    if (element_tapped.className == 'comment_counter') {
      this.controller.get("drawer_" + item.name).toggleClassName('toggle_hidden');
      return;
    }
    
    if (this.isLoggedIn()) {
      var edit_option = '+frontpage';
      var edit_action = 'frontpage-add-cmd';
      
      for (var i = 0; i < Subreddit.cached_list.length; i++) {
        if ((Subreddit.cached_list[i].label == item.display_name) && (Subreddit.cached_list[i].subscribed == true)) {
          edit_option = '-frontpage';
          edit_action = 'frontpage-remove-cmd';          
        }
      }
      
      this.controller.popupSubmenu({
               onChoose: this.handleActionCommand.bind(this),
               placeNear:element_tapped,
               items: [{label: $L('Visit'), command: 'view-cmd ' + item.display_name},
                         {label: $L(edit_option), command: edit_action + ' ' + item.name}]
      });
    }
    else {
      this.controller.popupSubmenu({
               onChoose: this.handleActionCommand.bind(this),
               placeNear:element_tapped,
               items: [{label: $L('Visit'), command: 'view-cmd ' + item.display_name}]
      });      
    }
  },
  
  isLoggedIn: function() {
    return (this.modhash && this.modhash != "");
  },

  handleActionCommand: function(command) {
    if (command == undefined) {
      return;
    }

    var params = command.split(' ');

    if (params[0] == 'view-cmd') {
      this.controller.stageController.swapScene({name:"frontpage",transition: Mojo.Transition.crossFade},{reddit:params[1]});
    }
    else if (params[0] == 'frontpage-add-cmd') {
      this.subscribe(params[1]);
    }
    else if (params[0] == 'frontpage-remove-cmd') {
      this.unsubscribe(params[1]);
    }
  }

});
