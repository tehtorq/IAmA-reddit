class Subreddit

  initialize: (callback) ->
    @callback = callback

  subscribe: (params) ->
    new Request(@callback).post('http://www.reddit.com/api/subscribe', params, 'subreddit-subscribe ' + params.sr)

  unsubscribe: (params) ->
    new Request(@callback).post('http://www.reddit.com/api/subscribe', params, 'subreddit-unsubscribe ' + params.sr)

  fetch: (params) ->
    url = params.url;
    delete params.url;

    new Request(@callback).get(url, params, 'subreddit-load')

  random: (params) ->
    new Request(@callback).get('http://www.reddit.com/r/random/', params, 'random-subreddit')
  
  mine: (params) ->
    new Request(@callback).get('http://www.reddit.com/reddits/mine', params, 'subreddit-load-mine')

  @cached_list = []