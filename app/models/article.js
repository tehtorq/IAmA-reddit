
Article = Class.create({

  initialize: function(callback) {
    this.callback = callback;
  },

  load: function(data) {
    if (!data) {
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
    this.can_unsave = (this.data.saved) ? false : true;
    this.setEmbeddedURLs();

    return this;
  },
  
  setEmbeddedURLs: function() {
    var image_url_html = "";
    var urls = this.urls();
    this.urls = [];
    this.images = [];
    
    var hide_thumbnails = StageAssistant.cookieValue("prefs-hide-easylinks", "off");
    
    if (hide_thumbnails == "on") {
      return;
    }

    if (urls) {
      for (var i = 0; i < urls.length; i++) {
        var link_url = urls[i];
        var link_icon = "";

        // check if its a link to image

        if (link_url.type == 'image') {
          this.images.push(link_url.url);
          link_icon = './images/picture.png';
          image_url_html += '<img class="reddit_embedded_link" src="'+link_icon+'" alt="Loading" id="image_'+i+'_'+ this.id + '">';
        }
        else if (link_url.type == 'youtube_video') {
          link_icon = './images/youtube.png';
          image_url_html += '<img class="reddit_embedded_link" src="'+link_icon+'" alt="Loading" id="youtube_'+i+'_'+ this.id + '">';
        }
        else if (link_url.type == 'web') {
          link_icon = './images/web.png';
          image_url_html += '<img class="reddit_embedded_link" src="'+link_icon+'" alt="Loading" id="web_'+i+'_'+ this.id + '">';
        }

        this.urls.push(link_url.url);
      }

      this.image_url_html = image_url_html;
    }    
  },

  getUrl: function() {
    if (!this.data.url) {
      return null;
    }

    return Linky.parse(this.data.url);
  },

  urls: function() {
    var urls = this.data.selftext.match(/https?:\/\/([-\w\.]+)+(:\d+)?(\/([\w-/_\.]*(\?\S+)?)?)?/g);

    if (urls) {
      for (var i = 0; i < urls.length; i++) {
        if (urls[i].indexOf(')') >= 0) {
          urls[i] = urls[i].substr(0, urls[i].indexOf(')'));
        }

        urls[i] = Linky.parse(urls[i]);
      }
    }

    return urls;
  },

  hasThumbnail: function() {
    return ((this.data.thumbnail) && (this.data.thumbnail != ""));
  },

  save: function(params) {
    new Request(this.callback).post('http://www.reddit.com/api/save', params, 'article-save ' + params.id);
  },

  unsave: function(params) {
    new Request(this.callback).post('http://www.reddit.com/api/unsave', params, 'article-unsave ' + params.id);
  },

  comments: function(params) {
    var url = params.url;
    delete params.url;
    
    new Request(this.callback).get(url, params, 'article-comments');
  },

  list: function(params) {
    var url = 'http://www.reddit.com/';

    if (params.sr) {
      url += 'r/' + params.sr + '/';
    }

    new Request(this.callback).get(url + '.json', params, 'article-list');
  },

  mail: function(params) {
    
  },

  sms: function(params) {

  }

});

Article.thumbnailFormatter = function(article) {
  if (article.items) {
    return "";
  }
  var hide_thumbnails = StageAssistant.cookieValue("prefs-hide-thumbnails", "off");
  
  if (hide_thumbnails == "on") {
    return "";
  }
  
  var thumbnail_url = "";

  if (Article.hasThumbnail(article)) {
    var image_link = article.data.thumbnail;

    if (image_link.indexOf('/static/') != -1) {
      image_link = 'http://reddit.com' + image_link;
    }
  }

  if (article.data.url) {
    var parsed_url = Linky.parse(article.data.url);

    if (parsed_url.type == 'image') {
      if (!image_link) {
        image_link = './images/picture.png';
      }

      thumbnail_url = '<img class="reddit_thumbnail" src="'+image_link+'" alt="Loading" id="image_'+article.data.id+'">';
    }
    else if (parsed_url.type == 'youtube_video') {
      if (!image_link) {
        image_link = './images/youtube.png';
      }

      thumbnail_url = '<img class="reddit_thumbnail" src="'+image_link+'" alt="Loading" id="youtube_'+article.data.id+'">';
    }
    else if (parsed_url.type == 'web') {
      if (parsed_url.url.indexOf('http://www.reddit.com/') === -1) {
        if (!image_link) {
          image_link = './images/web.png';
        }

        thumbnail_url = '<img class="reddit_thumbnail" src="'+image_link+'" alt="Loading" id="web_'+article.data.id+'">';
      }
    }
  }     

  return thumbnail_url;
}

Article.hasThumbnail = function(article) {
  return ((article.data) && (article.data.thumbnail) && (article.data.thumbnail != ""));
}
