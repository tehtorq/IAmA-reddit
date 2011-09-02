var Message;
Message = (function() {
  function Message() {}
  Message.prototype.initialize = function(callback) {
    return this.callback = callback;
  };
  Message.prototype.inbox = function(params) {
    return new Request(this.callback).get('http://reddit.com/message/inbox/.json', params, 'message-inbox');
  };
  Message.prototype.unread = function(params) {
    return new Request(this.callback).get('http://reddit.com/message/unread/.json', params, 'message-unread');
  };
  Message.prototype.messages = function(params) {
    return new Request(this.callback).get('http://reddit.com/message/messages/.json', params, 'message-messages');
  };
  Message.prototype.comments = function(params) {
    return new Request(this.callback).get('http://reddit.com/message/comments/.json', params, 'message-comments');
  };
  Message.prototype.selfreply = function(params) {
    return new Request(this.callback).get('http://reddit.com/message/selfreply/.json', params, 'message-selfreply');
  };
  Message.prototype.sent = function(params) {
    return new Request(this.callback).get('http://reddit.com/message/sent/.json', params, 'message-sent');
  };
  return Message;
})();