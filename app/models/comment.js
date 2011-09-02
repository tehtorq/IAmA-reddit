var Comment;
Comment = (function() {
  function Comment(callback) {
    this.callback = callback;
  }
  Comment.prototype.upvote = function(params) {
    return new Request(this.callback).post('http://www.reddit.com/api/vote', params, 'comment-upvote ' + params.id);
  };
  Comment.prototype.downvote = function(params) {
    return new Request(this.callback).post('http://www.reddit.com/api/vote', params, 'comment-downvote ' + params.id);
  };
  Comment.prototype.reset_vote = function(params) {
    return new Request(this.callback).post('http://www.reddit.com/api/vote', params, 'comment-vote-reset ' + params.id);
  };
  Comment.prototype.reply = function(params) {
    return new Request(this.callback).post('http://www.reddit.com/api/comment', params, 'comment-reply');
  };
  Comment.prototype.edit = function(params) {
    return new Request(this.callback).post('http://www.reddit.com/api/editusertext', params, 'comment-edit');
  };
  Comment.prototype.recent = function(params) {
    return new Request(this.callback).get('http://www.reddit.com/comments/.json', params, 'comment-recent');
  };
  return Comment;
})();