class Comment

  initialize: (callback) ->
    @callback = callback
  
  upvote: (params) ->
    new Request(@callback).post('http://www.reddit.com/api/vote', params, 'comment-upvote ' + params.id)
  
  downvote: (params) ->
    new Request(@callback).post('http://www.reddit.com/api/vote', params, 'comment-downvote ' + params.id)
  
  reset_vote: (params) ->
    new Request(@callback).post('http://www.reddit.com/api/vote', params, 'comment-vote-reset ' + params.id)

  reply: (params) ->
    new Request(@callback).post('http://www.reddit.com/api/comment', params, 'comment-reply')

  edit: (params) ->
    new Request(@callback).post('http://www.reddit.com/api/editusertext', params, 'comment-edit')
  
  recent: (params) ->
    new Request(@callback).get('http://www.reddit.com/comments/.json', params, 'comment-recent')