class User
  
  constructor: (callback) ->
    @callback = callback

  create: (params) ->
    new Request(@callback).request('http://www.reddit.com/api/register/' + params.user, 'post', params, 'user-create')

  login: (params) ->
    new Request(@callback).request('http://www.reddit.com/api/login', 'post', params, 'user-login')
  
  logout: (params) ->
    cookie = new Mojo.Model.Cookie("reddit_session")
    cookie.remove()

    Banner.send("Logged out")

  comments: (params) ->
    new Request(@callback).get('http://reddit.com/user/' + params.user + '.json', {}, 'user-comments')

  about: (params) ->
    new Request(@callback).get('http://www.reddit.com/user/' + params.user + '/about.json', {}, 'user-about')
