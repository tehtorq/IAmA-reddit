var Subreddit;
Subreddit = (function() {
  function Subreddit(callback) {
    this.callback = callback;
  }
  Subreddit.prototype.subscribe = function(params) {
    return new Request(this.callback).post('http://www.reddit.com/api/subscribe', params, 'subreddit-subscribe ' + params.sr);
  };
  Subreddit.prototype.unsubscribe = function(params) {
    return new Request(this.callback).post('http://www.reddit.com/api/subscribe', params, 'subreddit-unsubscribe ' + params.sr);
  };
  Subreddit.prototype.fetch = function(params) {
    var url;
    url = params.url;
    delete params.url;
    return new Request(this.callback).get(url, params, 'subreddit-load');
  };
  Subreddit.prototype.random = function(params) {
    return new Request(this.callback).get('http://www.reddit.com/r/random/', params, 'random-subreddit');
  };
  Subreddit.prototype.mine = function(params) {
    return new Request(this.callback).get('http://www.reddit.com/reddits/mine', params, 'subreddit-load-mine');
  };
  Subreddit.cached_list = [];
  return Subreddit;
})();