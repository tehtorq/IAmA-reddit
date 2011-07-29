
Subreddit = Class.create({

  initialize: function(callback) {
    this.callback = callback;
  },

  subscribe: function(params) {
    new Request(this.callback).post('http://www.reddit.com/api/subscribe', params, 'subreddit-subscribe ' + params.sr);
  },

  unsubscribe: function(params) {
    new Request(this.callback).post('http://www.reddit.com/api/subscribe', params, 'subreddit-unsubscribe ' + params.sr);
  },

  fetch: function(params) {
    var url = params.url;
    delete params.url;

    new Request(this.callback).get(url, params, 'subreddit-load');
  },

  random: function(params) {
    new Request(this.callback).get('http://www.reddit.com/r/random/', params, 'random-subreddit');
  },
  
  mine: function(params) {
    new Request(this.callback).get('http://www.reddit.com/reddits/mine', params, 'subreddit-load-mine');
  }

});

Subreddit.cached_list = [];