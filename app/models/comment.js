
Comment = Class.create({

  initialize: function(callback) {
    this.callback = callback;
  },
  
  upvote: function(params) {
    new Request(this.callback).post('http://www.reddit.com/api/vote', params, 'comment-upvote ' + params.id);
  },
  
  downvote: function(params) {
    new Request(this.callback).post('http://www.reddit.com/api/vote', params, 'comment-downvote ' + params.id);
  },
  
  reset_vote: function(params) {
    new Request(this.callback).post('http://www.reddit.com/api/vote', params, 'comment-vote-reset ' + params.id);
  },

  reply: function(params) {
    new Request(this.callback).post('http://www.reddit.com/api/comment', params, 'comment-reply');
  },

  edit: function(params) {
    new Request(this.callback).post('http://www.reddit.com/api/editusertext', params, 'comment-edit');
  },
  
  recent: function(params) {
    new Request(this.callback).get('http://www.reddit.com/comments/.json', params, 'comment-recent');
  }

});