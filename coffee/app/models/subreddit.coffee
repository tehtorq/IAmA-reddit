class Subreddit

  constructor: (callback) ->
    @callback = callback

  subscribe: (params) ->
    display_name = params.display_name
    delete params.display_name
    
    new Request(@callback).post('http://www.reddit.com/api/subscribe', params, 'subreddit-subscribe ' + params.sr + ' ' + display_name)

  unsubscribe: (params) ->
    display_name = params.display_name
    delete params.display_name
    
    new Request(@callback).post('http://www.reddit.com/api/subscribe', params, 'subreddit-unsubscribe ' + params.sr + ' ' + display_name)

  fetch: (params) ->
    url = params.url
    delete params.url

    new Request(@callback).get(url, params, 'subreddit-load')

  random: (params) ->
    new Request(@callback).get('http://www.reddit.com/r/random/', params, 'random-subreddit')
  
  mine: (params) ->
    new Request(@callback).get('http://www.reddit.com/reddits/mine', params, 'subreddit-load-mine')

  @cached_list = []