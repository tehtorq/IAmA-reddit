class Message

  constructor: (callback) ->
    @callback = callback
  
  inbox: (params) ->
    new Request(@callback).get('http://reddit.com/message/inbox/.json', params, 'message-inbox')
  
  unread: (params) ->
    new Request(@callback).get('http://reddit.com/message/unread/.json', params, 'message-unread')

  messages: (params) ->
    new Request(@callback).get('http://reddit.com/message/messages/.json', params, 'message-messages')
  
  comments: (params) ->
    new Request(@callback).get('http://reddit.com/message/comments/.json', params, 'message-comments')

  selfreply: (params) ->
    new Request(@callback).get('http://reddit.com/message/selfreply/.json', params, 'message-selfreply')
  
  sent: (params) ->
    new Request(@callback).get('http://reddit.com/message/sent/.json', params, 'message-sent')
