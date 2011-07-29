
RedditAPI = Class.create({

  initialize: function() {
    this.base_url = 'http://www.reddit.com/';
    this.reset_options();
    this.reddits_category = 'popular';
  },
  
  reset_options: function() {
    this.category = 'hot';
    this.category_sort = null;
    this.domain = null;
    this.search = null;
    this.subreddit = null
    this.permalink = null;
  },
  
  set_permalink: function(url) {
    this.reset_options();
    this.permalink = url;
  },

  setSubreddit: function(subreddit) {
    if (subreddit != this.subreddit) {
      this.reset_options();
      this.subreddit = subreddit;
    }
  },

  setCategory: function(category, sort) {
    this.domain = null;
    this.search = null;
    this.category_sort = null;
    this.category = category;
    
    if (sort != undefined) {
      this.category_sort = sort;
    }
  },

  setSearchTerm: function(search) {
    if (search != this.search) {
      this.reset_options();
      this.search = search;
    }
  },

  setDomain: function(domain) {
    if (domain != this.domain) {
      this.reset_options();
      this.domain = domain;
    }
  },

  getArticlesPerPage: function() {
    return StageAssistant.cookieValue("prefs-articles-per-page", 25);
  },

  getArticlesUrl: function() {
    var url = this.base_url;

    if (this.search != null) {
      url += 'search/.json';
      return url;
    }

    if (this.domain != null) {
      url += 'domain/' + this.domain + '/';
    }
    else if ((this.subreddit != null) && (this.subreddit != 'frontpage')) {
      url += 'r/' + this.subreddit + '/';
    }

    if (this.permalink) {
      url = this.base_url + this.permalink;
    }
    else {
      url += this.category + '/';
    }
    
    url += '.json';
    
    if (this.category_sort != null) {
      url += '?'+this.category_sort.key+'=' + this.category_sort.value;
    }

    return url;
  },

  getRedditsUrl: function() {
    var url = "http://www.reddit.com/reddits/";

    if (this.search != null) {
      url += 'search/.json';
      return url;
    }

    url += this.reddits_category + '/';
    url += '.json';
    return url;
  },

  setRedditsSearchTerm: function(search) {
    if (search != this.search) {
      this.last_reddit = null;
    }

    this.search = search;
  },

  setRedditsCategory: function(category) {
    if (category != this.reddits_category) {
      this.last_reddit = null;
    }

    this.reddits_category = category;
    this.search = null;
  }

});









