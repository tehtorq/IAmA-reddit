
Message = Class.create({

  initialize: function(callback) {
    this.callback = callback;
  },
  
  inbox: function(params) {
    new Request(this.callback).get('http://reddit.com/message/inbox/.json', params, 'message-inbox');
  },
  
  unread: function(params) {
    new Request(this.callback).get('http://reddit.com/message/unread/.json', params, 'message-unread');
  },

  messages: function(params) {
    new Request(this.callback).get('http://reddit.com/message/messages/.json', params, 'message-messages');
  },
  
  comments: function(params) {
    new Request(this.callback).get('http://reddit.com/message/comments/.json', params, 'message-comments');
  },

  selfreply: function(params) {
    new Request(this.callback).get('http://reddit.com/message/selfreply/.json', params, 'message-selfreply');
  },
  
  sent: function(params) {
    new Request(this.callback).get('http://reddit.com/message/sent/.json', params, 'message-sent');
  }  

});