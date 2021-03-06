class RedditAPI
  
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
