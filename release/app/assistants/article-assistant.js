var ArticleAssistant;
var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
  for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
  function ctor() { this.constructor = child; }
  ctor.prototype = parent.prototype;
  child.prototype = new ctor;
  child.__super__ = parent.prototype;
  return child;
};
ArticleAssistant = (function() {
  __extends(ArticleAssistant, PowerScrollBase);
  function ArticleAssistant(params) {
    this.easylinksFormatter = __bind(this.easylinksFormatter, this);
    this.thumbnailFormatter = __bind(this.thumbnailFormatter, this);
    this.shadowindentFormatter = __bind(this.shadowindentFormatter, this);
    this.indentFormatter = __bind(this.indentFormatter, this);
    this.cssclassFormatter = __bind(this.cssclassFormatter, this);
    this.tagClassFormatter = __bind(this.tagClassFormatter, this);
    this.voteFormatter = __bind(this.voteFormatter, this);
    this.scoreFormatter = __bind(this.scoreFormatter, this);
    this.bodyFormatter = __bind(this.bodyFormatter, this);
    this.timeFormatter = __bind(this.timeFormatter, this);    ArticleAssistant.__super__.constructor.apply(this, arguments);
    this.params = params;
    this.url = 'http://reddit.com';
    if (params.article != null) {
      this.original_article = params.article;
      this.article = params.article.data;
      this.url += this.article.permalink;
      this.params.title = this.article.title;
    } else {
      this.url += params.url;
    }
    this.comments = {
      items: []
    };
  }
  ArticleAssistant.prototype.setup = function() {
    StageAssistant.setTheme(this);
    this.controller.setupWidget("spinner", this.attributes = {}, this.model = {
      spinning: true
    });
    this.spinSpinner(false);
    this.controller.setupWidget('sub-menu', null, {
      items: [
        {
          label: $L("sorted by"),
          items: [
            {
              label: $L("hot"),
              command: $L("sort hot")
            }, {
              label: $L("new"),
              command: $L("sort new")
            }, {
              label: $L("controversial"),
              command: $L("sort controversial")
            }, {
              label: $L("top"),
              command: $L("sort top")
            }, {
              label: $L("old"),
              command: $L("sort old")
            }, {
              label: $L("best"),
              command: $L("sort confidence")
            }
          ]
        }, {
          label: $L("show"),
          items: [
            {
              label: $L("top 200 comments"),
              command: $L("show 200")
            }, {
              label: $L("top 500 comments"),
              command: $L("show 500")
            }
          ]
        }, {
          label: $L("share"),
          items: [
            {
              label: $L("email"),
              command: $L("email-cmd")
            }, {
              label: $L("sms"),
              command: $L("sms-cmd")
            }
          ]
        }, {
          label: $L("related"),
          command: $L("related")
        }, {
          label: $L("other discussions"),
          command: $L("duplicates")
        }, {
          label: $L("save"),
          command: $L("save-cmd")
        }
      ]
    });
    this.viewMenuModel = {
      visible: true,
      items: [
        {
          items: [
            {}, {
              label: this.params.title.substr(0, 40),
              command: 'top',
              icon: "",
              width: Mojo.Environment.DeviceInfo.screenWidth - 60
            }, {
              submenu: "sub-menu",
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
    if (this.article != null) {
      this.comments.items.push({
        kind: 't3',
        data: this.article
      });
    }
    this.controller.setupWidget("comment-list", {
      itemTemplate: "article/comment",
      formatters: {
        time: this.timeFormatter,
        body: this.bodyFormatter,
        score: this.scoreFormatter,
        vote: this.voteFormatter,
        easylinks: this.easylinksFormatter,
        cssclass: this.cssclassFormatter,
        tagClass: this.tagClassFormatter,
        indent: this.indentFormatter,
        thumbnail: this.thumbnailFormatter,
        shadowindent: this.shadowindentFormatter
      }
    }, this.comments);
    this.controller.setupWidget("loadMoreButton", {
      type: Mojo.Widget.activityButton
    }, {
      label: "Loading replies",
      disabled: true
    });
    this.itemTappedBind = this.itemTapped.bind(this);
    return Mojo.Event.listen(this.controller.get("comment-list"), Mojo.Event.listTap, this.itemTappedBind);
  };
  ArticleAssistant.prototype.activate = function(event) {
    var item;
    ArticleAssistant.__super__.activate.apply(this, arguments);
    StageAssistant.defaultWindowOrientation(this, "free");
    if (event != null) {
      if (event.replied === true) {
        item = this.comments.items[0];
        this.comments.items.clear();
        this.comments.items.push(item);
        this.jump_to_comment = event.comment_id;
      }
    }
    if (this.comments.items.length < 2) {
      this.controller.get('loadMoreButton').mojo.activate();
      return this.fetchComments({});
    }
  };
  ArticleAssistant.prototype.findArticleIndex = function(article_name) {
    var index, items, length;
    length = this.comments.items.length;
    items = this.comments.items;
    index = -1;
    _.each(this.comments.items, function(item, i) {
      if (item.data.name === article_name) {
        return index = i;
      }
    });
    return index;
  };
  ArticleAssistant.prototype.loadComments = function(params) {
    var item;
    item = this.comments.items[0];
    this.comments.items.clear();
    this.comments.items.push(item);
    this.controller.modelChanged(this.comments);
    this.controller.get('loadMoreButton').mojo.activate();
    this.controller.get('loadMoreButton').show();
    return this.fetchComments(params);
  };
  ArticleAssistant.prototype.deactivate = function(event) {
    return ArticleAssistant.__super__.deactivate.apply(this, arguments);
  };
  ArticleAssistant.prototype.cleanup = function(event) {
    Request.clear_all();
    return Mojo.Event.stopListening(this.controller.get("comment-list"), Mojo.Event.listTap, this.itemTappedBind);
  };
  ArticleAssistant.prototype.timeFormatter = function(propertyValue, model) {
    if ((model.kind !== 't1') && (model.kind !== 't3')) {
      return;
    }
    return StageAssistant.timeFormatter(model.data.created_utc);
  };
  ArticleAssistant.prototype.bodyFormatter = function(propertyValue, model) {
    var content;
    if ((model.kind !== 't1') && (model.kind !== 't3')) {
      if (model.kind === 'more') {
        return "load more comments";
      }
      return "";
    }
    content = "";
    if (model.data.selftext_html) {
      content = model.data.selftext_html;
    } else {
      content = model.data.body_html;
    }
    if (!content) {
      return "";
    }
    content = content.unescapeHTML();
    return content;
  };
  ArticleAssistant.prototype.scoreFormatter = function(propertyValue, model) {
    if ((model.kind !== 't1') && (model.kind !== 't3')) {
      return "";
    }
    return (model.data.ups - model.data.downs) + " points";
  };
  ArticleAssistant.prototype.voteFormatter = function(propertyValue, model) {
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
  ArticleAssistant.prototype.tagClassFormatter = function(propertyValue, model) {
    if ((model.kind !== 't1') && (model.kind !== 't3')) {
      return '';
    }
    if (model.data.author === this.article.author) {
      return 'comment_tag';
    } else {
      return 'comment_tag_hidden';
    }
  };
  ArticleAssistant.prototype.cssclassFormatter = function(propertyValue, model) {
    var _ref;
    if ((model.kind !== 't1') && (model.kind !== 't3')) {
      return ("load_more_comment" === (_ref = model.kind) && _ref === 'more');
      return "";
    }
    return 'reddit_comment';
  };
  ArticleAssistant.prototype.indentFormatter = function(propertyValue, model) {
    if ((model.kind !== 't1') && (model.kind !== 'more')) {
      return '';
    }
    return 4 + 6 * model.data.indent + "";
  };
  ArticleAssistant.prototype.shadowindentFormatter = function(propertyValue, model) {
    if ((model.kind !== 't1') && (model.kind !== 'more')) {
      return '';
    }
    return 8 + 6 * model.data.indent + "";
  };
  ArticleAssistant.prototype.thumbnailFormatter = function(propertyValue, model) {
    var image_link, linky;
    if ((model.kind !== 't1') && (model.kind !== 't3')) {
      return '';
    }
    image_link = null;
    if ((model.data.thumbnail != null) && (model.data.thumbnail !== "")) {
      image_link = model.data.thumbnail;
      if (image_link.indexOf('/static/') !== -1) {
        image_link = 'http://reddit.com' + image_link;
      }
    }
    if (model.data.url != null) {
      linky = Linky.parse(model.data.url);
      switch (linky.type) {
        case 'image':
          if (image_link == null) {
            image_link = './images/picture.png';
          }
          return '<img class="reddit_thumbnail" src="' + image_link + '" alt="Loading" id="image_' + model.data.id + '">';
        case 'youtube_video':
          if (image_link == null) {
            image_link = './images/youtube.png';
          }
          return '<img class="reddit_thumbnail" src="' + image_link + '" alt="Loading" id="youtube_' + model.data.id + '">';
        case 'web':
          if (linky.url.indexOf('http://www.reddit.com/') === -1) {
            if (image_link == null) {
              image_link = './images/web.png';
            }
            return '<img class="reddit_thumbnail" src="' + image_link + '" alt="Loading" id="web_' + model.data.id + '">';
          }
      }
    }
    return "";
  };
  ArticleAssistant.prototype.easylinksFormatter = function(propertyValue, model) {
    var hide_thumbnails, id, image_url_html, imagecount, urls;
    if ((model.kind !== 't1') && (model.kind !== 't3')) {
      return '';
    }
    hide_thumbnails = StageAssistant.cookieValue("prefs-hide-easylinks", "off");
    if (hide_thumbnails === "on") {
      return "";
    }
    id = model.data.id;
    urls = StageAssistant.parseUrls(model.data.body);
    if (urls == null) {
      return "";
    }
    image_url_html = "";
    imagecount = 0;
    _.each(urls, function(url) {
      var image_link;
      image_link = "";
      if (url.type === 'image') {
        image_link = './images/picture.png';
        image_url_html += '<img class="reddit_embedded_link" src="' + image_link + '" alt="Loading" id="image_' + imagecount + '_' + id + '">';
        return imagecount++;
      } else if (url.type === 'youtube_video') {
        image_link = './images/youtube.png';
        return image_url_html += '<img class="reddit_embedded_link" src="' + image_link + '" alt="Loading" id="youtube_' + i + '_' + id + '">';
      } else if (url.type === 'web') {
        image_link = './images/web.png';
        return image_url_html += '<img class="reddit_embedded_link" src="' + image_link + '" alt="Loading" id="web_' + i + '_' + id + '">';
      }
    });
    return image_url_html;
  };
  ArticleAssistant.prototype.handleCommand = function(event) {
    var params, url;
    if (event.type !== Mojo.Event.command) {
      return;
    }
    switch (event.command) {
      case 'top':
        return this.scrollToTop();
      case 'save-cmd':
        return this.saveArticle();
      case 'email-cmd':
        return this.mailArticle();
      case 'sms-cmd':
        return this.smsArticle();
      case 'show 200':
        return this.loadComments({
          limit: 200
        });
      case 'show 500':
        return this.loadComments({
          limit: 500
        });
      case 'related':
      case 'duplicates':
        url = this.url.replace(/\/comments\//, '/' + event.command + '/').replace('http://www.reddit.com/', '').replace('http://reddit.com/', '');
        return AppAssistant.cloneCard(this, {
          name: "frontpage"
        }, {
          permalink: url
        });
      case 'sort hot':
      case 'sort new':
      case 'sort controversial':
      case 'sort top':
      case 'sort old':
      case 'sort best':
        params = event.command.split(' ');
        return this.loadComments({
          sort: params[1]
        });
    }
  };
  ArticleAssistant.prototype.scrollToTop = function() {
    return this.controller.getSceneScroller().mojo.scrollTo(0, 0, true);
  };
  ArticleAssistant.prototype.handleCommentActionSelection = function(command) {
    var params;
    if (command == null) {
      return;
    }
    params = command.split(' ');
    switch (params[0]) {
      case 'reply-cmd':
        return this.controller.stageController.pushScene({
          name: "reply",
          transition: Mojo.Transition.crossFade
        }, {
          thing_id: params[1],
          user: params[2],
          modhash: this.modhash,
          subreddit: params[4]
        });
      case 'view-cmd':
        return this.controller.stageController.pushScene({
          name: "user",
          transition: Mojo.Transition.crossFade
        }, {
          linky: params[1]
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
    }
  };
  ArticleAssistant.prototype.spinSpinner = function(bool) {
    if (bool) {
      return this.controller.get('loading').show();
    } else {
      return this.controller.get('loading').hide();
    }
  };
  ArticleAssistant.prototype.populateComments = function(object) {
    if (this.article == null) {
      this.article = object[0].data.children[0].data;
      this.comments.items.push({
        kind: 't3',
        data: object[0].data.children[0].data
      });
      this.controller.modelChanged(this.comments);
    }
    this.populateReplies(object[1].data.children, 0);
    this.controller.get('comment-list').mojo.setLength(this.comments.items.length);
    return this.controller.get('comment-list').mojo.noticeUpdatedItems(0, this.comments.items);
  };
  ArticleAssistant.prototype.populateReplies = function(replies, indent) {
    return _.each(replies, __bind(function(child) {
      var data;
      if (child.kind !== 'more') {
        child.data.indent = indent;
        this.comments.items.push(child);
        data = child.data;
        if ((data.replies != null) && (data.replies !== "")) {
          if ((data.replies.data != null) && (data.replies.data.children != null)) {
            return this.populateReplies(data.replies.data.children, indent + 1);
          }
        }
      }
    }, this));
  };
  ArticleAssistant.prototype.fetchComments = function(params) {
    params.url = this.url + '.json';
    return new Article(this).comments(params);
  };
  ArticleAssistant.prototype.handlefetchCommentsResponse = function(response) {
    var json;
    if (!((response != null) && (response.responseJSON != null))) {
      return;
    }
    json = response.responseJSON;
    if ((json[0].data != null) && (json[0].data.modhash != null)) {
      this.modhash = json[0].data.modhash;
    }
    this.populateComments(json);
    this.controller.get('loadMoreButton').hide();
    if (this.jump_to_comment != null) {
      this.controller.getSceneScroller().mojo.revealElement(this.jump_to_comment);
      return this.jump_to_comment = null;
    }
  };
  ArticleAssistant.prototype.handleCallback = function(params) {
    var index;
    if (!((params != null) && params.success)) {
      return params;
    }
    this.spinSpinner(false);
    params.type = params.type.split(' ');
    index = -1;
    if (params.type[0] === "comment-upvote") {
      index = this.findArticleIndex(params.type[1]);
      if (index > -1) {
        if (this.comments.items[index].data.likes === false) {
          this.comments.items[index].data.downs--;
        }
        this.comments.items[index].data.likes = true;
        this.comments.items[index].data.ups++;
        this.controller.get('comment-list').mojo.noticeUpdatedItems(index, [this.comments.items[index]]);
      }
      return new Banner("Upvoted!").send();
    } else if (params.type[0] === "comment-downvote") {
      index = this.findArticleIndex(params.type[1]);
      if (index > -1) {
        if (this.comments.items[index].data.likes === true) {
          this.comments.items[index].data.ups--;
        }
        this.comments.items[index].data.likes = false;
        this.comments.items[index].data.downs++;
        this.controller.get('comment-list').mojo.noticeUpdatedItems(index, [this.comments.items[index]]);
      }
      return new Banner("Downvoted!").send();
    } else if (params.type[0] === "comment-vote-reset") {
      index = this.findArticleIndex(params.type[1]);
      if (index > -1) {
        if (this.comments.items[index].data.likes === true) {
          this.comments.items[index].data.ups--;
        } else {
          this.comments.items[index].data.downs--;
        }
        this.comments.items[index].data.likes = null;
        this.controller.get('comment-list').mojo.noticeUpdatedItems(index, [this.comments.items[index]]);
      }
      return new Banner("Vote reset!").send();
    } else if (params.type[0] === "article-save") {
      return new Banner("Saved!").send();
    } else if (params.type[0] === "article-comments") {
      return this.handlefetchCommentsResponse(params.response);
    }
  };
  ArticleAssistant.prototype.voteOnComment = function(dir, comment_name, subreddit) {
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
  ArticleAssistant.prototype.mailArticle = function() {
    return this.controller.serviceRequest("palm://com.palm.applicationManager", {
      method: 'open',
      parameters: {
        id: "com.palm.app.email",
        params: {
          summary: this.article.title,
          text: 'http://reddit.com' + this.article.data.permalink,
          recipients: [
            {
              type: "email",
              role: 1,
              value: "",
              contactDisplay: ""
            }
          ]
        }
      }
    });
  };
  ArticleAssistant.prototype.smsArticle = function() {
    return this.controller.serviceRequest("palm://com.palm.applicationManager", {
      method: 'open',
      parameters: {
        id: "com.palm.app.messaging",
        params: {
          messageText: this.article.title + "\n\n" + 'http://reddit.com' + this.article.data.permalink
        }
      }
    });
  };
  ArticleAssistant.prototype.saveArticle = function() {
    ({
      params: {
        executed: 'saved',
        id: this.article.name,
        uh: this.modhash,
        renderstyle: 'html'
      }
    });
    return new Article(this).save(params);
  };
  ArticleAssistant.prototype.isLoggedIn = function() {
    return this.modhash && (this.modhash !== "");
  };
  ArticleAssistant.prototype.itemTapped = function(event) {
    var author, comment, downvote_action, downvote_icon, element_tapped, index, linky, upvote_action, upvote_icon, url, urls;
    comment = event.item;
    element_tapped = event.originalEvent.target;
    index = 0;
    url = null;
    if (element_tapped.tagName === 'A') {
      if ((element_tapped.href === 'file:///s') || (element_tapped.href === 'file:///b') || (element_tapped.href === 'file:///?')) {
        element_tapped.update(element_tapped.title);
      } else {
        if ((element_tapped.title != null) && (element_tapped.title.length > 0)) {
          this.controller.showAlertDialog({
            message: element_tapped.title,
            choices: [
              {
                label: "Ok",
                value: "",
                type: 'dismiss'
              }
            ]
          });
        }
      }
      return;
    }
    if (element_tapped.className === 'comment_tag') {
      index = event.index;
      author = comment.data.author;
      while (true) {
        index++;
        if (index === this.comments.items.length) {
          index = 0;
        }
        if (this.comments.items[index].data.author && (this.comments.items[index].data.author === author)) {
          this.controller.get('comment-list').mojo.revealItem(index, true);
          return;
        }
      }
      return;
    }
    if (element_tapped.className === 'linky') {
      linky = Linky.parse(element_tapped.href);
      if (linky.type === 'image') {
        AppAssistant.cloneCard(this, {
          name: "image",
          transition: Mojo.Transition.crossFade
        }, {
          index: 0,
          images: [linky.url]
        });
      } else if ((linky.type === 'youtube_video') || (linky.type === 'web')) {
        this.controller.serviceRequest("palm://com.palm.applicationManager", {
          method: "open",
          parameters: {
            target: linky.url,
            onSuccess: function() {},
            onFailure: function() {}
          }
        });
      }
      return;
    }
    if (element_tapped.id.indexOf('image_') !== -1) {
      if (element_tapped.className === 'reddit_thumbnail') {
        StageAssistant.cloneImageCard(this, this.original_article);
      } else {
        index = element_tapped.id.match(/_(\d+)_/g)[0].replace(/_/g, '');
        index = parseInt(index);
        AppAssistant.cloneCard(this, {
          name: "image",
          transition: Mojo.Transition.crossFade
        }, {
          index: index,
          images: StageAssistant.parseImageUrls(comment.data.body)
        });
      }
      return;
    }
    if ((element_tapped.id.indexOf('web_') !== -1) || (element_tapped.id.indexOf('youtube_') !== -1)) {
      if (element_tapped.className === 'reddit_thumbnail') {
        url = Linky.parse(comment.data.url).url;
      } else {
        index = element_tapped.id.match(/_(\d+)_/g)[0].replace(/_/g, '');
        urls = StageAssistant.parseUrls(comment.data.body);
        url = StageAssistant.parseUrls(comment.data.body)[index].url;
      }
      this.controller.serviceRequest("palm://com.palm.applicationManager", {
        method: "open",
        parameters: {
          target: url,
          onSuccess: function() {},
          onFailure: function() {}
        }
      });
      return;
    }
    if (this.isLoggedIn()) {
      upvote_icon = comment.data.likes === true ? 'selected_upvote_icon' : 'upvote_icon';
      downvote_icon = comment.data.likes === false ? 'selected_downvote_icon' : 'downvote_icon';
      upvote_action = comment.data.likes === true ? 'reset-vote-cmd' : 'upvote-cmd';
      downvote_action = comment.data.likes === false ? 'reset-vote-cmd' : 'downvote-cmd';
      return this.controller.popupSubmenu({
        onChoose: this.handleCommentActionSelection.bind(this),
        placeNear: element_tapped,
        items: [
          {
            label: $L('Upvote'),
            command: upvote_action + ' ' + comment.data.name + ' ' + comment.data.subreddit,
            secondaryIcon: upvote_icon
          }, {
            label: $L('Downvote'),
            command: downvote_action + ' ' + comment.data.name + ' ' + comment.data.subreddit,
            secondaryIcon: downvote_icon
          }, {
            label: $L('Reply'),
            command: 'reply-cmd ' + comment.data.name + ' ' + comment.data.author + ' ' + this.url + ' ' + comment.data.subreddit
          }, {
            label: $L(comment.data.author),
            command: 'view-cmd ' + comment.data.author
          }
        ]
      });
    } else {
      return this.controller.popupSubmenu({
        onChoose: this.handleCommentActionSelection.bind(this),
        placeNear: element_tapped,
        items: [
          {
            label: $L(comment.data.author),
            command: 'view-cmd ' + comment.data.author
          }
        ]
      });
    }
  };
  return ArticleAssistant;
})();