class Friend

  constructor: (callback) ->
    @callback = callback
  
  add: (params) ->
    new Request(@callback).post('http://www.reddit.com/api/friend', params, 'add-friend')
  
  remove: (params) ->
    new Request(@callback).post('http://www.reddit.com/api/unfriend', params, 'remove-friend')
  
  list: (params) ->
    url = 'https://ssl.reddit.com/prefs/friends/'
    new Request(@callback).get(url, params, 'list-friends')
    
  submissions: (params) ->
    new Request(@callback).get('http://www.reddit.com/r/friends', params, 'list-friends-submissions')
    
  comments: (params) ->
    new Request(@callback).get('http://www.reddit.com/r/friends/comments', params, 'list-friends-comments')
    
