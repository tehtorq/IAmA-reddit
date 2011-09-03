
ArticleAssistant = Class.create(PowerScrollBase, {

  initialize: function($super, params) {
    $super();
    this.params = params;
    this.url = 'http://reddit.com';

    if (params.article) {
      this.original_article = params.article;
      this.article = params.article.data;      
      this.url += this.article.permalink;
      this.params.title = this.article.title;
    }
    else {
      this.url += params.url;
    }
    
    this.comments = { items : [] };
  },

  setup: function() {
    StageAssistant.setTheme(this);
    
    this.controller.setupWidget("spinner",
      this.attributes = {},
      this.model = {spinning: true}
    ); 
      
    this.spinSpinner(false);
    
    this.controller.setupWidget('sub-menu', null, {items: [
      {label:$L("sorted by"), items: [{label:$L("hot"), command:$L("sort hot")},
                                          {label:$L("new"), command:$L("sort new")},
                                          {label:$L("controversial"), command:$L("sort controversial")},
                                          {label:$L("top"), command:$L("sort top")},
                                          {label:$L("old"), command:$L("sort old")},
                                          {label:$L("best"), command:$L("sort confidence")}]},
      {label:$L("show"), items: [{label:$L("top 200 comments"), command:$L("show 200")},
                                {label:$L("top 500 comments"), command:$L("show 500")}]},
      {label:$L("share"), items: [{label:$L("email"), command:$L("email-cmd")},
                                {label:$L("sms"), command:$L("sms-cmd")}]},
      {label:$L("related"), command:$L("related")},
      {label:$L("other discussions"), command:$L("duplicates")},
      {label:$L("save"), command:$L("save-cmd")},
      ]});

    this.viewMenuModel = {
      visible: true,
      items: [
          {items:[{},
                  { label: this.params.title.substr(0, 40), command: 'top', icon: "", width: Mojo.Environment.DeviceInfo.screenWidth - 60},
                  {submenu: "sub-menu", width: 60, iconPath: 'images/options.png'},
                  {}]}
      ]
    };

    this.controller.setupWidget(Mojo.Menu.viewMenu, { menuClass:'no-fade' }, this.viewMenuModel);
    
    
    if (this.article) {
      this.comments.items.push({kind: 't3', data: this.article});
    }

    this.controller.setupWidget("comment-list", {
    itemTemplate : "article/comment",
    formatters: {time: this.timeFormatter.bind(this),
                 body: this.bodyFormatter.bind(this),
                 score: this.scoreFormatter.bind(this),
                 vote: this.voteFormatter.bind(this),
                 easylinks: this.easylinksFormatter.bind(this),
                 cssclass: this.cssclassFormatter.bind(this),
                 tagClass: this.tagClassFormatter.bind(this),
                 indent: this.indentFormatter.bind(this),
                 thumbnail: this.thumbnailFormatter.bind(this),
                 shadowindent: this.shadowindentFormatter.bind(this)}
    }, this.comments);

    this.controller.setupWidget("loadMoreButton", {type:Mojo.Widget.activityButton}, {label : "Loading replies", disabled: true});

    /* add event handlers to listen to events from widgets */

    this.itemTappedBind = this.itemTapped.bind(this);

    Mojo.Event.listen(this.controller.get("comment-list"), Mojo.Event.listTap, this.itemTappedBind);
  },

  activate: function($super, event) {
    $super();
    StageAssistant.defaultWindowOrientation(this, "free");
    
    if (event != undefined) {
      if (event.replied == true) {
        var item = this.comments.items[0];
        this.comments.items.clear();
        this.comments.items.push(item);
        this.jump_to_comment = event.comment_id;
      }
    }
    
    if (this.comments.items.length < 2) {
      //Mojo.Log.info("reloading comments");
      this.controller.get('loadMoreButton').mojo.activate();
      this.fetchComments({});
    }
    else {
      //Mojo.Log.info("not reloading comments");
    }
  },
  
  findArticleIndex: function(article_name) {
    var length = this.comments.items.length;
    var items = this.comments.items;
    
    for (var i = length - 1; i >= 0; i--) {
      if (items[i].data.name == article_name) {
        return i;
      }
    }
    
    return -1;
  },
  
  loadComments: function(params) {
    var item = this.comments.items[0];
    this.comments.items.clear();
    this.comments.items.push(item);
    
    this.controller.modelChanged(this.comments);
    this.controller.get('loadMoreButton').mojo.activate();
    this.controller.get('loadMoreButton').show();
    this.fetchComments(params);
  },

  deactivate: function($super, event) {
    $super();
  },

  cleanup: function(event) {
    Request.clear_all();

    Mojo.Event.stopListening(this.controller.get("comment-list"), Mojo.Event.listTap, this.itemTappedBind);
  },

  timeFormatter: function(propertyValue, model) {
    if ((model.kind != 't1') && (model.kind != 't3')) {
      return "";
    }
    
    return StageAssistant.timeFormatter(model.data.created_utc);
  },

  bodyFormatter: function(propertyValue, model) {
    if ((model.kind != 't1') && (model.kind != 't3')) {
      if (model.kind == 'more') {
        return "load more comments";
      }
      
      return "";
    }
    
    var content = "";

    if (model.data.selftext_html) {
      content = model.data.selftext_html;
    }
    else {
      //content = model.data.body;
      content = model.data.body_html;
    }

    if (!content) {
      return "";
    }
    
    content = content.unescapeHTML();

    //content = content.replace('<a ', '<a class="linky" ');
    //content = content.replace(/\[([^\]]*)\]\(([^\)]+)\)/gi, "<a class='linky' onClick=\"return false;\" href='$2'>$1</a>");
    return content;
  },

  scoreFormatter: function(propertyValue, model) {
    if ((model.kind != 't1') && (model.kind != 't3')) {
      return "";
    }
    
    return (model.data.ups - model.data.downs) + " points";
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
  
  tagClassFormatter: function(propertyValue, model) {
    if ((model.kind != 't1') && (model.kind != 't3')) {
      return "";
    }
    
    return (model.data.author == this.article.author) ? 'comment_tag' : 'comment_tag_hidden';
  },

  cssclassFormatter: function(propertyValue, model) {
    if ((model.kind != 't1') && (model.kind != 't3')) {
      if (model.kind == 'more') {
        return "load_more_comment";
      }
      
      return "";
    }
    
    return 'reddit_comment';
  },

  indentFormatter: function(propertyValue, model) {
    if ((model.kind != 't1') && (model.kind != 'more')) {
      return "";
    }
    
    return 4 + 6 * model.data.indent + "";
  },

  shadowindentFormatter: function(propertyValue, model) {
    if ((model.kind != 't1') && (model.kind != 'more')) {
      return "";
    }
    
    return 8 + 6 * model.data.indent + "";
  },

  thumbnailFormatter: function(propertyValue, model) {
    if ((model.kind != 't1') && (model.kind != 't3')) {
      return "";
    }
    
    var image_link = null;

    if ((model.data.thumbnail) && (model.data.thumbnail != "")) {
      image_link = model.data.thumbnail;

      if (image_link.indexOf('/static/') != -1) {
        image_link = 'http://reddit.com' + image_link;
      }
    }

    if (model.data.url) {
      var linky = Linky.parse(model.data.url);

      if (linky.type == 'image') {
        if (!image_link) {
          image_link = './images/picture.png';
        }

        return '<img class="reddit_thumbnail" src="'+image_link+'" alt="Loading" id="image_'+model.data.id+'">';
      }
      else if (linky.type == 'youtube_video') {
        if (!image_link) {
          image_link = './images/youtube.png';
        }

        return '<img class="reddit_thumbnail" src="'+image_link+'" alt="Loading" id="youtube_'+model.data.id+'">';
      }
      else if (linky.type == 'web') {
        if (linky.url.indexOf('http://www.reddit.com/') === -1) {
          if (!image_link) {
            image_link = './images/web.png';
          }

          return '<img class="reddit_thumbnail" src="'+image_link+'" alt="Loading" id="web_'+model.data.id+'">';
        }
      }
    }

    return "";
  },

  easylinksFormatter: function(propertyValue, model) {
    if ((model.kind != 't1') && (model.kind != 't3')) {
      return "";
    }
    
    var hide_thumbnails = StageAssistant.cookieValue("prefs-hide-easylinks", "off");
    
    if (hide_thumbnails == "on") {
      return "";
    }
    
    var id = model.data.id;
    var urls = StageAssistant.parseUrls(model.data.body);

    if (!urls) {
      return "";
    }

    //urls = urls.unique(); // FIX - unique doesnt work

    var image_url_html = "";
    var imagecount = 0;

    for (var i = 0; i < urls.length; i++) {
      var url = urls[i];
      var image_link = "";

      // check if its a link to image

      if (url.type == 'image') {
        //this.images.push(url.url);
        image_link = './images/picture.png';
        image_url_html += '<img class="reddit_embedded_link" src="'+image_link+'" alt="Loading" id="image_'+imagecount+'_'+ id + '">';
        imagecount++;
      }
      else if (url.type == 'youtube_video') {
        image_link = './images/youtube.png';
        image_url_html += '<img class="reddit_embedded_link" src="'+image_link+'" alt="Loading" id="youtube_'+i+'_'+ id + '">';
      }
      else if (url.type == 'web') {
        image_link = './images/web.png';
        image_url_html += '<img class="reddit_embedded_link" src="'+image_link+'" alt="Loading" id="web_'+i+'_'+ id + '">';
      }
    }

    return image_url_html;
  },

  handleCommand: function(event) {
    if (event.type == Mojo.Event.command) {
      switch (event.command) {
        case 'top':
          this.scrollToTop();
          break;
        case 'save-cmd':
          this.saveArticle();
          break;
        case 'email-cmd':
          this.mailArticle();
          break;
        case 'sms-cmd':
          this.smsArticle();
          break;
        case 'show 200':
          this.loadComments({limit: 200});
          break;
        case 'show 500':
          this.loadComments({limit: 500});
          break;
        case 'related':
        case 'duplicates':
          var url = this.url.replace(/\/comments\//, '/'+event.command+'/').replace('http://www.reddit.com/', '').replace('http://reddit.com/', '');          
          AppAssistant.cloneCard(this, {name:"frontpage"},{permalink:url});          
          break;
        case 'sort hot':
        case 'sort new':
        case 'sort controversial':
        case 'sort top':
        case 'sort old':
        case 'sort best':
          var params = event.command.split(' ');
          this.loadComments({sort: params[1]});
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

    if (params[0] == 'reply-cmd') {
      this.controller.stageController.pushScene({name:"reply",transition: Mojo.Transition.crossFade}, {thing_id:params[1], user:params[2], modhash:this.modhash, subreddit:params[4]});
    }
    else if (params[0] == 'view-cmd') {
      //this.controller.stageController.popScenesTo("user", {linky:params[1]});
      this.controller.stageController.pushScene({name:"user",transition: Mojo.Transition.crossFade},{linky:params[1]});
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
  },
  
  spinSpinner: function(bool) {
    if (bool) {
      this.controller.get('loading').show();
    }
    else {
      this.controller.get('loading').hide();
    }
  },

  populateComments: function(object) {
    if (this.article == null) {
      this.article = object[0].data.children[0].data;
      this.comments.items.push({kind: 't3', data: object[0].data.children[0].data});
      this.controller.modelChanged(this.comments);
    }
    
    this.populateReplies(object[1].data.children, 0);
    
    this.controller.get('comment-list').mojo.setLength(this.comments.items.length);
    this.controller.get('comment-list').mojo.noticeUpdatedItems(0, this.comments.items);
  },

  populateReplies: function(replies, indent) {
    for (var j = 0; j < replies.length; j++) {
      var child = replies[j];
      
      if (child.kind == 'more') {
        continue;
      }
      
      child.data.indent = indent;
      this.comments.items.push(child);
      
      var data = child.data;
      
      if ((data.replies != null) && (data.replies != "")) {
        if (data.replies.data) {
          if (data.replies.data.children) {
            this.populateReplies(data.replies.data.children, indent+1);
          }
        }
      }
    }
  },

  fetchComments: function(params) {
    params.url = this.url + '.json';    
    new Article(this).comments(params);
  },

  handlefetchCommentsResponse: function(response) {
    if (response.responseJSON[0].data.modhash != "") {
      this.modhash = response.responseJSON[0].data.modhash;
    }

    var myObj = response.responseJSON;

    this.populateComments(myObj);
    this.controller.get('loadMoreButton').hide();
    
    if (this.jump_to_comment != undefined) {
      this.controller.getSceneScroller().mojo.revealElement(this.jump_to_comment);
      this.jump_to_comment = null;
    }
  },

  handleCallback: function(params) {
    if (!params || !params.success) {
      return params;
    }
    
    this.spinSpinner(false);
    
    params.type = params.type.split(' ');
    var index = -1;

    if (params.type[0] == "comment-upvote") {
      index = this.findArticleIndex(params.type[1]);
      
      if (index > -1) {
        if (this.comments.items[index].data.likes === false) {
          this.comments.items[index].data.downs--;
        }

        this.comments.items[index].data.likes = true;
        this.comments.items[index].data.ups++;
        this.controller.get('comment-list').mojo.noticeUpdatedItems(index, [this.comments.items[index]]);
      }
      
      new Banner("Upvoted!").send();
    }
    else if (params.type[0] == "comment-downvote") {
      index = this.findArticleIndex(params.type[1]);
      
      if (index > -1) {
        if (this.comments.items[index].data.likes === true) {
          this.comments.items[index].data.ups--;
        }

        this.comments.items[index].data.likes = false;
        this.comments.items[index].data.downs++;
        this.controller.get('comment-list').mojo.noticeUpdatedItems(index, [this.comments.items[index]]);
      }
      
      new Banner("Downvoted!").send();
    }
    else if (params.type[0] == "comment-vote-reset") {
      index = this.findArticleIndex(params.type[1]);
      
      if (index > -1) {
        if (this.comments.items[index].data.likes === true) {
          this.comments.items[index].data.ups--;
        }
        else {
          this.comments.items[index].data.downs--;
        }

        this.comments.items[index].data.likes = null;      
        this.controller.get('comment-list').mojo.noticeUpdatedItems(index, [this.comments.items[index]]);
      }
      
      new Banner("Vote reset!").send();
    }
    else if (params.type[0] == "article-save") {
      new Banner("Saved!").send();
    }
    else if (params.type[0] == "article-comments") {
      this.handlefetchCommentsResponse(params.response);
    }
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

  mailArticle: function() {
    this.controller.serviceRequest(
        "palm://com.palm.applicationManager", {
            method: 'open',
            parameters: {
                id: "com.palm.app.email",
                params: {
                    summary: this.article.title,
                    text: 'http://reddit.com' + this.article.data.permalink,
                    recipients: [{
                        type:"email",
                        role:1,
                        value:"",
                        contactDisplay:""
                    }]
                }
            }
        }
    );
  },

  smsArticle: function() {
    this.controller.serviceRequest(
        "palm://com.palm.applicationManager", {
            method: 'open',
            parameters: {
                id: "com.palm.app.messaging",
                params: {
                    messageText: this.article.title + "\n\n" + 'http://reddit.com' + this.article.data.permalink
                }
            }
        }
    );
  },

  saveArticle: function() {
    var params = {executed: 'saved',
                    id: this.article.name,
                    uh: this.modhash,
                    renderstyle: 'html'};

    new Article(this).save(params);
  },
  
  isLoggedIn: function() {
    return (this.modhash && this.modhash != "");
  },

  itemTapped: function(event) {
    var comment = event.item;
    var element_tapped = event.originalEvent.target;
    var index = 0;
    var url = null;
    
    // handle links & spoilers
    
    if (element_tapped.tagName == 'A') {
      if ((element_tapped.href == 'file:///s') || (element_tapped.href == 'file:///b') || (element_tapped.href == 'file:///?')) {
        element_tapped.update(element_tapped.title);
      }
      else {
        if (element_tapped.title && element_tapped.title.length > 0) {
          this.controller.showAlertDialog({   
            /*title: "Title",*/
            message: element_tapped.title,
            choices:[    
              {label: "Ok", value:"", type:'dismiss'}    
            ]
          });
        }
      }
      
      return;
    }
    
    // click on OP tag to jump to next comment by OP
    
    if (element_tapped.className == 'comment_tag') {
      index = event.index;
      var author = comment.data.author;
      
      while (true) {
        index++;
        
        if (index == this.comments.items.length) {
          index = 0;
        }
        
        if (this.comments.items[index].data.author && (this.comments.items[index].data.author == author)) {
          this.controller.get('comment-list').mojo.revealItem(index, true);
          return;          
        }
      }
      
      return;
    }

    if (element_tapped.className == 'linky') {
      //event.originalEvent.stopPropagation();
      //event.stopPropagation();

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
        StageAssistant.cloneImageCard(this, this.original_article);
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
        //        Mojo.Log.info("wtf!!");
        //Mojo.Log.info(element_tapped.id + "wtf!!");
        index = element_tapped.id.match(/_(\d+)_/g)[0].replace(/_/g,'');
        
        var urls = StageAssistant.parseUrls(comment.data.body);
        //Mojo.Log.info(comment.data.body);
        //Mojo.Log.info(Object.toJSON(urls));
        
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
    
    if (this.isLoggedIn()) {    
      var upvote_icon = (comment.data.likes === true) ? 'selected_upvote_icon' : 'upvote_icon';
      var downvote_icon = (comment.data.likes === false) ? 'selected_downvote_icon' : 'downvote_icon';
      var upvote_action = (comment.data.likes === true) ? 'reset-vote-cmd' : 'upvote-cmd';
      var downvote_action = (comment.data.likes === false) ? 'reset-vote-cmd' : 'downvote-cmd';

      this.controller.popupSubmenu({
                 onChoose: this.handleCommentActionSelection.bind(this),
                 placeNear:element_tapped,
                 items: [                         
                   {label: $L('Upvote'), command: upvote_action + ' ' + comment.data.name + ' ' + comment.data.subreddit, secondaryIcon: upvote_icon},
                   {label: $L('Downvote'), command: downvote_action + ' ' + comment.data.name + ' ' + comment.data.subreddit, secondaryIcon: downvote_icon},
                   {label: $L('Reply'), command: 'reply-cmd ' + comment.data.name + ' ' + comment.data.author + ' ' + this.url + ' ' + comment.data.subreddit},
                   {label: $L(comment.data.author), command: 'view-cmd ' + comment.data.author}]
                 });
    }
    else {
      this.controller.popupSubmenu({
                 onChoose: this.handleCommentActionSelection.bind(this),
                 placeNear:element_tapped,
                 items: [
                   {label: $L(comment.data.author), command: 'view-cmd ' + comment.data.author}]
                 });     
    }
  }

});
