var RedditAPI;
RedditAPI = (function() {
  function RedditAPI() {}
  RedditAPI.prototype.initialize = function() {
    this.base_url = 'http://www.reddit.com/';
    this.reset_options();
    return this.reddits_category = 'popular';
  };
  RedditAPI.prototype.reset_options = function() {
    this.category = 'hot';
    this.category_sort = null;
    this.domain = null;
    this.search = null;
    this.subreddit = null;
    return this.permalink = null;
  };
  RedditAPI.prototype.set_permalink = function(url) {
    this.reset_options();
    return this.permalink = url;
  };
  RedditAPI.prototype.setSubreddit = function(subreddit) {
    if (subreddit !== this.subreddit) {
      this.reset_options();
      return this.subreddit = subreddit;
    }
  };
  RedditAPI.prototype.setCategory = function(category, sort) {
    this.domain = null;
    this.search = null;
    this.category_sort = null;
    this.category = category;
    if (sort != null) {
      return this.category_sort = sort;
    }
  };
  RedditAPI.prototype.setSearchTerm = function(search) {
    if (search !== this.search) {
      this.reset_options();
      return this.search = search;
    }
  };
  RedditAPI.prototype.setDomain = function(domain) {
    if (domain !== this.domain) {
      this.reset_options();
      return this.domain = domain;
    }
  };
  RedditAPI.prototype.getArticlesPerPage = function() {
    return StageAssistant.cookieValue("prefs-articles-per-page", 25);
  };
  RedditAPI.prototype.getArticlesUrl = function() {
    var url;
    url = this.base_url;
    if (this.search != null) {
      url += 'search/.json';
      return url;
    }
    if (this.domain != null) {
      url += 'domain/' + this.domain + '/';
    } else if ((this.subreddit != null) && (this.subreddit !== 'frontpage')) {
      url += 'r/' + this.subreddit + '/';
    }
    if (this.permalink != null) {
      url = this.base_url + this.permalink;
    } else {
      url += this.category + '/';
    }
    url += '.json';
    if (this.category_sort != null) {
      url += '?' + this.category_sort.key + '=' + this.category_sort.value;
    }
    return url;
  };
  RedditAPI.prototype.getRedditsUrl = function() {
    var url;
    url = "http://www.reddit.com/reddits/";
    if (this.search != null) {
      url += 'search/.json';
      return url;
    }
    url += this.reddits_category + '/';
    url += '.json';
    return url;
  };
  RedditAPI.prototype.setRedditsSearchTerm = function(search) {
    if (search !== this.search) {
      this.last_reddit = null;
    }
    return this.search = search;
  };
  RedditAPI.prototype.setRedditsCategory = function(category) {
    if (category !== this.reddits_category) {
      this.last_reddit = null;
    }
    this.reddits_category = category;
    return this.search = null;
  };
  return RedditAPI;
})();