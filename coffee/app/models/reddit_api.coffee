class RedditAPI
  
  @setUser: (username, modhash, reddit_session) ->
    Mojo.Log.info("#{username},#{modhash},#{reddit_session}")
    
    new Mojo.Model.Cookie("reddit_session").put(reddit_session)
    
    users = @getUsers()
    @user = _.first _.select users, (user) -> user.username is username
    
    if @user?
      @user.modhash = modhash
      @user.reddit_session = reddit_session
    else
      @user = {username: username, modhash: modhash, reddit_session: reddit_session}
      users.push(@user)
    
    new Mojo.Model.Cookie("iama-reddit-users").put(JSON.stringify(users))
    
  @getUser: ->
    @user
    
  @getUsers: ->
    users = JSON.parse(StageAssistant.cookieValue("iama-reddit-users", JSON.stringify([])))
    
  @findUserByRedditSession: (reddit_session) ->
    users = @getUsers()
    _.first _.select users, (user) -> user.reddit_session is reddit_session
    
  @checkIfLoggedIn: ->
    reddit_session = StageAssistant.cookieValue("reddit_session", '')
    
    if reddit_session isnt ''
      @user = @findUserByRedditSession(reddit_session)

  constructor: ->
    @base_url = 'http://www.reddit.com/'
    @reset_options()
    @reddits_category = 'popular'
    
  reset_options: ->
    @category = 'hot'
    @category_sort = null
    @domain = null
    @search = null
    @subreddit = null
    @permalink = null
    
  set_permalink: (url) ->
    @reset_options()
    @permalink = url
    
  setSubreddit: (subreddit) ->
    if subreddit isnt @subreddit
      @reset_options()
      @subreddit = subreddit
      
  setCategory: (category, sort) ->
    @domain = null
    @search = null
    @category_sort = null
    @category = category
    @category_sort = sort if sort?
    
  setSearchTerm: (search) ->
    if search isnt @search
      @reset_options()
      @search = search
      
  setDomain: (domain) ->
    if domain isnt @domain
      @reset_options()
      @domain = domain
      
  getArticlesPerPage: ->
    StageAssistant.cookieValue("prefs-articles-per-page", 25)
    
  getArticlesUrl: ->
    url = @base_url
    
    if @search?
      url += 'search/.json'
      return url
      
    if @domain?
      url += 'domain/' + @domain + '/'
    else if @subreddit? and (@subreddit isnt 'frontpage')
      url += 'r/' + @subreddit + '/'
      
    if @permalink?
      url = @base_url + @permalink
    else
      url += @category + '/'
      
    url += '.json'
    
    if @category_sort?
      url += '?'+@category_sort.key+'=' + @category_sort.value
      
    url
    
  getRedditsUrl: ->
    url = "http://www.reddit.com/reddits/"
    
    if @search?
      url += 'search/.json'
      return url
      
    url += @reddits_category + '/'
    url += '.json'
    url
    
  setRedditsSearchTerm: (search) ->
    @last_reddit = null if search isnt @search
    @search = search
    
  setRedditsCategory: (category) ->
    @last_reddit = null if category isnt @reddits_category
    @reddits_category = category
    @search = null
