
RecentCommentAssistant = Class.create(PowerScrollBase, {

  initialize: function($super, params) {
    $super();
    this.params = params;
    this.commentModel = { items : [] };
    this.comments = [];
  },

  setup: function() {
    StageAssistant.setTheme(this);
    
    this.controller.setupWidget("list", {
    itemTemplate : "recent-comment/comment",
    formatters: {
                 body: this.bodyFormatter.bind(this),
                 indent: this.indentFormatter.bind(this),
                 shadowindent: this.shadowindentFormatter.bind(this)}
    }, this.commentModel);

    /* add event handlers to listen to events from widgets */

    this.itemTappedBind = this.itemTapped.bind(this);

    Mojo.Event.listen(this.controller.get("list"), Mojo.Event.listTap, this.itemTappedBind);
  },

  activate: function($super, event) {
    $super();
    StageAssistant.defaultWindowOrientation(this, "free");
    
    if (this.commentModel.items.length == 0) {
      this.fetchRecentComments();
    }
    
    this.timerID = this.controller.window.setInterval(this.tick.bind(this),5000);
  },

  deactivate: function($super, event) {
    $super();
    this.controller.window.clearInterval(this.timerID);
  },

  cleanup: function(event) {
    this.controller.window.clearInterval(this.timerID);
    Request.clear_all();

    Mojo.Event.stopListening(this.controller.get("list"), Mojo.Event.listTap, this.itemTappedBind);
  },
  
  tick: function() {
    var current_seconds = (new Date()).getTime() / 1000;
    
    if (this.starting_second == undefined) {
      this.starting_second = current_seconds;
    }
    
    if (this.last_poll_second == undefined) {
      this.last_poll_second = current_seconds;
    }
    
    if ((current_seconds - this.last_poll_second) > 5) {
      this.fetchRecentComments();
    }
    
    this.updateList();
  },

  bodyFormatter: function(propertyValue, model) {
    if ((model.kind != 't1') && (model.kind != 't3')) {
      if (model.kind == 'more') {
        return "load more comments";
      }
      
      return "";
    }
    
    var content = "";

    if (model.data.selftext) {
      content = model.data.selftext;
    }
    else {
      content = model.data.body;
    }

    if (!content) {
      return "";
    }

    content = content.replace(/\n/gi, "<br/>");
    content = content.replace(/\[([^\]]*)\]\(([^\)]+)\)/gi, "<a class='linky' onClick=\"return false;\" href='$2'>$1</a>");
    return content;
  },

  indentFormatter: function(propertyValue, model) {
    if ((model.kind != 't1') && (model.kind != 'more')) {
      return "";
    }
    
    return 6 + 10 * model.data.indent + "";
  },

  shadowindentFormatter: function(propertyValue, model) {
    if ((model.kind != 't1') && (model.kind != 'more')) {
      return "";
    }
    
    return 12 + 10 * model.data.indent + "";
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

  handleCommentActionSelection: function(command) {
    if (command == undefined) {
      return;
    }

    var params = command.split(' ');

    if (params[0] == 'view-cmd') {
      //this.controller.stageController.popScenesTo("user", {linky:params[1]});
      this.controller.stageController.pushScene({name:"user",transition: Mojo.Transition.crossFade},{linky:params[1]});
    }
  },

  populateComments: function(object) {
    for (var j = 0; j < object.data.children.length; j++) {
      var comment = object.data.children[j];
      
      comment.data.indent = 0;
      this.comments.push(comment);
    }
    
    this.comments.reverse();
  },
  
  newestTimestamp: function() {
    if (this.commentModel.items.length == 0) {
      return 0;
    }
    
    return this.commentModel.items[0].data.created_utc;
  },
  
  updateList: function() {
    if (this.comments.length == 0) {
      return;
    }
    
    var new_entries = false;
    var counter = 0;
    
    for (var i = 0; i < this.comments.length; i++) {
      if (this.comments[i].data.created_utc > this.newestTimestamp()) {
        counter++;
        new_entries = true;
        this.commentModel.items.unshift(this.comments[i]);
      }            
    }
    
    //new Banner(counter + " new entries").send();
    
    //this.comments.clear();
    
    if (new_entries) {
     // this.controller.modelChanged(this.commentModel);
      this.controller.get('list').mojo.setLength(this.commentModel.items.length);
      this.controller.get('list').mojo.noticeUpdatedItems(0, this.commentModel.items);
    }
  },

  fetchRecentComments: function() {
    new Comment(this).recent({limit: 1});
  },

  handlefetchCommentsResponse: function(response) {
//    if (response.responseJSON[0].data.modhash != "") {
//      this.modhash = response.responseJSON[0].data.modhash;
//    }

    var myObj = response.responseJSON;

    this.populateComments(myObj);
  },

  handleCallback: function(params) {
    if (!params || !params.success) {
      return params;
    }

    if (params.type == "comment-recent") {
      this.handlefetchCommentsResponse(params.response);
    }
  },

  itemTapped: function(event) {
    var comment = event.item;
    var element_tapped = event.originalEvent.target;
    var index = 0;
    var url = null;

    if (element_tapped.className == 'linky') {
      event.originalEvent.stopPropagation();
      event.stopPropagation();

      var linky = Linky.parse(element_tapped.href);

      if (linky.type == 'image') {
        AppAssistant.cloneCard(this, {name:"image",transition: Mojo.Transition.crossFade},{index: 0,images:[linky.url]});        
      }
      else if ((linky.type == 'youtube_video') || (linky.type == 'web')) {
        this.controller.serviceRequest("palm://com.palm.applicationManager", {
          method : "open",
          parameters : {
            target : linky.url,
            onSuccess : function() {  },
            onFailure : function() {  }
          }
        });
      }

      return;
    }

    if (element_tapped.id.indexOf('image_') != -1) {
      if (element_tapped.className == 'reddit_thumbnail') {
        AppAssistant.cloneCard(this, {name:"image",transition: Mojo.Transition.crossFade},{index: 0,images:[Linky.parse(comment.data.url).url]});
      }
      else {
        index = element_tapped.id.match(/_(\d+)_/g)[0].replace(/_/g,'');
        index = parseInt(index);
        AppAssistant.cloneCard(this, {name:"image",transition: Mojo.Transition.crossFade},{index: index,images: StageAssistant.parseImageUrls(comment.data.body)});
      }
      return;
    }

    if ((element_tapped.id.indexOf('web_') != -1) || (element_tapped.id.indexOf('youtube_') != -1)) {
      if (element_tapped.className == 'reddit_thumbnail') {
        url = Linky.parse(comment.data.url).url;
      }
      else {
        index = element_tapped.id.match(/_(\d+)_/g)[0].replace(/_/g,'');
        url = StageAssistant.parseUrls(comment.data.body)[index].url;
      }     

      this.controller.serviceRequest("palm://com.palm.applicationManager", {
        method : "open",
        parameters : {
          target : url,
          onSuccess : function() {  },
          onFailure : function() {  }
        }
        });

      return;
    }

    this.controller.popupSubmenu({
               onChoose: this.handleCommentActionSelection.bind(this),
               placeNear:element_tapped,
               items: [{label: $L('View Posts'), command: 'view-cmd ' + comment.data.author}]
               });
  }

});
