var Article;
Article = (function() {
  function Article() {}
  Article.prototype.initialize = function(callback) {
    return this.callback = callback;
  };
  Article.prototype.load = function(data) {
    var _ref;
    if (data == null) {
      return this;
    }
    this.kind = 't3';
    this.data = data;
    this.data.url = this.data.url.unescapeHTML();
    this.author = this.data.author;
    this.title = this.data.title;
    this.url = this.getUrl();
    this.id = this.data.id;
    this.name = data.name;
    this.can_unsave = (_ref = this.data.saved) != null ? _ref : {
      "false": true
    };
    this.setEmbeddedURLs();
    return this;
  };
  Article.prototype.setEmbeddedURLs = function() {
    var hide_thumbnails, image_url_html, urls;
    image_url_html = "";
    urls = this.urls();
    this.urls = [];
    this.images = [];
    hide_thumbnails = StageAssistant.cookieValue("prefs-hide-easylinks", "off");
    if (hide_thumbnails === "on") {
      return;
    }
    if (urls == null) {
      return;
    }
    _.each(urls, function(link_url) {
      var link_icon;
      link_icon = "";
      if (link_url.type === 'image') {
        this.images.push(link_url.url);
        link_icon = './images/picture.png';
        image_url_html += '<img class="reddit_embedded_link" src="' + link_icon + '" alt="Loading" id="image_' + i + '_' + this.id + '">';
      } else if (link_url.type === 'youtube_video') {
        link_icon = './images/youtube.png';
        image_url_html += '<img class="reddit_embedded_link" src="' + link_icon + '" alt="Loading" id="youtube_' + i + '_' + this.id + '">';
      } else if (link_url.type === 'web') {
        link_icon = './images/web.png';
        image_url_html += '<img class="reddit_embedded_link" src="' + link_icon + '" alt="Loading" id="web_' + i + '_' + this.id + '">';
      }
      return this.urls.push(link_url.url);
    });
    return this.image_url_html = image_url_html;
  };
  Article.prototype.getUrl = function() {
    if (this.data.url == null) {
      return null;
    }
    return Linky.parse(this.data.url);
  };
  Article.prototype.urls = function() {
    var urls;
    urls = this.data.selftext.match(/https?:\/\/([-\w\.]+)+(:\d+)?(\/([\w-/_\.]*(\?\S+)?)?)?/g);
    if (urls != null) {
      _.each(urls, function(url) {
        if (url.indexOf(')') >= 0) {
          url = url.substr(0, url.indexOf(')'));
        }
        return url = Linky.parse(url);
      });
    }
    return urls;
  };
  Article.prototype.hasThumbnail = function() {
    return this.data.thumbnail && (this.data.thumbnail !== "");
  };
  Article.prototype.save = function(params) {
    return new Request(this.callback).post('http://www.reddit.com/api/save', params, 'article-save ' + params.id);
  };
  Article.prototype.unsave = function(params) {
    return new Request(this.callback).post('http://www.reddit.com/api/unsave', params, 'article-unsave ' + params.id);
  };
  Article.prototype.comments = function(params) {
    var url;
    url = params.url;
    delete params.url;
    return new Request(this.callback).get(url, params, 'article-comments');
  };
  Article.prototype.list = function(params) {
    var url;
    url = 'http://www.reddit.com/';
    if (params.sr != null) {
      url += 'r/' + params.sr + '/';
    }
    return new Request(this.callback).get(url + '.json', params, 'article-list');
  };
  Article.prototype.mail = function(params) {};
  Article.prototype.sms = function(params) {};
  return Article;
})();
Article.thumbnailFormatter = function(article) {
  var hide_thumbnails, image_link, parsed_url, thumbnail_url;
  if (article.items != null) {
    return "";
  }
  hide_thumbnails = StageAssistant.cookieValue("prefs-hide-thumbnails", "off");
  if (hide_thumbnails === "on") {
    return "";
  }
  thumbnail_url = "";
  if (Article.hasThumbnail(article)) {
    image_link = article.data.thumbnail;
    if (image_link.indexOf('/static/') !== -1) {
      image_link = 'http://reddit.com' + image_link;
    }
  }
  if (article.data.url != null) {
    parsed_url = Linky.parse(article.data.url);
    if (parsed_url.type === 'image') {
      if (image_link == null) {
        image_link = './images/picture.png';
      }
      thumbnail_url = '<img class="reddit_thumbnail" src="' + image_link + '" alt="Loading" id="image_' + article.data.id + '">';
    } else if (parsed_url.type === 'youtube_video') {
      if (image_link == null) {
        image_link = './images/youtube.png';
      }
      thumbnail_url = '<img class="reddit_thumbnail" src="' + image_link + '" alt="Loading" id="youtube_' + article.data.id + '">';
    } else if (parsed_url.type === 'web') {
      if (parsed_url.url.indexOf('http://www.reddit.com/') !== -1) {
        if (image_link == null) {
          image_link = './images/web.png';
        }
        thumbnail_url = '<img class="reddit_thumbnail" src="' + image_link + '" alt="Loading" id="web_' + article.data.id + '">';
      }
    }
  }
  return thumbnail_url;
};
Article.hasThumbnail = function(article) {
  return (article.data != null) && (article.data.thumbnail != null) && (article.data.thumbnail !== "");
};